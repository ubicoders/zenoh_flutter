/// cube_scene_painter: draws the world the way `ips_viz` shows it in rerun —
/// a dark gradient, the floor grid, a labelled yellow dot with RGB axes per
/// camera, and a coloured wireframe box with a label per cube.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';

/// What the scene shows besides the cubes.
class SceneOptions {
  const SceneOptions({
    this.grid = true,
    this.cameras = true,
    this.bodyAxes = true,
    this.trails = false,
    this.velocity = false,
    this.labels = true,
  });

  final bool grid;
  final bool cameras;
  final bool bodyAxes;
  final bool trails;
  final bool velocity;
  final bool labels;

  SceneOptions copyWith({
    bool? grid,
    bool? cameras,
    bool? bodyAxes,
    bool? trails,
    bool? velocity,
    bool? labels,
  }) => SceneOptions(
    grid: grid ?? this.grid,
    cameras: cameras ?? this.cameras,
    bodyAxes: bodyAxes ?? this.bodyAxes,
    trails: trails ?? this.trails,
    velocity: velocity ?? this.velocity,
    labels: labels ?? this.labels,
  );
}

/// The scene is always dark, whatever the app theme, like the rerun viewer.
class ScenePalette {
  static const bgTop = Color(0xFF3A1D5C);
  static const bgMid = Color(0xFF4A1A4B);
  static const bgBottom = Color(0xFF3B1238);
  static const grid = Color(0x40FFFFFF);
  static const gridAxis = Color(0x80FFFFFF);
  static const camera = Color(0xFFFFEB3B);
  static const axisX = Color(0xFFFF4040);
  static const axisY = Color(0xFF40E040);
  static const axisZ = Color(0xFF5080FF);
  static const labelBg = Color(0x8A000000);
  static const velocity = Color(0xFFFFFFFF);
}

class CubeScenePainter extends CustomPainter {
  CubeScenePainter({
    required this.camera,
    required this.cubes,
    required this.options,
    this.trails = const {},
    this.gridHalfExtent = 4.0,
    this.gridStep = 0.5,
    this.labelScale = 1.0,
  }) : super(repaint: camera);

  final OrbitCamera camera;

  /// Cubes to draw. A stale cube is drawn dimmed when it still has a pose
  /// (the caller carries the last alive one through).
  final List<SceneCube> cubes;
  final SceneOptions options;

  /// Recent centre positions per cube id, oldest first.
  final Map<int, List<V3>> trails;

  final double gridHalfExtent;
  final double gridStep;
  final double labelScale;

  static const double cameraAxisLen = 0.25;
  static const double bodyAxisLen = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    _background(canvas, size);
    final p = Projector(camera, size);
    if (options.grid) _grid(canvas, p);
    if (options.cameras) _cameras(canvas, p);
    if (options.trails) _trails(canvas, p);
    _cubes(canvas, p);
  }

  void _background(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const [ScenePalette.bgTop, ScenePalette.bgMid, ScenePalette.bgBottom],
          const [0, 0.55, 1],
        ),
    );
  }

  void _line(Canvas canvas, Projector p, V3 a, V3 b, Paint paint) {
    final seg = p.projectSegment(a, b);
    if (seg == null) return;
    canvas.drawLine(seg.$1, seg.$2, paint);
  }

  void _grid(Canvas canvas, Projector p) {
    final paint = Paint()
      ..color = ScenePalette.grid
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = ScenePalette.gridAxis
      ..strokeWidth = 1;
    final n = (gridHalfExtent / gridStep).round();
    for (var i = -n; i <= n; i++) {
      final v = i * gridStep;
      final onAxis = i == 0;
      _line(
        canvas,
        p,
        V3(v, -gridHalfExtent, 0),
        V3(v, gridHalfExtent, 0),
        onAxis ? axisPaint : paint,
      );
      _line(
        canvas,
        p,
        V3(-gridHalfExtent, v, 0),
        V3(gridHalfExtent, v, 0),
        onAxis ? axisPaint : paint,
      );
    }
  }

  void _triad(Canvas canvas, Projector p, V3 origin, M3 r, double len) {
    const colors = [ScenePalette.axisX, ScenePalette.axisY, ScenePalette.axisZ];
    for (var c = 0; c < 3; c++) {
      _line(
        canvas,
        p,
        origin,
        origin + r.col(c) * len,
        Paint()
          ..color = colors[c]
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _cameras(Canvas canvas, Projector p) {
    for (final cam in sceneCameras) {
      _triad(canvas, p, cam.t, cam.r, cameraAxisLen);
      final o = p.project(cam.t);
      if (o == null) continue;
      canvas.drawCircle(o, 4.5, Paint()..color = ScenePalette.camera);
      if (options.labels) {
        _label(canvas, o + const Offset(0, 8), cam.name, ScenePalette.camera);
      }
    }
  }

  void _trails(Canvas canvas, Projector p) {
    for (final entry in trails.entries) {
      final pts = entry.value;
      if (pts.length < 2) continue;
      final color = cubeColor(entry.key);
      for (var i = 1; i < pts.length; i++) {
        final alpha = 0.15 + 0.6 * i / pts.length;
        _line(
          canvas,
          p,
          pts[i - 1],
          pts[i],
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _cubes(Canvas canvas, Projector p) {
    // Far cubes first so near labels end up on top.
    final drawable = [
      for (final c in cubes)
        if (c.position != null) c,
    ]..sort((a, b) => p.depth(b.position!).compareTo(p.depth(a.position!)));

    for (final cube in drawable) {
      final color = cube.alive
          ? cubeColor(cube.id)
          : cubeColor(cube.id).withValues(alpha: 0.35);
      final corners = cube.corners()!;
      final edge = Paint()
        ..color = color
        ..strokeWidth = cube.alive ? 1.6 : 1.0
        ..strokeCap = StrokeCap.round;
      for (final (a, b) in SceneCube.edges) {
        _line(canvas, p, corners[a], corners[b], edge);
      }
      final centre = cube.position!;
      if (options.bodyAxes && cube.alive) {
        _triad(canvas, p, centre, cube.rotation!, bodyAxisLen);
      }
      final v = cube.velocity;
      if (options.velocity && cube.alive && v != null && v.length > 0.01) {
        _arrow(canvas, p, centre, centre + v * 0.5, ScenePalette.velocity);
      }
      if (options.labels) {
        final o = p.project(centre);
        if (o != null) {
          final r = p.focal * SceneCube.half / math.max(p.depth(centre), 0.1);
          _label(
            canvas,
            o + Offset(0, r + 4),
            cube.alive ? 'cube ${cube.id}' : 'cube ${cube.id} · stale',
            color,
          );
        }
      }
    }
  }

  void _arrow(Canvas canvas, Projector p, V3 from, V3 to, Color color) {
    final seg = p.projectSegment(from, to);
    if (seg == null) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(seg.$1, seg.$2, paint);
    final d = seg.$2 - seg.$1;
    if (d.distance < 4) return;
    final dir = d / d.distance;
    final n = Offset(-dir.dy, dir.dx);
    canvas.drawLine(seg.$2, seg.$2 - dir * 6 + n * 3, paint);
    canvas.drawLine(seg.$2, seg.$2 - dir * 6 - n * 3, paint);
  }

  void _label(Canvas canvas, Offset at, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12 * labelScale,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx - tp.width / 2 - 4,
      at.dy,
      tp.width + 8,
      tp.height + 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = ScenePalette.labelBg,
    );
    tp.paint(canvas, Offset(rect.left + 4, rect.top + 1));
  }

  @override
  bool shouldRepaint(CubeScenePainter old) =>
      old.camera != camera ||
      old.cubes != cubes ||
      old.options != options ||
      old.trails != trails ||
      old.labelScale != labelScale;
}
