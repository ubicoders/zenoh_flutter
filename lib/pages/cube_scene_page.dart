import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/scene/cube_scene_painter.dart';
import 'package:zenoh_flutter/scene/cube_scene_view.dart';
import 'package:zenoh_flutter/scene/scene_history.dart';
import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/topics/format.dart';
import 'package:zenoh_flutter/topics/rate_counter.dart';
import 'package:zenoh_flutter/widgets/connection_strip.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Full-screen 3D view of one `custom/CubePoses` key: the floor grid, the
/// rig's cameras, and every cube of the latest frame as a wireframe box.
///
/// Subscribes on its own, like [ViewerPage]: samples are recorded as they
/// arrive and a 30 Hz timer decodes and shows the newest one.
class CubeScenePage extends StatefulWidget {
  const CubeScenePage({super.key, required this.keyExpr});

  final String keyExpr;

  @override
  State<CubeScenePage> createState() => _CubeScenePageState();
}

enum _ViewPreset { reset, top, side }

class _CubeScenePageState extends State<CubeScenePage> {
  static const _drawInterval = Duration(milliseconds: 33);
  static const _idleRefresh = Duration(milliseconds: 500);

  final _session = SessionController.instance;
  final _rate = RateCounter();
  final _drawRate = RateCounter();
  final _camera = OrbitCamera();
  final _history = SceneHistory();

  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  StreamSubscription<ZenohSample>? _streamSub;
  Timer? _drawTimer;

  String? _error;
  String? _closed;
  bool _paused = false;
  SceneOptions _options = const SceneOptions();

  ZenohSample? _latest;
  ZenohSample? _consumed;
  DateTime? _shownAt;
  SceneFrame? _frame;
  List<SceneCube> _cubes = const [];
  String? _decodeError;
  DateTime _lastBuild = DateTime.fromMillisecondsSinceEpoch(0);

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
      _session.log('Cube scene unsubscribed from ${widget.keyExpr}');
    }
    _camera.dispose();
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
            _session.log('Cube scene $keyExpr: $e', isError: true),
        onDone: _onStreamDone,
      );
      _session.log('Cube scene subscribed to $keyExpr');
    } catch (e) {
      _session.log(
        'Cube scene subscribe to $keyExpr failed: $e',
        isError: true,
      );
      if (!mounted) return;
      _drawTimer?.cancel();
      setState(() => _error = '$e');
    }
  }

  void _onSample(ZenohSample sample) {
    _rate.tick();
    _latest = sample;
  }

  void _onDrawTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final latest = _latest;
    if (!_paused && latest != null && !identical(latest, _consumed)) {
      _consumed = latest;
      try {
        final frame = decodeCubePoses(latest.payload);
        _frame = frame;
        _cubes = _history.apply(frame);
        _decodeError = null;
      } catch (e) {
        _decodeError = '$e';
      }
      _shownAt = now;
      _drawRate.tick();
      _lastBuild = now;
      setState(() {});
      return;
    }
    if (now.difference(_lastBuild) >= _idleRefresh) {
      _lastBuild = now;
      setState(() {});
    }
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
    _subscriber = null;
    _streamSub = null;
    _session.log(
      'Cube scene stream for ${widget.keyExpr} closed',
      isError: true,
    );
    _shutdown('Subscription closed');
  }

  void _shutdown(String why) {
    _drawTimer?.cancel();
    _releaseSubscriber();
    setState(() => _closed = why);
  }

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
    if (client.isClosed) return;
    try {
      await client.undeclareSubscriber(subscriber);
    } catch (e) {
      _session.log('Cube scene undeclare $keyExpr failed: $e', isError: true);
    }
  }

  void _preset(_ViewPreset p) {
    switch (p) {
      case _ViewPreset.reset:
        _camera.set(target: V3.zero, yaw: 0, pitch: 0.62, distance: 7.5);
      case _ViewPreset.top:
        _camera.set(
          target: V3.zero,
          yaw: 0,
          pitch: OrbitCamera.maxPitch,
          distance: 8,
        );
      case _ViewPreset.side:
        _camera.set(target: V3.zero, yaw: 0, pitch: 0.08, distance: 7.5);
    }
  }

  void _centreOn(SceneCube c) {
    final p = c.position;
    if (p == null) return;
    _camera.set(target: p, distance: 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          IconButton(
            onPressed: live ? () => setState(() => _paused = !_paused) : null,
            tooltip: _paused ? 'Resume' : 'Pause',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          ),
          IconButton(
            onPressed: () => _preset(_ViewPreset.reset),
            tooltip: 'Reset view',
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
          PopupMenuButton<Object>(
            tooltip: 'Scene',
            onSelected: (v) {
              if (v is _ViewPreset) {
                _preset(v);
              } else if (v is String) {
                setState(() => _options = _toggle(_options, v));
              }
            },
            itemBuilder: (_) => [
              _check('grid', 'Floor grid', _options.grid),
              _check('cameras', 'Cameras', _options.cameras),
              _check('bodyAxes', 'Body axes on cubes', _options.bodyAxes),
              _check('trails', 'Trails', _options.trails),
              _check('velocity', 'Velocity arrows', _options.velocity),
              _check('labels', 'Labels', _options.labels),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ViewPreset.top,
                child: Text('View from top'),
              ),
              const PopupMenuItem(
                value: _ViewPreset.side,
                child: Text('View from side'),
              ),
              const PopupMenuItem(
                value: _ViewPreset.reset,
                child: Text('Reset view'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  static PopupMenuItem<Object> _check(String key, String label, bool on) =>
      CheckedPopupMenuItem<Object>(value: key, checked: on, child: Text(label));

  static SceneOptions _toggle(SceneOptions o, String key) => switch (key) {
    'grid' => o.copyWith(grid: !o.grid),
    'cameras' => o.copyWith(cameras: !o.cameras),
    'bodyAxes' => o.copyWith(bodyAxes: !o.bodyAxes),
    'trails' => o.copyWith(trails: !o.trails),
    'velocity' => o.copyWith(velocity: !o.velocity),
    'labels' => o.copyWith(labels: !o.labels),
    _ => o,
  };

  Widget _buildBody(BuildContext context) {
    final closed = _closed;
    final error = _error;
    if (closed != null) return _Message(Icons.link_off, closed);
    if (error != null) {
      return _Message(Icons.error_outline, 'Subscribe failed: $error');
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CubeSceneView(
                camera: _camera,
                cubes: _cubes,
                options: _options,
                trails: _history.trails,
              ),
              if (_paused)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Chip(label: Text('PAUSED')),
                ),
              if (_frame == null && _decodeError == null)
                const Center(
                  child: Text(
                    'Waiting for the first CubePoses frame…',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        _StatusPanel(
          frame: _frame,
          cubes: _cubes,
          now: DateTime.now(),
          shownAt: _shownAt,
          pubHz: _rate.hz(DateTime.now()),
          drawHz: _drawRate.hz(DateTime.now()),
          decodeError: _decodeError,
          onTapCube: _centreOn,
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.frame,
    required this.cubes,
    required this.now,
    required this.shownAt,
    required this.pubHz,
    required this.drawHz,
    required this.decodeError,
    required this.onTapCube,
  });

  final SceneFrame? frame;
  final List<SceneCube> cubes;
  final DateTime now;
  final DateTime? shownAt;
  final double pubHz;
  final double drawHz;
  final String? decodeError;
  final void Function(SceneCube) onTapCube;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: _tabular,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final f = frame;
    final latency = f == null || shownAt == null
        ? null
        : shownAt!.difference(f.stamp).inMilliseconds;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PUB ${formatHz(pubHz)} · DRAW ${formatHz(drawHz)}'
                '${f == null ? '' : ' · frame ${f.frameSeq}'}'
                '${latency == null ? '' : ' · latency $latency ms'}',
                style: mono,
              ),
              if (decodeError != null)
                Text(
                  'Decode failed: $decodeError',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              for (final c in cubes)
                _CubeRow(cube: c, now: now, onTap: onTapCube),
              if (f != null && cubes.isEmpty)
                Text('No cube seen yet', style: mono),
            ],
          ),
        ),
      ),
    );
  }
}

class _CubeRow extends StatelessWidget {
  const _CubeRow({required this.cube, required this.now, required this.onTap});

  final SceneCube cube;
  final DateTime now;
  final void Function(SceneCube) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: _tabular,
    );
    final color = cubeColor(cube.id);
    final p = cube.position;
    final e = cube.eulerDeg;
    final ago = now.difference(cube.lastSeen);
    final status = cube.alive
        ? '${cube.numCameras} cam · rms ${(cube.residualRms * 1000).toStringAsFixed(1)} mm'
        : 'stale · last seen ${(ago.inMilliseconds / 1000).toStringAsFixed(1)} s ago';
    return InkWell(
      onTap: p == null ? null : () => onTap(cube),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                cube.alive ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('cube ${cube.id}  $status', style: mono),
                  if (p != null)
                    Text(
                      'xyz ${_m(p.x)} ${_m(p.y)} ${_m(p.z)} m'
                      '${e == null ? '' : '   rpy ${_d(e.x)} ${_d(e.y)} ${_d(e.z)} °'}',
                      style: mono?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _m(double v) => v.toStringAsFixed(3).padLeft(7);
  static String _d(double v) => v.toStringAsFixed(1).padLeft(6);
}

class _Message extends StatelessWidget {
  const _Message(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
