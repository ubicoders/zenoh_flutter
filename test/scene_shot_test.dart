// Renders the cube scene to a PNG so it can be looked at without a device:
//   SHOT_DIR=/some/dir flutter test test/scene_shot_test.dart
// Skipped when SHOT_DIR is unset. Text renders as boxes (the test font).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/scene/cube_scene_painter.dart';
import 'package:zenoh_flutter/scene/cube_scene_view.dart';
import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';

M3 rz(double a) =>
    M3([math.cos(a), -math.sin(a), 0, math.sin(a), math.cos(a), 0, 0, 0, 1]);

SceneCube cube(int id, double x, double y, double yaw, {bool alive = true}) =>
    SceneCube(
      id: id,
      alive: alive,
      position: V3(x, y, 0.05),
      rotation: rz(yaw),
      velocity: V3(0.3, 0.1, 0),
      eulerDeg: V3(0, 0, yaw * 180 / math.pi),
      markerIds: const [0, 1, 2],
      numCameras: 2,
      residualRms: 0.002,
      lastSeen: DateTime.now(),
    );

void main() {
  final out = Platform.environment['SHOT_DIR'];
  testWidgets('scene shot', skip: out == null, (tester) async {
    final cubes = [
      cube(0, 0.5, 0.0, 0.3),
      cube(1, -0.35, 0.35, 1.2, alive: false),
    ];
    await tester.binding.setSurfaceSize(const Size(900, 640));
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: CubeSceneView(
            camera: OrbitCamera(),
            cubes: cubes,
            options: const SceneOptions(velocity: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$out/scene.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
