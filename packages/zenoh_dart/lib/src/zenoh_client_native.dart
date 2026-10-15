import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkgffi;

import 'bindings/native_library.dart';
import 'bindings/zenoh_bindings.dart';
import 'bindings/zenoh_generated.dart' as gen;
import 'zenoh_exceptions.dart';
import 'zenoh_platform_interface.dart';
import 'zenoh_types.dart';

// ---------------------------------------------------------------------------
// Top-level polling function — runs in a background Dart isolate.
// Must be top-level (not a closure or instance method) for Isolate.spawn.
// ---------------------------------------------------------------------------
Future<void> _zenohFifoPollingIsolate(Map<String, Object> config) async {
  final sendPort = config['sendPort']! as SendPort;
  final handlerAddress = config['handlerAddress']! as int;

  ffi.DynamicLibrary lib;
  try {
    if (Platform.isAndroid || Platform.isLinux) {
      lib = ffi.DynamicLibrary.open('libzenoh.so');
    } else if (Platform.isIOS) {
      // Embedded dynamic framework, see ios/zenoh_dart.podspec.
      lib = ffi.DynamicLibrary.open('zenohc.framework/zenohc');
    } else if (Platform.isMacOS) {
      lib = ffi.DynamicLibrary.open('libzenoh.dylib');
    } else if (Platform.isWindows) {
      lib = ffi.DynamicLibrary.open('zenoh.dll');
    } else {
      sendPort.send(null);
      return;
    }
  } catch (_) {
    lib = ffi.DynamicLibrary.process();
  }

  final native = gen.ZenohFFI(lib);
  final handlerPtr =
      ffi.Pointer<gen.z_loaned_fifo_handler_sample_t>.fromAddress(
          handlerAddress);

  while (true) {
    final samplePtr = pkgffi.calloc<gen.z_owned_sample_t>();
    final rc = native.z_fifo_handler_sample_recv(handlerPtr, samplePtr);

    if (rc != 0) {
      pkgffi.calloc.free(samplePtr);
      // Channel disconnected — signal stream end. This must be the isolate's
      // last use of handlerPtr: the main isolate frees the handler as soon as
      // it receives this null.
      sendPort.send(null);
      break;
    }

    // Sample is owned and remains valid until z_sample_drop.
    final loanedSample = native.z_sample_loan(samplePtr);

    // Read key expression.
    final viewPtr = pkgffi.calloc<gen.z_view_string_t>();
    native.z_view_string_empty(viewPtr);
    final keyExprLoan = native.z_sample_keyexpr(loanedSample);
    native.z_keyexpr_as_view_string(keyExprLoan, viewPtr);
    final keyLoanStr = native.z_view_string_loan(viewPtr);
    final keyLen = native.z_string_len(keyLoanStr);
    String keyStr = '';
    if (keyLen > 0) {
      final keyData = native.z_string_data(keyLoanStr).cast<ffi.Uint8>();
      keyStr = utf8.decode(keyData.asTypedList(keyLen));
    }
    pkgffi.calloc.free(viewPtr);

    // Read payload via z_bytes_to_slice — copies all fragments into one owned slice.
    final payloadLoan = native.z_sample_payload(loanedSample);
    Uint8List payload = Uint8List(0);

    final ownedSlicePtr = pkgffi.calloc<gen.z_owned_slice_t>();
    final toSliceRc = native.z_bytes_to_slice(payloadLoan, ownedSlicePtr);
    if (toSliceRc == 0) {
      final sliceLoan = native.z_slice_loan(ownedSlicePtr);
      final len = native.z_slice_len(sliceLoan);
      if (len > 0) {
        payload =
            Uint8List.fromList(native.z_slice_data(sliceLoan).asTypedList(len));
      }
    }
    native.z_slice_drop(ownedSlicePtr.cast<gen.z_moved_slice_t>());
    pkgffi.calloc.free(ownedSlicePtr);

    // Read encoding (e.g. 'text/plain'). The encoding loan is tied to the
    // sample, so this must happen before z_sample_drop. Best effort: any
    // failure yields null rather than killing the polling isolate.
    String? encodingStr;
    final ownedEncStrPtr = pkgffi.calloc<gen.z_owned_string_t>();
    var encStrInitialized = false;
    try {
      final encodingLoan = native.z_sample_encoding(loanedSample);
      if (encodingLoan != ffi.nullptr) {
        native.z_encoding_to_string(encodingLoan, ownedEncStrPtr);
        encStrInitialized = true;
        final encStrLoan = native.z_string_loan(ownedEncStrPtr);
        final encLen = native.z_string_len(encStrLoan);
        if (encLen > 0) {
          final encData = native.z_string_data(encStrLoan).cast<ffi.Uint8>();
          encodingStr =
              utf8.decode(encData.asTypedList(encLen), allowMalformed: true);
        }
      }
    } catch (_) {
      encodingStr = null;
    } finally {
      if (encStrInitialized) {
        native.z_string_drop(ownedEncStrPtr.cast<gen.z_moved_string_t>());
      }
      pkgffi.calloc.free(ownedEncStrPtr);
    }

    // Drop the owned sample.
    native.z_sample_drop(samplePtr.cast<gen.z_moved_sample_t>());
    pkgffi.calloc.free(samplePtr);

    sendPort.send(<String, Object?>{
      'key': keyStr,
      'payload': payload,
      'encoding': encodingStr,
    });
  }
}

// ---------------------------------------------------------------------------
// Opaque struct allocation.
// ---------------------------------------------------------------------------

/// Extra bytes added when allocating opaque zenoh-c structs whose size differs
/// between zenoh-c releases.
///
/// The generated bindings come from the zenoh-c 1.6.2 headers, but the 1.8.0
/// library bundled for Android has larger `z_owned_subscriber_t` (56 vs 48
/// bytes), `z_owned_publisher_t` (120 vs 112) and `z_owned_config_t`
/// (2008 vs 1984) on 64-bit targets. Allocating too little lets zenoh-c write
/// past the end of the chunk and corrupt the heap; allocating more is harmless.
const int _opaqueSlackBytes = 256;

ffi.Pointer<T> _callocOpaque<T extends ffi.NativeType>(int generatedSize) =>
    pkgffi.calloc<ffi.Uint8>(generatedSize + _opaqueSlackBytes).cast<T>();

/// How long teardown waits for a polling isolate to confirm it has left
/// `z_fifo_handler_sample_recv` before giving up and leaking the handler.
const Duration _pollingIsolateExitTimeout = Duration(seconds: 2);

/// Native resources and isolate plumbing behind one subscription.
class _NativeSubscription {
  _NativeSubscription({
    required this.subscriberPtr,
    required this.handlerPtr,
    required this.receivePort,
    required this.controller,
  });

  final ffi.Pointer<gen.z_owned_subscriber_t> subscriberPtr;
  final ffi.Pointer<gen.z_owned_fifo_handler_sample_t> handlerPtr;
  final ReceivePort receivePort;
  final StreamController<ZenohSample> controller;

  /// Completes once the polling isolate no longer touches [handlerPtr]: it
  /// sent its final `null` (channel disconnected) or it terminated.
  final Completer<void> isolateDone = Completer<void>();

  Isolate? isolate;

  void markIsolateDone() {
    if (!isolateDone.isCompleted) isolateDone.complete();
  }
}

// ---------------------------------------------------------------------------
// Native FFI-based Zenoh client — desktop and mobile platforms.
// ---------------------------------------------------------------------------
class ZenohClientNative implements ZenohClientInterface {
  ZenohClientNative._(this._bindings, this.session);

  final ZenohBindings _bindings;
  final ZenohSession session;

  /// Set as soon as [close] is called; the client is unusable from then on.
  bool _closed = false;
  Future<void>? _closeFuture;
  int _nextId = 1;

  final Map<int, _NativeSubscription> _subscriptions = {};
  final Set<Future<void>> _pendingTeardowns = {};

  @override
  bool get isClosed => _closed;

  static Future<ZenohClientNative> connect(ZenohConfig config) async {
    final bindings = await NativeLibrary.instance.ensureBindings();
    final sessionPtr = pkgffi.calloc<gen.z_owned_session_t>();
    try {
      _openSession(bindings, sessionPtr, config);
      return ZenohClientNative._(bindings, ZenohSession(sessionPtr));
    } catch (_) {
      pkgffi.calloc.free(sessionPtr);
      rethrow;
    }
  }

  @override
  Future<ZenohPublisher> declarePublisher(String keyExpr) async {
    if (_closed) {
      throw StateError('Cannot declare a publisher on a closed ZenohClient.');
    }
    final publisherPtr = _callocOpaque<gen.z_owned_publisher_t>(
        ffi.sizeOf<gen.z_owned_publisher_t>());
    try {
      final keyExprPtr = pkgffi.calloc<gen.z_owned_keyexpr_t>();
      final keyExprUtf8 = keyExpr.toNativeUtf8(allocator: pkgffi.calloc);
      final optionsPtr = pkgffi.calloc<gen.z_publisher_options_t>();
      try {
        final keyRc =
            _bindings.zKeyExprFromStr(keyExprPtr, keyExprUtf8.cast<ffi.Char>());
        if (keyRc != 0) {
          throw ZenohNativeCallException('z_keyexpr_from_str failed',
              errorCode: keyRc);
        }
        _bindings.zPublisherOptionsDefault(optionsPtr);
        final rc = _bindings.zDeclarePublisher(
          _bindings.zSessionLoan(session.pointer),
          publisherPtr,
          _bindings.zKeyExprLoan(keyExprPtr),
          optionsPtr,
        );
        _dropKeyExpr(keyExprPtr);
        if (rc != 0) {
          throw ZenohNativeCallException('z_declare_publisher failed',
              errorCode: rc);
        }
      } finally {
        pkgffi.calloc.free(optionsPtr);
        pkgffi.calloc.free(keyExprUtf8);
        pkgffi.calloc.free(keyExprPtr);
      }
      return ZenohPublisher(publisherPtr);
    } catch (_) {
      pkgffi.calloc.free(publisherPtr);
      rethrow;
    }
  }

  @override
  Future<ZenohSubscriber> subscribe(String keyExpr) async {
    if (_closed) {
      throw StateError('Cannot subscribe using a closed ZenohClient.');
    }

    // Create a FIFO channel: zenoh pushes samples in; background isolate polls.
    final callbackPtr = pkgffi.calloc<gen.z_owned_closure_sample_t>();
    final handlerPtr = pkgffi.calloc<gen.z_owned_fifo_handler_sample_t>();
    _bindings.zFifoChannelSampleNew(callbackPtr, handlerPtr, 64);

    final subscriberPtr = _callocOpaque<gen.z_owned_subscriber_t>(
        ffi.sizeOf<gen.z_owned_subscriber_t>());
    final keyExprPtr = pkgffi.calloc<gen.z_owned_keyexpr_t>();
    final keyExprUtf8 = keyExpr.toNativeUtf8(allocator: pkgffi.calloc);
    final optionsPtr = pkgffi.calloc<gen.z_subscriber_options_t>();
    var callbackMoved = false;

    try {
      final keyRc =
          _bindings.zKeyExprFromStr(keyExprPtr, keyExprUtf8.cast<ffi.Char>());
      if (keyRc != 0) {
        throw ZenohNativeCallException('z_keyexpr_from_str failed',
            errorCode: keyRc);
      }
      _bindings.zSubscriberOptionsDefault(optionsPtr);
      callbackMoved = true;
      final rc = _bindings.zDeclareSubscriber(
        _bindings.zSessionLoan(session.pointer),
        subscriberPtr,
        _bindings.zKeyExprLoan(keyExprPtr),
        callbackPtr.cast<gen.z_moved_closure_sample_t>(),
        optionsPtr,
      );
      _dropKeyExpr(keyExprPtr);
      if (rc != 0) {
        throw ZenohNativeCallException('z_declare_subscriber failed',
            errorCode: rc);
      }
    } catch (_) {
      // No isolate polls the handler yet, so it can be released directly.
      if (!callbackMoved) {
        _bindings.zClosureSampleDrop(
            callbackPtr.cast<gen.z_moved_closure_sample_t>());
      }
      _bindings.zFifoHandlerSampleDrop(
          handlerPtr.cast<gen.z_moved_fifo_handler_sample_t>());
      pkgffi.calloc.free(handlerPtr);
      pkgffi.calloc.free(subscriberPtr);
      rethrow;
    } finally {
      pkgffi.calloc.free(keyExprUtf8);
      pkgffi.calloc.free(optionsPtr);
      pkgffi.calloc.free(keyExprPtr);
      // callbackPtr ownership was moved into the subscriber declaration (or
      // dropped above); only the Dart-side struct memory remains.
      pkgffi.calloc.free(callbackPtr);
    }

    final handlerAddress = _bindings.zFifoHandlerSampleLoan(handlerPtr).address;

    final sub = _NativeSubscription(
      subscriberPtr: subscriberPtr,
      handlerPtr: handlerPtr,
      receivePort: ReceivePort(),
      controller: StreamController<ZenohSample>(),
    );

    sub.receivePort.listen((message) {
      if (message == null) {
        // Either the isolate's final message (channel disconnected, it is about
        // to return) or its onExit notification. In both cases it will not
        // touch the handler again.
        sub.markIsolateDone();
        sub.receivePort.close();
        if (!sub.controller.isClosed) sub.controller.close();
      } else if (message is Map && !sub.controller.isClosed) {
        final key = message['key'] as String? ?? '';
        final data = message['payload'] as Uint8List? ?? Uint8List(0);
        sub.controller.add(ZenohSample(
          keyExpr: key,
          payload: data,
          encoding: message['encoding'] as String?,
        ));
      }
    });

    // Register before awaiting so a concurrent close() tears it down too.
    final id = _nextId++;
    _subscriptions[id] = sub;

    try {
      sub.isolate = await Isolate.spawn<Map<String, Object>>(
        _zenohFifoPollingIsolate,
        <String, Object>{
          'sendPort': sub.receivePort.sendPort,
          'handlerAddress': handlerAddress,
        },
        onExit: sub.receivePort.sendPort,
      );
    } catch (_) {
      // No isolate was started, so nothing can be blocked on the handler.
      sub.markIsolateDone();
      if (identical(_subscriptions[id], sub)) {
        _subscriptions.remove(id);
        await _trackTeardown(sub);
      }
      rethrow;
    }

    if (!identical(_subscriptions[id], sub)) {
      // close() ran while the isolate was starting and already tore this down.
      throw StateError('ZenohClient was closed while subscribing.');
    }

    return ZenohSubscriber(subscriberPtr,
        stream: sub.controller.stream, contextId: id);
  }

  @override
  Future<void> publishString(ZenohPublisher publisher, String message,
      {Encoding encoding = utf8}) async {
    await _publish(publisher, encoding.encode(message));
  }

  @override
  Future<void> publishBytes(ZenohPublisher publisher, List<int> data) async {
    await _publish(publisher, data);
  }

  Future<void> _publish(ZenohPublisher publisher, List<int> payload) async {
    if (_closed) {
      throw StateError('Cannot publish using a closed ZenohClient.');
    }
    if (payload.isEmpty) {
      throw ArgumentError.value(payload, 'payload', 'must not be empty');
    }
    final ptr = publisher.pointer;
    if (ptr == null) throw StateError('Invalid publisher pointer');

    final dataPtr = pkgffi.calloc<ffi.Uint8>(payload.length);
    final bytesPtr = pkgffi.calloc<gen.z_owned_bytes_t>();
    try {
      dataPtr.asTypedList(payload.length).setAll(0, payload);
      final rc = _bindings.zBytesCopyFromBuf(bytesPtr, dataPtr, payload.length);
      if (rc != 0) {
        throw ZenohNativeCallException('z_bytes_copy_from_buf failed',
            errorCode: rc);
      }
    } finally {
      pkgffi.calloc.free(dataPtr);
    }
    final optionsPtr = pkgffi.calloc<gen.z_publisher_put_options_t>();
    _bindings.zPublisherPutOptionsDefault(optionsPtr);
    final rc = _bindings.zPublisherPut(_bindings.zPublisherLoan(ptr),
        bytesPtr.cast<gen.z_moved_bytes_t>(), optionsPtr);
    pkgffi.calloc.free(optionsPtr);
    if (rc != 0) {
      _bindings.zBytesDrop(bytesPtr.cast<gen.z_moved_bytes_t>());
      pkgffi.calloc.free(bytesPtr);
      throw ZenohNativeCallException('z_publisher_put failed', errorCode: rc);
    }
    pkgffi.calloc.free(bytesPtr);
  }

  @override
  Future<void> undeclarePublisher(ZenohPublisher publisher) async {
    final ptr = publisher.pointer;
    if (ptr == null) throw StateError('Invalid publisher pointer');
    _bindings.zPublisherDrop(ptr.cast<gen.z_moved_publisher_t>());
    pkgffi.calloc.free(ptr);
  }

  /// Undeclares [subscriber] and releases its resources.
  ///
  /// Idempotent: a second call, or a call after [close], is a no-op.
  @override
  Future<void> undeclareSubscriber(ZenohSubscriber subscriber) async {
    final id = subscriber.contextId;
    final sub = _subscriptions[id];
    if (sub == null || sub.subscriberPtr != subscriber.pointer) return;
    // Remove before awaiting so a concurrent close() cannot tear it down twice.
    _subscriptions.remove(id);
    await _trackTeardown(sub);
  }

  Future<void> _trackTeardown(_NativeSubscription sub) {
    final future = _teardownSubscription(sub);
    _pendingTeardowns.add(future);
    return future.whenComplete(() => _pendingTeardowns.remove(future));
  }

  /// Teardown order matters: the polling isolate may be blocked inside
  /// `z_fifo_handler_sample_recv` on a loan of the handler, so the handler
  /// must outlive that call.
  Future<void> _teardownSubscription(_NativeSubscription sub) async {
    // 1. Undeclare the subscriber. This drops its callback closure and with it
    //    the FIFO sender, so recv returns Z_CHANNEL_DISCONNECTED once the
    //    queue is drained and the isolate sends null and returns. The owned
    //    subscriber is in its gravestone state afterwards, so its memory can
    //    be freed right away.
    _bindings
        .zSubscriberDrop(sub.subscriberPtr.cast<gen.z_moved_subscriber_t>());
    pkgffi.calloc.free(sub.subscriberPtr);

    // 2. Wait until the isolate has confirmed it left recv.
    var isolateDone = true;
    try {
      await sub.isolateDone.future.timeout(_pollingIsolateExitTimeout);
    } on TimeoutException {
      isolateDone = false;
    }

    // 3. Only now release the handler.
    if (isolateDone) {
      sub.isolate?.kill(priority: Isolate.immediate); // Already exited; no-op.
      _bindings.zFifoHandlerSampleDrop(
          sub.handlerPtr.cast<gen.z_moved_fifo_handler_sample_t>());
      pkgffi.calloc.free(sub.handlerPtr);
    } else {
      // Leaking the handler is better than freeing memory another thread may
      // still be blocked on.
      print('[zenoh_dart] Subscriber polling isolate did not exit within '
          '${_pollingIsolateExitTimeout.inMilliseconds} ms; leaking its FIFO '
          'handler to avoid a use-after-free.');
    }

    sub.receivePort.close();
    if (!sub.controller.isClosed) unawaited(sub.controller.close());
  }

  /// Undeclares all subscribers and closes the session.
  ///
  /// Idempotent: later calls return the same future.
  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) return existing;
    _closed = true;
    return _closeFuture = _closeSession();
  }

  Future<void> _closeSession() async {
    final subs = _subscriptions.values.toList();
    _subscriptions.clear();
    // Undeclares every subscriber synchronously first, then waits for all
    // polling isolates (including teardowns already started by
    // undeclareSubscriber) in parallel.
    await Future.wait(<Future<void>>[
      ..._pendingTeardowns,
      for (final sub in subs) _trackTeardown(sub),
    ]);

    final optionsPtr = pkgffi.calloc<gen.z_close_options_t>();
    final int rc;
    try {
      _bindings.zCloseOptionsDefault(optionsPtr);
      rc =
          _bindings.zClose(_bindings.zSessionLoan(session.pointer), optionsPtr);
    } finally {
      pkgffi.calloc.free(optionsPtr);
    }
    _bindings.zSessionDrop(session.pointer.cast<gen.z_moved_session_t>());
    pkgffi.calloc.free(session.pointer);
    if (rc != 0) {
      throw ZenohNativeCallException('z_close failed', errorCode: rc);
    }
  }

  static void _openSession(
    ZenohBindings bindings,
    ffi.Pointer<gen.z_owned_session_t> sessionPtr,
    ZenohConfig config,
  ) {
    final configJson = jsonEncode(config.toJson());
    final configUtf8 = configJson.toNativeUtf8(allocator: pkgffi.calloc);
    final configPtr =
        _callocOpaque<gen.z_owned_config_t>(ffi.sizeOf<gen.z_owned_config_t>());
    try {
      final rc =
          bindings.zcConfigFromStr(configPtr, configUtf8.cast<ffi.Char>());
      if (rc != 0) {
        pkgffi.calloc.free(configPtr);
        throw ZenohNativeCallException('zc_config_from_str failed',
            errorCode: rc);
      }
    } finally {
      pkgffi.calloc.free(configUtf8);
    }
    final optionsPtr = pkgffi.calloc<gen.z_open_options_t>();
    bindings.zOpenOptionsDefault(optionsPtr);
    final rc = bindings.zOpen(
        sessionPtr, configPtr.cast<gen.z_moved_config_t>(), optionsPtr);
    pkgffi.calloc.free(optionsPtr);
    pkgffi.calloc.free(configPtr);
    if (rc != 0) {
      bindings.zSessionDrop(sessionPtr.cast<gen.z_moved_session_t>());
      throw ZenohNativeCallException('z_open failed', errorCode: rc);
    }
  }

  void _dropKeyExpr(ffi.Pointer<gen.z_owned_keyexpr_t> keyExpr) {
    _bindings.zKeyExprDrop(keyExpr.cast<gen.z_moved_keyexpr_t>());
  }
}
