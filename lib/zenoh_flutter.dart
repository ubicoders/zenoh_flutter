/// The `package:zenoh_flutter/zenoh_flutter.dart` API that sb's Flutter
/// templates are written against, implemented over this app's FFI package
/// `packages/zenoh_dart`.
///
/// It exists for sb's Flutter template. `sb io add` / `sb io update` (sb
/// 0.8.0) render `lib/swarmbotix_io/subscribers/<name>.dart` (and
/// `publishers/<name>.dart`) for a `language: flutter` module, and those
/// files import this library and use exactly this surface:
///
/// ```dart
/// final session = await Zenoh.open();                    // doc example only
/// final Subscriber sub = await session.declareSubscriber(
///     key, (Sample sample) { ... sample.payload ... });  // List<int> bytes
/// await sub.undeclare();
/// final Publisher pub = await session.declarePublisher(key);
/// await pub.put(Uint8List payload);
/// await pub.undeclare();
/// ```
///
/// The app's pubspec name is already `zenoh_flutter`, so the generated
/// files compile untouched against this file. Change this file, never the
/// generated ones: `sb io update` overwrites them.
///
/// Inside the app, wrap the session that is already open
/// (`SessionController.instance.client`) with [Session.fromClient]; it runs
/// in whatever mode that session was opened in (peer by default).
/// [Zenoh.open] opens a separate session of its own, in peer mode unless a
/// [ZenohConfig] says otherwise.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:zenoh_dart/zenoh_dart.dart';

export 'package:zenoh_dart/zenoh_dart.dart' show ZenohConfig, ZenohMode;

/// Entry point used by the generated files' example blocks.
abstract final class Zenoh {
  /// Opens a new zenoh session and returns it as a [Session] that owns it:
  /// [Session.close] closes the zenoh session too.
  ///
  /// Without [config] the session is a peer with zenoh's defaults
  /// (multicast scouting on).
  static Future<Session> open({ZenohConfig? config}) async {
    final client = await ZenohClient.connect(config ?? ZenohConfig());
    return Session._(client, owned: true);
  }
}

/// A zenoh session as the generated publishers and subscribers see it.
class Session {
  Session._(this.client, {required bool owned, this.onSample, this.onError})
    : _owned = owned;

  /// Wraps [client], a session opened elsewhere. [close] undeclares what was
  /// declared through this object and leaves [client] open.
  ///
  /// [onSample] is called for every sample of every subscriber declared
  /// through this object, before that subscriber's own callback; it lets a
  /// caller count rates or read [Sample.encoding], which the generated
  /// subscribers drop. [onError] receives errors from a subscriber stream
  /// and exceptions thrown by a callback (they are not rethrown).
  Session.fromClient(
    ZenohClient client, {
    void Function(Subscriber subscriber, Sample sample)? onSample,
    void Function(Subscriber subscriber, Object error)? onError,
  }) : this._(client, owned: false, onSample: onSample, onError: onError);

  /// The underlying zenoh_dart client.
  final ZenohClient client;

  final bool _owned;

  /// See [Session.fromClient].
  final void Function(Subscriber subscriber, Sample sample)? onSample;

  /// See [Session.fromClient].
  final void Function(Subscriber subscriber, Object error)? onError;

  final Set<Subscriber> _subscribers = {};
  final Set<Publisher> _publishers = {};

  /// True once the underlying zenoh session is closed.
  bool get isClosed => client.isClosed;

  /// Declares a subscriber on [keyExpr] that calls [callback] for each
  /// sample.
  ///
  /// Delivery starts on the next event-loop turn, never before the
  /// returned future has completed: the generated `open()` only assigns the
  /// object its callback writes to after this call returns.
  Future<Subscriber> declareSubscriber(
    String keyExpr,
    void Function(Sample sample) callback,
  ) async {
    final native = await client.subscribe(keyExpr);
    final subscriber = Subscriber._(this, native, keyExpr, callback);
    _subscribers.add(subscriber);
    Timer.run(subscriber._start);
    return subscriber;
  }

  /// Declares a publisher on [keyExpr].
  Future<Publisher> declarePublisher(String keyExpr) async {
    final native = await client.declarePublisher(keyExpr);
    final publisher = Publisher._(this, native, keyExpr);
    _publishers.add(publisher);
    return publisher;
  }

  /// Undeclares every subscriber and publisher declared through this
  /// object. Also closes the zenoh session when [Zenoh.open] opened it.
  Future<void> close() async {
    final pending = <Future<void>>[
      for (final s in _subscribers.toList()) s.undeclare(),
      for (final p in _publishers.toList()) p.undeclare(),
    ];
    if (_owned) pending.add(client.close());
    await Future.wait(pending);
  }
}

/// One received sample.
class Sample {
  const Sample({required this.keyExpr, required this.payload, this.encoding});

  Sample._from(ZenohSample sample)
    : keyExpr = sample.keyExpr,
      payload = sample.payload,
      encoding = sample.encoding;

  /// The key the sample was published on (matches the subscriber's key
  /// expression, which may contain wildcards).
  final String keyExpr;

  /// The serialized message.
  final Uint8List payload;

  /// The zenoh encoding the publisher stamped, e.g.
  /// `application/protobuf;ros2/sensor_msgs/Imu`; null when unknown.
  final String? encoding;
}

/// A subscriber declared with [Session.declareSubscriber].
class Subscriber {
  Subscriber._(this._session, this._native, this.keyExpr, this._callback);

  final Session _session;
  final ZenohSubscriber _native;
  final void Function(Sample sample) _callback;

  /// The key expression it was declared on.
  final String keyExpr;

  StreamSubscription<ZenohSample>? _streamSub;
  bool _undeclared = false;
  bool _ended = false;
  final Completer<void> _done = Completer<void>();

  /// False after [undeclare], or once the stream ended underneath it
  /// (normally because the session closed).
  bool get isActive => !_undeclared && !_ended;

  /// Completes when the subscriber stops delivering, for either reason.
  Future<void> get done => _done.future;

  void _start() {
    if (_undeclared) return;
    _streamSub = _native.stream.listen(
      _deliver,
      onError: (Object e) => _session.onError?.call(this, e),
      onDone: _onStreamDone,
    );
  }

  void _deliver(ZenohSample native) {
    if (_undeclared) return;
    final sample = Sample._from(native);
    try {
      _session.onSample?.call(this, sample);
      _callback(sample);
    } catch (e) {
      _session.onError?.call(this, e);
    }
  }

  void _onStreamDone() {
    _ended = true;
    _streamSub = null;
    _session._subscribers.remove(this);
    if (!_done.isCompleted) _done.complete();
  }

  /// Stops delivery and undeclares the subscriber. Idempotent, and safe
  /// after the session closed.
  Future<void> undeclare() async {
    if (_undeclared) return;
    _undeclared = true;
    _session._subscribers.remove(this);
    final streamSub = _streamSub;
    _streamSub = null;
    // Cancel and undeclare before any await, so both happen before a
    // client.close() that is already pending (as in TopicRegistry).
    final cancelled = streamSub?.cancel();
    final client = _session.client;
    final undeclared = client.isClosed
        ? null
        : client.undeclareSubscriber(_native);
    if (!_done.isCompleted) _done.complete();
    await undeclared;
    try {
      await cancelled;
    } catch (_) {}
  }
}

/// A publisher declared with [Session.declarePublisher].
class Publisher {
  Publisher._(this._session, this._native, this.keyExpr);

  final Session _session;
  final ZenohPublisher _native;

  /// The key expression it publishes on.
  final String keyExpr;

  bool _undeclared = false;

  /// Publishes [payload] (must not be empty). The generated publishers set
  /// no encoding, so neither does this.
  Future<void> put(Uint8List payload) {
    if (_undeclared) {
      throw StateError('Publisher on $keyExpr was undeclared');
    }
    return _session.client.publishBytes(_native, payload);
  }

  /// Undeclares the publisher. Idempotent.
  Future<void> undeclare() async {
    if (_undeclared) return;
    _undeclared = true;
    _session._publishers.remove(this);
    // After close(), zenoh_dart has no live session to undeclare from; keep
    // the small handle rather than drop it against a closed session.
    if (_session.client.isClosed) return;
    await _session.client.undeclarePublisher(_native);
  }
}
