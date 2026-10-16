/// scene_model: what the cube scene draws, decoded from `custom/CubePoses`,
/// plus the static world geometry (the camera extrinsics) the message does
/// not carry.
library;

import 'dart:typed_data';
import 'dart:ui';

import 'package:zenoh_flutter/proto/ros2/custom/CubePoses.pb.dart' as pb;
import 'package:zenoh_flutter/proto/ros2/custom/MarkerDetections.pb.dart'
    as pb_md;
import 'package:zenoh_flutter/scene/scene_math.dart';

/// Edge of the marker cube, metres (`marker_size` in detector_params.yaml).
const double cubeEdge = 0.087;

/// Display-only scale of the drawn box about its centre, as `cube_viz_scale`
/// in ips_viz: the true cube is small next to a 0.5 m grid cell.
const double cubeVizScale = 1.5;

/// A fixed camera of the rig: its pose in the world, `world = R * cam + t`,
/// from `calibration/extrinsics/<name>_full.yaml`. The app has no access to
/// those files, so the four cameras of the workshop rig are listed here.
class SceneCamera {
  const SceneCamera({required this.name, required this.r, required this.t});

  final String name;
  final M3 r;
  final V3 t;
}

const List<SceneCamera> sceneCameras = [
  SceneCamera(
    name: 'sb00',
    r: M3([
      0.738253398, -0.232446801, 0.633206448, //
      0.665006087, 0.407958870, -0.625568913, //
      -0.112910695, 0.882914517, 0.455755560,
    ]),
    t: V3(-1.742744, 2.237757, -2.173919),
  ),
  SceneCamera(
    name: 'sb01',
    r: M3([
      -0.725690164, -0.226225579, 0.649765938, //
      0.687392307, -0.278777203, 0.670652732, //
      0.029421128, 0.933330198, 0.357811597,
    ]),
    t: V3(-1.863517, -2.915746, -1.867935),
  ),
  SceneCamera(
    name: 'sb02',
    r: M3([
      -0.870048695, 0.185920473, -0.456561985, //
      -0.492498609, -0.368136560, 0.788619422, //
      -0.021456663, 0.910993442, 0.411862308,
    ]),
    t: V3(1.570381, -3.086084, -2.068263),
  ),
  SceneCamera(
    name: 'sb03',
    r: M3([
      0.260876769, 0.410920194, -0.873549029, //
      -0.964765954, 0.078913513, -0.250996637, //
      -0.034204764, 0.908249553, 0.417028516,
    ]),
    t: V3(1.993789, 1.164126, -1.925418),
  ),
];

/// A stable per-cube colour, the palette of `ips_viz::cube_color`.
Color cubeColor(int id) {
  const palette = [
    Color(0xFFE65050),
    Color(0xFF50C878),
    Color(0xFF5A96F0),
    Color(0xFFF0BE46),
    Color(0xFFC86EE6),
    Color(0xFF5ADCDC),
  ];
  return palette[id % palette.length];
}

/// One cube of a frame. [position] and [rotation] are null when the cube is
/// stale (`alive == false`); the tracker clears them.
class SceneCube {
  const SceneCube({
    required this.id,
    required this.alive,
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.eulerDeg,
    required this.markerIds,
    required this.numCameras,
    required this.residualRms,
    required this.lastSeen,
  });

  final int id;
  final bool alive;
  final V3? position;
  final M3? rotation;
  final V3? velocity;
  final V3? eulerDeg;
  final List<int> markerIds;
  final int numCameras;
  final double residualRms;
  final DateTime lastSeen;

  /// Half-extents of the drawn box.
  static const double half = cubeEdge * cubeVizScale / 2;

  /// The eight corners in the world, body order `(±x, ±y, ±z)`, or null
  /// when stale.
  List<V3>? corners() {
    final t = position;
    final r = rotation;
    if (t == null || r == null) return null;
    return [
      for (final sz in const [-1.0, 1.0])
        for (final sy in const [-1.0, 1.0])
          for (final sx in const [-1.0, 1.0])
            t + r.apply(V3(sx * half, sy * half, sz * half)),
    ];
  }

  /// Corner index pairs of the twelve edges, for [corners].
  static const List<(int, int)> edges = [
    (0, 1), (1, 3), (3, 2), (2, 0), // -z (TOP) face
    (4, 5), (5, 7), (7, 6), (6, 4), // +z (BOTTOM) face
    (0, 4), (1, 5), (2, 6), (3, 7), // verticals
  ];
}

/// One decoded `CubePoses` message.
class SceneFrame {
  const SceneFrame({
    required this.frameSeq,
    required this.stamp,
    required this.cubes,
  });

  final int frameSeq;
  final DateTime stamp;
  final List<SceneCube> cubes;
}

V3? _vec(pb_md.Vec3 v, bool present) => present ? V3(v.x, v.y, v.z) : null;

/// Decodes a wire `CubePoses` payload. Throws on malformed bytes.
SceneFrame decodeCubePoses(Uint8List bytes) {
  final msg = pb.CubePoses.fromBuffer(bytes);
  return SceneFrame(
    frameSeq: msg.frameSeq.toInt(),
    stamp: _time(msg.stampSec, msg.stampNanosec),
    cubes: [
      for (final c in msg.cubes)
        SceneCube(
          id: c.cubeId,
          alive: c.alive,
          position: _vec(c.position, c.alive && c.hasPosition()),
          rotation: c.alive && c.hasRotation() && c.rotation.m.length == 9
              ? M3(List<double>.unmodifiable(c.rotation.m))
              : null,
          velocity: _vec(c.velocity, c.alive && c.hasVelocity()),
          eulerDeg: _vec(c.eulerDeg, c.alive && c.hasEulerDeg()),
          markerIds: List<int>.unmodifiable(c.markerIds),
          numCameras: c.numCameras,
          residualRms: c.residualRms,
          lastSeen: _time(c.lastSeenSec, c.lastSeenNanosec),
        ),
    ],
  );
}

DateTime _time(int sec, int nanosec) =>
    DateTime.fromMicrosecondsSinceEpoch(sec * 1000000 + nanosec ~/ 1000);
