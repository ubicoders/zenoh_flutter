import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/proto/ros2/custom/CubePoses.pb.dart' as pb;
import 'package:zenoh_flutter/proto/ros2/custom/MarkerDetections.pb.dart'
    as pb_md;
import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';

// Rz(a): a yaw about z, row-major.
M3 rz(double a) => M3([
  math.cos(a), -math.sin(a), 0, //
  math.sin(a), math.cos(a), 0, //
  0, 0, 1,
]);

pb.CubePoses message(String frame, V3 p, M3 r, V3 v) => pb.CubePoses(
  stampSec: 1,
  frameSeq: Int64(7),
  frame: frame,
  cubes: [
    pb.CubePose(
      cubeId: 1,
      alive: true,
      position: pb_md.Vec3(x: p.x, y: p.y, z: p.z),
      rotation: pb.Mat3(m: r.m),
      velocity: pb_md.Vec3(x: v.x, y: v.y, z: v.z),
      eulerDeg: pb_md.Vec3(x: 1, y: 2, z: 3),
    ),
    pb.CubePose(cubeId: 2, alive: false),
  ],
);

void close(V3 a, V3 b, String what) {
  expect((a - b).length, lessThan(1e-9), reason: what);
}

void main() {
  // Board-frame truth: 1 m toward the board's top row, 0.5 m above the floor.
  final pBoard = const V3(0.0, -1.0, -0.5);
  final rBoard = rz(0.4);
  final vBoard = const V3(1, 2, 3);

  test('RDF and an empty frame pass through', () {
    for (final name in ['RDF', '', 'rdf']) {
      final f = decodeCubePoses(
        message(name, pBoard, rBoard, vBoard).writeToBuffer(),
      );
      expect(f.frame, 'RDF');
      expect(f.frameKnown, isTrue);
      close(f.cubes[0].position!, pBoard, '$name pos');
      expect(f.cubes[0].rotation!.m, rBoard.m);
      close(f.cubes[0].eulerDeg!, const V3(1, 2, 3), '$name euler verbatim');
      expect(f.cubes[1].position, isNull);
    }
  });

  test('FRD and FRU are mapped back to the board frame', () {
    for (final name in ['FRD', 'FRU']) {
      final c = wireFrames[name]!;
      // What the tracker publishes for that truth.
      final pWire = c.apply(pBoard);
      final rWire = c.mul(rBoard).mul(c.transposed);
      final vWire = c.apply(vBoard);
      final f = decodeCubePoses(
        message(name, pWire, rWire, vWire).writeToBuffer(),
      );
      expect(f.frame, name);
      expect(f.frameKnown, isTrue);
      final cube = f.cubes[0];
      close(cube.position!, pBoard, '$name pos');
      close(cube.velocity!, vBoard, '$name vel');
      for (var i = 0; i < 9; i++) {
        expect(cube.rotation!.m[i], closeTo(rBoard.m[i], 1e-9), reason: name);
      }
      // Euler is recomputed from the mapped rotation: a 0.4 rad yaw.
      close(cube.eulerDeg!, V3(0, 0, 0.4 * 180 / math.pi), '$name euler');
    }
  });

  test('an unknown frame is flagged and drawn as the board frame', () {
    final f = decodeCubePoses(
      message('ENU', pBoard, rBoard, vBoard).writeToBuffer(),
    );
    expect(f.frame, 'ENU');
    expect(f.frameKnown, isFalse);
    close(f.cubes[0].position!, pBoard, 'unknown pos');
  });

  test('FRD stands the board camera on the floor', () {
    // Up is board -z: 2 m above the floor is FRU z = +2, FRD z = -2.
    final up = const V3(0, 0, -2);
    expect(wireFrames['FRU']!.apply(up).z, 2);
    expect(wireFrames['FRD']!.apply(up).z, -2);
    // Toward the board's top row (board -y) is forward (x) in both.
    expect(wireFrames['FRD']!.apply(const V3(0, -1, 0)).x, 1);
  });
}
