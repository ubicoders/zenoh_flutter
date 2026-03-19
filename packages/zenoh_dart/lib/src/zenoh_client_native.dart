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
    } else if (Platform.isMacOS || Platform.isIOS) {
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
      sendPort.send(null); // channel disconnected — signal stream end
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

    // Drop the owned sample.
    native.z_sample_drop(samplePtr.cast<gen.z_moved_sample_t>());
    pkgffi.calloc.free(samplePtr);

    sendPort.send(<String, Object>{'key': keyStr, 'payload': payload});
  }
}

// ---------------------------------------------------------------------------
// Native FFI-based Zenoh client — desktop and mobile platforms.
// ---------------------------------------------------------------------------
class ZenohClientNative implements ZenohClientInterface {
  ZenohClientNative._(this._bindings, this.session);

  final ZenohBindings _bindings;
  final ZenohSession session;

  bool _closed = false;
  int _nextId = 1;

  final Map<int, ffi.Pointer<gen.z_owned_subscriber_t>> _subscriberPtrs = {};
  final Map<int, ffi.Pointer<gen.z_owned_fifo_handler_sample_t>> _fifoHandlers =
      {};
  final Map<int, ReceivePort> _pollingPorts = {};
  final Map<int, Isolate> _pollingIsolates = {};
  final Map<int, StreamController<ZenohSample>> _controllers = {};

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
    final publisherPtr = pkgffi.calloc<gen.z_owned_publisher_t>();
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

    final subscriberPtr = pkgffi.calloc<gen.z_owned_subscriber_t>();
    final keyExprPtr = pkgffi.calloc<gen.z_owned_keyexpr_t>();
    final keyExprUtf8 = keyExpr.toNativeUtf8(allocator: pkgffi.calloc);
    final optionsPtr = pkgffi.calloc<gen.z_subscriber_options_t>();

    try {
      final keyRc =
          _bindings.zKeyExprFromStr(keyExprPtr, keyExprUtf8.cast<ffi.Char>());
      if (keyRc != 0) {
        throw ZenohNativeCallException('z_keyexpr_from_str failed',
            errorCode: keyRc);
      }
      _bindings.zSubscriberOptionsDefault(optionsPtr);
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
    } catch (e) {
      pkgffi.calloc.free(callbackPtr);
      pkgffi.calloc.free(handlerPtr);
      pkgffi.calloc.free(subscriberPtr);
      pkgffi.calloc.free(keyExprPtr);
      pkgffi.calloc.free(keyExprUtf8);
      pkgffi.calloc.free(optionsPtr);
      rethrow;
    } finally {
      pkgffi.calloc.free(keyExprUtf8);
      pkgffi.calloc.free(optionsPtr);
      pkgffi.calloc.free(keyExprPtr);
      // callbackPtr ownership was moved into the subscriber declaration.
      pkgffi.calloc.free(callbackPtr);
    }

    final handlerAddress = _bindings.zFifoHandlerSampleLoan(handlerPtr).address;

    final controller = StreamController<ZenohSample>();
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<Map<String, Object>>(
      _zenohFifoPollingIsolate,
      <String, Object>{
        'sendPort': receivePort.sendPort,
        'handlerAddress': handlerAddress,
      },
    );

    receivePort.listen((message) {
      if (message == null) {
        controller.close();
        receivePort.close();
      } else if (message is Map) {
        final key = message['key'] as String? ?? '';
        final data = message['payload'] as Uint8List? ?? Uint8List(0);
        controller.add(ZenohSample(keyExpr: key, payload: data));
      }
    });

    final id = _nextId++;
    _subscriberPtrs[id] = subscriberPtr;
    _fifoHandlers[id] = handlerPtr;
    _pollingPorts[id] = receivePort;
    _pollingIsolates[id] = isolate;
    _controllers[id] = controller;

    return ZenohSubscriber(subscriberPtr,
        stream: controller.stream, contextId: id);
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

  @override
  Future<void> undeclareSubscriber(ZenohSubscriber subscriber) async {
    _cleanupSubscriberById(subscriber.contextId);
    final ptr = subscriber.pointer;
    if (ptr != null) {
      _bindings.zSubscriberDrop(ptr.cast<gen.z_moved_subscriber_t>());
      pkgffi.calloc.free(ptr);
    }
  }

  void _cleanupSubscriberById(int id) {
    // Dropping the handler disconnects the FIFO channel, causing
    // z_fifo_handler_sample_recv to return Z_CHANNEL_DISCONNECTED.
    // The background isolate then exits naturally.
    final handler = _fifoHandlers.remove(id);
    if (handler != null) {
      _bindings.zFifoHandlerSampleDrop(
          handler.cast<gen.z_moved_fifo_handler_sample_t>());
      pkgffi.calloc.free(handler);
    }
    _pollingIsolates.remove(id)?.kill(priority: Isolate.immediate);
    _pollingPorts.remove(id)?.close();
    _controllers.remove(id)?.close();
    _subscriberPtrs.remove(id);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    for (final id in List<int>.from(_subscriberPtrs.keys)) {
      final ptr = _subscriberPtrs[id];
      _cleanupSubscriberById(id);
      if (ptr != null) {
        _bindings.zSubscriberDrop(ptr.cast<gen.z_moved_subscriber_t>());
        pkgffi.calloc.free(ptr);
      }
    }
    final optionsPtr = pkgffi.calloc<gen.z_close_options_t>();
    try {
      _bindings.zCloseOptionsDefault(optionsPtr);
      final rc =
          _bindings.zClose(_bindings.zSessionLoan(session.pointer), optionsPtr);
      if (rc != 0) {
        throw ZenohNativeCallException('z_close failed', errorCode: rc);
      }
    } finally {
      pkgffi.calloc.free(optionsPtr);
    }
    _bindings.zSessionDrop(session.pointer.cast<gen.z_moved_session_t>());
    pkgffi.calloc.free(session.pointer);
    _closed = true;
  }

  static void _openSession(
    ZenohBindings bindings,
    ffi.Pointer<gen.z_owned_session_t> sessionPtr,
    ZenohConfig config,
  ) {
    final configJson = jsonEncode(config.toJson());
    final configUtf8 = configJson.toNativeUtf8(allocator: pkgffi.calloc);
    final configPtr = pkgffi.calloc<gen.z_owned_config_t>();
    try {
      final rc =
          bindings.zcConfigFromStr(configPtr, configUtf8.cast<ffi.Char>());
      if (rc != 0) {
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
