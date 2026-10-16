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
import 'package:zenoh_flutter/widgets/connection_strip.dart';
import 'package:zenoh_flutter/widgets/payload_card.dart';
import 'package:zenoh_flutter/widgets/rate_meter.dart';

/// Live view of one key expression with its own subscriber.
///
/// Samples are only recorded as they arrive; a 30 Hz timer puts the newest
/// one on screen, so fast publishers never rebuild faster than that.
class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key, required this.keyExpr});

  final String keyExpr;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  static const _drawInterval = Duration(milliseconds: 33);
  static const _idleRefresh = Duration(milliseconds: 500);

  /// Images bigger than this are decoded here (off the UI thread, newest
  /// frame wins) instead of by [Image.memory]. For a protobuf or FlatBuffers
  /// sample this is the size of the image inside the message. Uncompressed
  /// images (`sensor_msgs/Image`) are always converted here, whatever their
  /// size.
  static const _largeImageBytes = 200 * 1024;

  final _session = SessionController.instance;
  final _rate = RateCounter();
  final _drawRate = RateCounter();

  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  StreamSubscription<ZenohSample>? _streamSub;
  Timer? _drawTimer;

  String? _error; // subscribe failed
  String? _closed; // session or subscription ended
  bool _paused = false;

  // Written by the stream listener only; no setState there.
  ZenohSample? _latest;
  DateTime? _latestAt;

  // Newest sample taken by the draw timer, with a sequence number so a slow
  // decode never replaces something newer.
  ZenohSample? _consumed;
  DateTime? _consumedAt;
  int _seq = 0;

  // What is on screen.
  ZenohSample? _shown;
  DateTime? _shownAt;
  int _shownSeq = -1;
  PayloadType? _type;
  bool _typeFromEmpty = false;
  DateTime _lastBuild = DateTime.fromMillisecondsSinceEpoch(0);

  // Large-image and raw-image path. [_decoded] is owned here and belongs to
  // [_shown]. [_rgba] is reused by every raw-pixel conversion (one at a time).
  ui.Image? _decoded;
  bool _decodeFailed = false;
  bool _decoding = false;
  final RgbaBuffer _rgba = RgbaBuffer();

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    final client = _session.client;
    if (client == null) {
      _closed = 'Not connected';
      return;
    }
    _client = client;
    _drawTimer = Timer.periodic(_drawInterval, (_) => _onDrawTick());
    unawaited(_subscribe(client));
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _drawTimer?.cancel();
    if (_releaseSubscriber()) {
      _session.log('Viewer unsubscribed from ${widget.keyExpr}');
    }
    _decoded?.dispose();
    _decoded = null;
    final shown = _shown;
    final shownImage = shown == null ? null : _smallImageOf(shown);
    if (shownImage != null) unawaited(MemoryImage(shownImage).evict());
    super.dispose();
  }

  Future<void> _subscribe(ZenohClient client) async {
    final keyExpr = widget.keyExpr;
    try {
      final subscriber = await client.subscribe(keyExpr);
      if (!mounted || _closed != null) {
        await _undeclare(client, subscriber, keyExpr);
        return;
      }
      _subscriber = subscriber;
      _streamSub = subscriber.stream.listen(
        _onSample,
        onError: (Object e) =>
            _session.log('Viewer $keyExpr: $e', isError: true),
        onDone: _onStreamDone,
      );
      _session.log('Viewer subscribed to $keyExpr');
    } catch (e) {
      _session.log('Viewer subscribe to $keyExpr failed: $e', isError: true);
      if (!mounted) return;
      _drawTimer?.cancel();
      setState(() => _error = '$e');
    }
  }

  void _onSample(ZenohSample sample) {
    final now = DateTime.now();
    _rate.tick(now);
    _latest = sample;
    _latestAt = now;
  }

  void _onDrawTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final latest = _latest;
    final latestAt = _latestAt;
    if (!_paused &&
        latest != null &&
        latestAt != null &&
        !identical(latest, _consumed)) {
      _consumed = latest;
      _consumedAt = latestAt;
      _seq++;
      if (_type == null || _typeFromEmpty) {
        _type = detectPayloadType(latest.payload, encoding: latest.encoding);
        _typeFromEmpty = latest.payload.isEmpty;
      }
      if (_decodesHere(latest)) {
        _startDecode(); // presents when the decode finishes
      } else {
        _present(latest, latestAt, _seq);
        return;
      }
    }
    // Keep the meters moving while paused or when the publisher stops.
    if (now.difference(_lastBuild) >= _idleRefresh) {
      _lastBuild = now;
      setState(() {});
    }
  }

  void _present(
    ZenohSample sample,
    DateTime receivedAt,
    int seq, {
    ui.Image? image,
    bool failed = false,
  }) {
    final previous = _shown;
    final oldImage = _decoded;
    _drawRate.tick();
    _lastBuild = DateTime.now();
    setState(() {
      _shown = sample;
      _shownAt = receivedAt;
      _shownSeq = seq;
      _decoded = image;
      _decodeFailed = failed;
    });
    // RawImage keeps its own clone, so our handle can go now.
    if (!identical(oldImage, image)) oldImage?.dispose();
    // Image.memory caches every frame; drop the one we just replaced.
    if (previous != null && !identical(previous, sample)) {
      final previousImage = _smallImageOf(previous);
      if (previousImage != null) {
        unawaited(MemoryImage(previousImage).evict());
      }
    }
  }

  void _startDecode() {
    final sample = _consumed;
    final at = _consumedAt;
    // While a decode runs, newer samples just replace [_consumed]; the
    // running decode picks up the newest one when it finishes.
    if (_decoding || sample == null || at == null) return;
    _decoding = true;
    unawaited(_decode(sample, at, _seq));
  }

  Future<void> _decode(ZenohSample sample, DateTime at, int seq) async {
    final raw = _drawableRawImageOf(sample);
    final data = raw == null ? _imageOf(sample) : null;
    ui.Image? image;
    if (raw != null) {
      try {
        image = await decodeRawImage(raw, scratch: _rgba);
      } catch (_) {
        image = null;
      }
    } else if (data != null) {
      try {
        final codec = await ui.instantiateImageCodec(data);
        try {
          image = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      } catch (_) {
        image = null;
      }
    }
    _decoding = false;
    if (!mounted || _closed != null || seq < _shownSeq) {
      image?.dispose();
      return;
    }
    _present(sample, at, seq, image: image, failed: image == null);
    final next = _consumed;
    if (next != null && !identical(next, sample) && _decodesHere(next)) {
      _startDecode();
    }
  }

  /// The encoded image [s] carries (its payload, or the image inside a
  /// protobuf or FlatBuffers message), or null when [s] is not an image.
  Uint8List? _imageOf(ZenohSample s) {
    final type = _type;
    return type == null ? null : imageBytesOf(s.payload, type, s.encoding);
  }

  /// The uncompressed image [s] carries when it can be drawn (a
  /// `sensor_msgs/Image` with consistent sizes), or null. One that cannot is
  /// presented as is, and the card says why.
  RawImageFrame? _drawableRawImageOf(ZenohSample s) {
    final type = _type;
    final raw = type == null ? null : rawImageOf(s.payload, type, s.encoding);
    return raw != null && raw.isDrawable ? raw : null;
  }

  /// Whether [s] is decoded here before it is shown: a large encoded image,
  /// or any drawable uncompressed one.
  bool _decodesHere(ZenohSample s) =>
      _drawableRawImageOf(s) != null ||
      (_imageOf(s)?.length ?? 0) > _largeImageBytes;

  /// The image bytes [Image.memory] decodes (and caches) for [s], or null.
  Uint8List? _smallImageOf(ZenohSample s) {
    final image = _imageOf(s);
    return image != null && image.length <= _largeImageBytes ? image : null;
  }

  void _onSession() {
    if (!mounted || _closed != null) return;
    if (_session.state == SessionState.connected &&
        identical(_session.client, _client)) {
      return;
    }
    _shutdown('Session closed');
  }

  void _onStreamDone() {
    if (!mounted || _closed != null) return;
    // The stream ended underneath us; don't undeclare twice.
    _subscriber = null;
    _streamSub = null;
    _session.log('Viewer stream for ${widget.keyExpr} closed', isError: true);
    _shutdown('Subscription closed');
  }

  void _shutdown(String message) {
    _drawTimer?.cancel();
    _drawTimer = null;
    _releaseSubscriber();
    setState(() => _closed = message);
  }

  /// Cancels the stream and undeclares (fire and forget). Returns whether a
  /// subscriber was held.
  bool _releaseSubscriber() {
    final streamSub = _streamSub;
    final subscriber = _subscriber;
    final client = _client;
    _streamSub = null;
    _subscriber = null;
    unawaited(streamSub?.cancel());
    if (subscriber == null || client == null) return false;
    unawaited(_undeclare(client, subscriber, widget.keyExpr));
    return true;
  }

  Future<void> _undeclare(
    ZenohClient client,
    ZenohSubscriber subscriber,
    String keyExpr,
  ) async {
    if (client.isClosed) return; // close() already released it
    try {
      await client.undeclareSubscriber(subscriber);
    } catch (e) {
      _session.log('Viewer undeclare $keyExpr failed: $e', isError: true);
    }
  }

  void _togglePause() => setState(() => _paused = !_paused);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _type;
    final live = _closed == null && _error == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.keyExpr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
        ),
        bottom: const ConnectionStrip(),
        actions: [
          Center(
            child: InfoChip(
              type == null ? '…' : payloadTypeLabel(type),
              emphasized: true,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: live ? _togglePause : null,
            tooltip: _paused ? 'Resume' : 'Pause',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final closed = _closed;
    if (closed != null) {
      return _Message(icon: Icons.link_off, title: closed);
    }
    final error = _error;
    if (error != null) {
      return _Message(
        icon: Icons.error_outline,
        title: 'Subscribe failed',
        detail: error,
        isError: true,
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final shown = _shown;
    final shownAt = _shownAt;
    final type = _type;
    final decodedHere = shown != null && _decodesHere(shown);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RateMeter(
          pubHz: _rate.hz(now),
          drawHz: _drawRate.hz(now),
          lastSize: shown?.payload.length,
        ),
        const SizedBox(height: 12),
        if (shown == null || type == null)
          _WaitingCard(keyExpr: widget.keyExpr)
        else
          PayloadCard(
            bytes: shown.payload,
            type: type,
            encoding: shown.encoding,
            paused: _paused,
            decodedImage: decodedHere ? _decoded : null,
            externalDecode: decodedHere,
            decodeFailed: decodedHere && _decodeFailed,
          ),
        const SizedBox(height: 8),
        Text(
          '#${_rate.total} · ${shownAt == null ? '—' : formatClock(shownAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.keyExpr});

  final String keyExpr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for samples on $keyExpr…',
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

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = this.detail;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isError ? scheme.error : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (detail != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isError ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
