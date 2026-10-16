/// scene_history: what a frame alone does not tell — where a stale cube was
/// last seen (so it can be drawn dimmed in place) and the recent path of
/// each cube (the trail).
library;

import 'package:zenoh_flutter/scene/scene_math.dart';
import 'package:zenoh_flutter/scene/scene_model.dart';

class SceneHistory {
  SceneHistory({this.maxTrail = 150});

  final int maxTrail;

  final Map<int, SceneCube> _lastAlive = {};
  final Map<int, List<V3>> _trails = {};

  /// Trails per cube id, oldest point first. The lists are replaced, never
  /// mutated, after [apply], so a painter can compare them by identity.
  Map<int, List<V3>> get trails => _trails;

  /// Folds [frame] in and returns the cubes to draw: alive cubes as they
  /// are, stale cubes at their last alive pose.
  List<SceneCube> apply(SceneFrame frame) {
    final out = <SceneCube>[];
    for (final c in frame.cubes) {
      if (c.alive && c.position != null) {
        _lastAlive[c.id] = c;
        final trail = [...?_trails[c.id], c.position!];
        if (trail.length > maxTrail) {
          trail.removeRange(0, trail.length - maxTrail);
        }
        _trails[c.id] = trail;
        out.add(c);
        continue;
      }
      final last = _lastAlive[c.id];
      out.add(
        SceneCube(
          id: c.id,
          alive: false,
          position: last?.position,
          rotation: last?.rotation,
          velocity: null,
          eulerDeg: last?.eulerDeg,
          markerIds: c.markerIds,
          numCameras: c.numCameras,
          residualRms: c.residualRms,
          lastSeen: c.lastSeen,
        ),
      );
    }
    return out;
  }

  void clear() {
    _lastAlive.clear();
    _trails.clear();
  }
}
