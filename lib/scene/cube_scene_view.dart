/// cube_scene_view: the 3D viewport widget. Drag orbits, pinch or scroll
/// zooms, a two-finger drag pans. With [interactive] false it is a fixed
/// preview (the card on the swarmbotix io page).
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:zenoh_flutter/scene/cube_scene_painter.dart';
import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';

class CubeSceneView extends StatefulWidget {
  const CubeSceneView({
    super.key,
    required this.camera,
    required this.cubes,
    this.options = const SceneOptions(),
    this.trails = const {},
    this.interactive = true,
    this.labelScale = 1.0,
  });

  final OrbitCamera camera;
  final List<SceneCube> cubes;
  final SceneOptions options;
  final Map<int, List<V3>> trails;
  final bool interactive;
  final double labelScale;

  @override
  State<CubeSceneView> createState() => _CubeSceneViewState();
}

class _CubeSceneViewState extends State<CubeSceneView> {
  double _startDistance = 0;
  Size _size = Size.zero;

  void _onScaleStart(ScaleStartDetails d) {
    _startDistance = widget.camera.distance;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final cam = widget.camera;
    if (d.pointerCount <= 1) {
      cam.orbit(d.focalPointDelta.dx, d.focalPointDelta.dy);
      return;
    }
    cam.set(distance: _startDistance / math.max(d.scale, 0.01));
    cam.pan(d.focalPointDelta.dx, d.focalPointDelta.dy, _size);
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      widget.camera.zoomBy(math.exp(-e.scrollDelta.dy / 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paint = LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return CustomPaint(
          size: _size,
          painter: CubeScenePainter(
            camera: widget.camera,
            cubes: widget.cubes,
            options: widget.options,
            trails: widget.trails,
            labelScale: widget.labelScale,
          ),
        );
      },
    );
    if (!widget.interactive) return paint;
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: paint,
      ),
    );
  }
}
