/// scene_math: the small 3D toolkit behind the cube scene.
///
/// World frame is the tracker's RDF frame (metres): X right, Y down, Z
/// forward, with the ceiling cameras at Z about -2 and the cubes on the floor
/// near Z = 0. The scene is viewed with -Z as "up", the way `ips_viz` logs it
/// to rerun (RFD view coordinates), so the floor grid is the X-Y plane and the
/// cameras hang above it.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Immutable 3-vector.
class V3 {
  const V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = V3(0, 0, 0);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double s) => V3(x * s, y * s, z * s);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;

  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(dot(this));

  V3 get normalized {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  @override
  String toString() =>
      '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// Row-major 3x3 matrix, `[r00 r01 r02 r10 r11 r12 r20 r21 r22]`, the wire
/// layout of `custom/CubePoses.Mat3`.
class M3 {
  const M3(this.m);

  final List<double> m;

  static const identity = M3([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  /// `this * v`.
  V3 apply(V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z,
    m[3] * v.x + m[4] * v.y + m[5] * v.z,
    m[6] * v.x + m[7] * v.y + m[8] * v.z,
  );

  /// Column [c]: the c-th body axis expressed in the parent frame.
  V3 col(int c) => V3(m[c], m[3 + c], m[6 + c]);
}

/// An orbit camera: looks at [target] from [distance] metres away, turned
/// by [yaw] about the vertical and tilted by [pitch] above the floor.
///
/// Notifies on every change so a `CustomPaint` can repaint from it.
class OrbitCamera extends ChangeNotifier {
  OrbitCamera({
    V3 target = V3.zero,
    double yaw = 0,
    double pitch = 0.62,
    double distance = 7.5,
    this.fovDeg = 50,
  }) : _target = target,
       _yaw = yaw,
       _pitch = pitch,
       _distance = distance;

  /// "Up" in world coordinates: the cameras are at negative Z, above the
  /// floor.
  static const V3 up = V3(0, 0, -1);

  static const double minDistance = 0.3;
  static const double maxDistance = 40;
  static const double maxPitch = math.pi / 2 - 0.02;
  static const double minPitch = 0.03;

  final double fovDeg;

  V3 _target;
  double _yaw;
  double _pitch;
  double _distance;

  V3 get target => _target;
  double get yaw => _yaw;
  double get pitch => _pitch;
  double get distance => _distance;

  set target(V3 v) {
    _target = v;
    notifyListeners();
  }

  /// Rotates the view by screen deltas (radians per logical pixel).
  void orbit(double dx, double dy) {
    _yaw -= dx * 0.005;
    _pitch = (_pitch + dy * 0.005).clamp(minPitch, maxPitch);
    notifyListeners();
  }

  void zoomBy(double factor) {
    _distance = (_distance / factor).clamp(minDistance, maxDistance);
    notifyListeners();
  }

  /// Slides [target] in the view plane by a screen delta.
  void pan(double dx, double dy, Size viewport) {
    final f = focal(viewport);
    final scale = _distance / f;
    _target = _target - right * (dx * scale) + viewUp * (dy * scale);
    notifyListeners();
  }

  void set({V3? target, double? yaw, double? pitch, double? distance}) {
    _target = target ?? _target;
    _yaw = yaw ?? _yaw;
    _pitch = (pitch ?? _pitch).clamp(minPitch, maxPitch);
    _distance = (distance ?? _distance).clamp(minDistance, maxDistance);
    notifyListeners();
  }

  /// Eye position in world coordinates. Yaw 0 looks along -Y from the +Y
  /// side; pitch raises the eye toward [up].
  V3 get eye {
    final c = math.cos(_pitch);
    final horizontal = V3(math.sin(_yaw) * c, math.cos(_yaw) * c, 0);
    return _target + (horizontal + up * math.sin(_pitch)) * _distance;
  }

  V3 get forward => (_target - eye).normalized;

  V3 get right => forward.cross(up).normalized;

  V3 get viewUp => right.cross(forward);

  /// Focal length in logical pixels for a viewport. [fovDeg] spans the
  /// shorter side, so a portrait phone shows as much width as landscape
  /// shows height.
  double focal(Size viewport) =>
      viewport.shortestSide / (2 * math.tan(fovDeg * math.pi / 360));

  /// Pixel size of one metre at the target distance (for sizing dots).
  double pixelsPerMetreAtTarget(Size viewport) => focal(viewport) / _distance;
}

/// One frame's projection: the camera basis frozen for a paint.
class Projector {
  Projector(OrbitCamera camera, this.viewport)
    : eye = camera.eye,
      forward = camera.forward,
      right = camera.right,
      up = camera.viewUp,
      focal = camera.focal(viewport),
      centre = Offset(viewport.width / 2, viewport.height / 2);

  static const double near = 0.05;

  final Size viewport;
  final V3 eye;
  final V3 forward;
  final V3 right;
  final V3 up;
  final double focal;
  final Offset centre;

  /// Camera-space coordinates: x right, y up, z into the scene.
  V3 toCamera(V3 p) {
    final d = p - eye;
    return V3(d.dot(right), d.dot(up), d.dot(forward));
  }

  Offset _toScreen(V3 c) =>
      Offset(centre.dx + focal * c.x / c.z, centre.dy - focal * c.y / c.z);

  /// Screen position of a world point, or null when behind the camera.
  Offset? project(V3 p) {
    final c = toCamera(p);
    return c.z <= near ? null : _toScreen(c);
  }

  /// Depth of a world point along the view axis (metres), for sorting.
  double depth(V3 p) => (p - eye).dot(forward);

  /// A world segment clipped to the near plane and projected, or null when
  /// it is entirely behind the camera.
  (Offset, Offset)? projectSegment(V3 a, V3 b) {
    var ca = toCamera(a);
    var cb = toCamera(b);
    if (ca.z <= near && cb.z <= near) return null;
    if (ca.z <= near || cb.z <= near) {
      final t = (near - ca.z) / (cb.z - ca.z);
      final hit = ca + (cb - ca) * t;
      if (ca.z <= near) {
        ca = hit;
      } else {
        cb = hit;
      }
    }
    return (_toScreen(ca), _toScreen(cb));
  }
}
