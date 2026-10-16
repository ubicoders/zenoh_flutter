import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/topics/format.dart';
import 'package:zenoh_flutter/topics/info_chip.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/rate_counter.dart';
import 'package:zenoh_flutter/topics/raw_image.dart';
import 'package:zenoh_flutter/topics/sbio_topics.dart';
import 'package:zenoh_flutter/widgets/connection_strip.dart';
import 'package:zenoh_flutter/widgets/payload_card.dart';
import 'package:zenoh_flutter/widgets/rate_meter.dart';
import 'package:zenoh_flutter/zenoh_flutter.dart' as sb;

const _tabular = [FontFeature.tabularFigures()];

/// One live card per `sb io` subscriber of this module ([sbioTopics]).
///
/// Opens the generated subscribers on the app's session while the screen
/// is open, and again after the session reconnects; closes them when the
/// screen is left or the session drops. The generated subscribers are
/// polling (`tryRecvLatest()`), so a 30 Hz timer takes the newest payload
/// of each. PUB HZ comes from a tap on the session wrapper, which sees every
/// sample. Payloads are decoded with the wire tag the sb publisher stamps
/// for the entry's type and encoding, so the cards work whatever encoding
/// actually arrives; the line under each card shows that one. Uncompressed
/// images (`sensor_msgs/Image`) are converted per slot before they are
/// shown, newest frame first.
class SbioPage extends StatefulWidget {
  const SbioPage({super.key});

  @override
  State<SbioPage> createState() => _SbioPageState();
}

class _SbioPageState extends State<SbioPage> {
  static const _drawInterval = Duration(milliseconds: 33);
  static const _idleRefresh = Duration(milliseconds: 500);

  final _session = SessionController.instance;
  late final List<_Slot> _slots = [
    for (final t in sbioTopics) _Slot(t, onDecoded: _onSlotDecoded),
  ];
  late final Map<String, _Slot> _byKey = {
    for (final s in _slots) s.topic.keyExpr: s,
  };

  /// The session the subscribers are open on; null while closed.
  ZenohClient? _client;
  int _generation = 0;
  Timer? _drawTimer;
  DateTime _lastBuild = DateTime.fromMillisecondsSinceEpoch(0);
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    _drawTimer = Timer.periodic(_drawInterval, (_) => _onDrawTick());
    _open();
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _drawTimer?.cancel();
    _logClosed(_close());
    for (final slot in _slots) {
      slot.clear();
    }
    super.dispose();
  }

  /// Opens every generated subscriber on the current session, if any.
  void _open() {
    final client = _session.client;
    if (client == null) return;
    final generation = ++_generation;
    _client = client;
    final wrapper = sb.Session.fromClient(
      client,
      onSample: (subscriber, sample) {
        if (generation == _generation) _onSample(subscriber, sample);
      },
      onError: (subscriber, error) {
        if (generation == _generation) _onError(subscriber, error);
      },
    );
    for (final slot in _slots) {
      slot.clear();
      unawaited(_openSlot(slot, wrapper, generation));
    }
  }

  Future<void> _openSlot(_Slot slot, sb.Session wrapper, int generation) async {
    final key = slot.topic.keyExpr;
    try {
      final receiver = await slot.topic.open(wrapper);
      if (!mounted || generation != _generation) {
        await receiver.close();
        return;
      }
      slot.receiver = receiver;
      _session.log('sb io subscribed to $key (${slot.topic.type})');
    } catch (e) {
      if (!mounted || generation != _generation) return;
      slot.error = '$e';
      _session.log('sb io subscribe to $key failed: $e', isError: true);
    }
    if (mounted) setState(() {});
  }

  /// Closes every open subscriber and returns how many there were. Each
  /// generated close() undeclares before its first await, so this runs ahead
  /// of a pending session close.
  ///
  /// Does not log: logging notifies the session's listeners, [_onSession]
  /// among them, so callers log once their own state is settled.
  int _close() {
    _generation++;
    _client = null;
    var closed = 0;
    for (final slot in _slots) {
      final receiver = slot.receiver;
      slot.receiver = null;
      if (receiver == null) continue;
      closed++;
      unawaited(
        receiver.close().catchError((Object e) {
          _session.log(
            'sb io close ${slot.topic.keyExpr} failed: $e',
            isError: true,
          );
        }),
      );
    }
    return closed;
  }

  void _logClosed(int closed) {
    if (closed > 0) _session.log('sb io closed $closed subscribers');
  }

  void _onSession() {
    if (!mounted) return;
    final client = _session.client; // non-null iff connected
    if (identical(client, _client)) return;
    final closed = _close();
    _open(); // no-op unless connected
    _logClosed(closed);
    setState(() {});
  }

  void _onSample(sb.Subscriber subscriber, sb.Sample sample) {
    final slot = _byKey[subscriber.keyExpr];
    if (slot == null) return;
    slot.rate.tick();
    slot.wireEncoding = sample.encoding;
  }

  void _onError(sb.Subscriber subscriber, Object error) {
    final slot = _byKey[subscriber.keyExpr];
    if (slot == null || slot.errorLogged) return;
    slot.errorLogged = true; // once per slot and session, not per sample
    _session.log('sb io ${subscriber.keyExpr}: $error', isError: true);
  }

  /// A slot finished converting a raw image and now shows it.
  void _onSlotDecoded() {
    if (!mounted) return;
    _lastBuild = DateTime.now();
    setState(() {});
  }

  void _onDrawTick() {
    if (!mounted) return;
    final now = DateTime.now();
    var changed = false;
    // While the Viewer covers this screen, payloads just wait in the
    // generated subscribers (each keeps only its newest one).
    if (_visible) {
      for (final slot in _slots) {
        final bytes = slot.receiver?.tryRecvLatest();
        if (bytes == null) continue;
        slot.show(bytes, now);
        changed = true;
      }
    }
    if (changed || (_visible && now.difference(_lastBuild) >= _idleRefresh)) {
      _lastBuild = now;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also rebuilds this page when it becomes current again.
    _visible = ModalRoute.of(context)?.isCurrent ?? true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('swarmbotix io'),
        bottom: const ConnectionStrip(),
      ),
      body: _session.state == SessionState.connected
          ? _buildSlots(context)
          : _NotConnected(state: _session.state, error: _session.errorText),
    );
  }

  Widget _buildSlots(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final open = _slots.where((s) => s.receiver != null).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'module zenoh_flutter · $open of ${_slots.length} '
          'subscribers open · sb.module.yaml',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontFeatures: _tabular,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final slot in _slots) ...[
          const SizedBox(height: 16),
          _SlotView(slot: slot, now: now),
        ],
      ],
    );
  }
}

/// What the screen knows about one [SbioTopic].
class _Slot {
  _Slot(this.topic, {required this.onDecoded});

  final SbioTopic topic;

  /// Called when a raw image has been converted and is now [shown].
  final VoidCallback onDecoded;

  /// Fixed by the entry's encoding: protobuf or flatbuffers.
  late final PayloadType type = detectPayloadType(
    Uint8List(0),
    encoding: topic.wireTag,
  );

  SbioReceiver? receiver;
  String? error;
  bool errorLogged = false;

  /// Samples received (PUB HZ) and put on screen (DRAW HZ).
  final RateCounter rate = RateCounter();
  final RateCounter drawRate = RateCounter();

  /// The encoding of the newest sample as it arrived on the wire.
  String? wireEncoding;

  Uint8List? shown;
  DateTime? shownAt;

  // A drawable uncompressed image (sensor_msgs/Image) is converted to
  // [image] before it is shown, one frame at a time: what arrives meanwhile
  // waits in [_pending], newest wins, and older frames are dropped. [image]
  // belongs to [shown] and is owned here; [_rgba] is reused by every
  // conversion.
  ui.Image? image;
  bool imageFailed = false;
  ({Uint8List bytes, RawImageFrame frame, DateTime at, int seq})? _pending;
  bool _decoding = false;
  int _seq = 0; // per payload taken
  int _shownSeq = -1;
  int _epoch = 0; // bumped by clear(), which drops conversions in flight
  final RgbaBuffer _rgba = RgbaBuffer();

  void show(Uint8List bytes, DateTime now) {
    final seq = ++_seq;
    final raw = rawImageOf(bytes, type, topic.wireTag);
    if (raw != null && raw.isDrawable) {
      _pending = (bytes: bytes, frame: raw, at: now, seq: seq);
      if (!_decoding) unawaited(_decodePending());
      return;
    }
    _present(bytes, now, seq);
  }

  Future<void> _decodePending() async {
    final epoch = _epoch;
    _decoding = true;
    for (var next = _pending; next != null; next = _pending) {
      _pending = null;
      ui.Image? decoded;
      try {
        decoded = await decodeRawImage(next.frame, scratch: _rgba);
      } catch (_) {
        decoded = null;
      }
      if (epoch != _epoch) {
        decoded?.dispose();
        return; // clear() has reset the rest
      }
      if (next.seq < _shownSeq) {
        decoded?.dispose(); // something newer is on screen already
        continue;
      }
      _present(
        next.bytes,
        next.at,
        next.seq,
        image: decoded,
        failed: decoded == null,
      );
      onDecoded();
    }
    _decoding = false;
  }

  void _present(
    Uint8List bytes,
    DateTime at,
    int seq, {
    ui.Image? image,
    bool failed = false,
  }) {
    final previous = shown;
    final oldImage = this.image;
    shown = bytes;
    shownAt = at;
    _shownSeq = seq;
    this.image = image;
    imageFailed = failed;
    drawRate.tick();
    // RawImage keeps its own clone, so the replaced handle can go now.
    if (!identical(oldImage, image)) oldImage?.dispose();
    // Image.memory caches every frame; drop the one just replaced.
    if (previous != null && !identical(previous, bytes)) _evict(previous);
  }

  /// Forgets everything from the previous session.
  void clear() {
    final previous = shown;
    if (previous != null) _evict(previous);
    _epoch++;
    _decoding = false;
    _pending = null;
    image?.dispose();
    image = null;
    imageFailed = false;
    _shownSeq = -1;
    shown = null;
    shownAt = null;
    wireEncoding = null;
    error = null;
    errorLogged = false;
    rate.reset();
    drawRate.reset();
  }

  void _evict(Uint8List payload) {
    final image = imageBytesOf(payload, type, topic.wireTag);
    if (image != null) unawaited(MemoryImage(image).evict());
  }
}

class _SlotView extends StatelessWidget {
  const _SlotView({required this.slot, required this.now});

  final _Slot slot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = slot.topic;
    final shown = slot.shown;
    final shownAt = slot.shownAt;
    final error = slot.error;
    final wire = slot.wireEncoding;
    final small = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: _tabular,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              Navigator.pushNamed(context, '/view', arguments: topic.keyExpr),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(topic.keyExpr, style: small),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          InfoChip(
                            payloadTypeLabel(slot.type),
                            emphasized: true,
                          ),
                          InfoChip(topic.type),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        RateMeter(
          pubHz: slot.rate.hz(now),
          drawHz: slot.drawRate.hz(now),
          lastSize: shown?.length,
        ),
        const SizedBox(height: 8),
        if (error != null)
          Text(
            'Subscribe failed: $error',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else if (shown == null)
          _WaitingCard(keyExpr: topic.keyExpr, active: slot.receiver != null)
        else
          PayloadCard(
            bytes: shown,
            type: slot.type,
            encoding: topic.wireTag,
            decodedImage: slot.image,
            decodeFailed: slot.imageFailed,
          ),
        const SizedBox(height: 4),
        Text(
          '#${slot.rate.total} · '
          '${shownAt == null ? '—' : formatClock(shownAt)} · '
          'wire ${wire ?? '—'}',
          style: wire != null && wire != topic.wireTag
              ? small?.copyWith(color: theme.colorScheme.error)
              : small,
        ),
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.keyExpr, required this.active});

  final String keyExpr;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: active
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                active ? 'Waiting for samples…' : 'Subscribing…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.state, required this.error});

  final SessionState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connecting = state == SessionState.connecting;
    final err = state == SessionState.error ? error : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connecting)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(
                Icons.link_off,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: 12),
            Text(
              connecting ? 'Connecting…' : 'Not connected',
              style: theme.textTheme.titleMedium,
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back to settings'),
            ),
          ],
        ),
      ),
    );
  }
}
