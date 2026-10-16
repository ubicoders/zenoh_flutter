// This is a generated file - do not edit.
//
// Generated from custom/CubePoses.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'MarkerDetections.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// 3x3 row-major rotation matrix, 9 doubles: [r00 r01 r02 r10 r11 r12 r20 r21 r22].
class Mat3 extends $pb.GeneratedMessage {
  factory Mat3({
    $core.Iterable<$core.double>? m,
  }) {
    final result = Mat3._();
    if (m != null) result.m.addAll(m);
    return result;
  }

  Mat3._();

  factory Mat3.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Mat3()..mergeFromBuffer(data, registry);
  factory Mat3.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Mat3()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mat3',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: Mat3.$_createMessage)
    ..p<$core.double>(1, _omitFieldNames ? '' : 'm', $pb.PbFieldType.KD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mat3 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mat3 copyWith(void Function(Mat3) updates) =>
      super.copyWith((message) => updates(message as Mat3)) as Mat3;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Mat3() / Mat3.new instead')
  static Mat3 create() => Mat3._();
  static $pb.GeneratedMessage $_createMessage() => Mat3._();
  @$core.override
  Mat3 createEmptyInstance() => Mat3._();
  @$core.pragma('dart2js:noInline')
  static Mat3 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Mat3>(Mat3.$_createMessage);
  static Mat3? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.double> get m => $_getList(0);
}

/// One fused cube pose in the world frame, with a liveness heartbeat.
///
/// A cube enters the roster on its first successful fuse and is then reported on
/// every frame thereafter. `alive` is recomputed each frame from how long ago the
/// cube was last fused (the tracker's alive window, default 2 s).
///
/// alive=true: fused within the window. position/rotation/euler/orientation carry
/// a usable pose (this frame's fit, or the last good one carried through a brief
/// gap), and last_seen_* mark when it was last fused. `velocity` is the cube's
/// world-frame linear velocity, but only when the tracker runs the `kf` filter
/// (the other smoothers carry no velocity state and leave it unset).
///
/// alive=false: not fused within the window, treat the cube as gone, do NOT use
/// it. The pose fields (position/rotation/euler/orientation/velocity) are cleared
/// (unset); only cube_id, alive and last_seen_* are meaningful.
class CubePose extends $pb.GeneratedMessage {
  factory CubePose({
    $core.int? cubeId,
    $0.Vec3? position,
    Mat3? rotation,
    $0.Vec3? eulerDeg,
    $0.Quat? orientation,
    $core.Iterable<$core.int>? markerIds,
    $core.int? numCameras,
    $core.double? residualRms,
    $core.bool? alive,
    $core.int? lastSeenSec,
    $core.int? lastSeenNanosec,
    $0.Vec3? velocity,
  }) {
    final result = CubePose._();
    if (cubeId != null) result.cubeId = cubeId;
    if (position != null) result.position = position;
    if (rotation != null) result.rotation = rotation;
    if (eulerDeg != null) result.eulerDeg = eulerDeg;
    if (orientation != null) result.orientation = orientation;
    if (markerIds != null) result.markerIds.addAll(markerIds);
    if (numCameras != null) result.numCameras = numCameras;
    if (residualRms != null) result.residualRms = residualRms;
    if (alive != null) result.alive = alive;
    if (lastSeenSec != null) result.lastSeenSec = lastSeenSec;
    if (lastSeenNanosec != null) result.lastSeenNanosec = lastSeenNanosec;
    if (velocity != null) result.velocity = velocity;
    return result;
  }

  CubePose._();

  factory CubePose.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CubePose()..mergeFromBuffer(data, registry);
  factory CubePose.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CubePose()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CubePose',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: CubePose.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'cubeId', fieldType: $pb.PbFieldType.OU3)
    ..aOM<$0.Vec3>(2, _omitFieldNames ? '' : 'position',
        subBuilder: $0.Vec3.$_createMessage)
    ..aOM<Mat3>(3, _omitFieldNames ? '' : 'rotation',
        subBuilder: Mat3.$_createMessage)
    ..aOM<$0.Vec3>(4, _omitFieldNames ? '' : 'eulerDeg',
        subBuilder: $0.Vec3.$_createMessage)
    ..aOM<$0.Quat>(5, _omitFieldNames ? '' : 'orientation',
        subBuilder: $0.Quat.$_createMessage)
    ..p<$core.int>(6, _omitFieldNames ? '' : 'markerIds', $pb.PbFieldType.K3)
    ..aI(7, _omitFieldNames ? '' : 'numCameras', fieldType: $pb.PbFieldType.OU3)
    ..aD(8, _omitFieldNames ? '' : 'residualRms')
    ..aOB(9, _omitFieldNames ? '' : 'alive')
    ..aI(10, _omitFieldNames ? '' : 'lastSeenSec')
    ..aI(11, _omitFieldNames ? '' : 'lastSeenNanosec',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<$0.Vec3>(12, _omitFieldNames ? '' : 'velocity',
        subBuilder: $0.Vec3.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CubePose clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CubePose copyWith(void Function(CubePose) updates) =>
      super.copyWith((message) => updates(message as CubePose)) as CubePose;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CubePose() / CubePose.new instead')
  static CubePose create() => CubePose._();
  static $pb.GeneratedMessage $_createMessage() => CubePose._();
  @$core.override
  CubePose createEmptyInstance() => CubePose._();
  @$core.pragma('dart2js:noInline')
  static CubePose getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CubePose>(CubePose.$_createMessage);
  static CubePose? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cubeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set cubeId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCubeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCubeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Vec3 get position => $_getN(1);
  @$pb.TagNumber(2)
  set position($0.Vec3 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Vec3 ensurePosition() => $_ensure(1);

  @$pb.TagNumber(3)
  Mat3 get rotation => $_getN(2);
  @$pb.TagNumber(3)
  set rotation(Mat3 value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRotation() => $_has(2);
  @$pb.TagNumber(3)
  void clearRotation() => $_clearField(3);
  @$pb.TagNumber(3)
  Mat3 ensureRotation() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.Vec3 get eulerDeg => $_getN(3);
  @$pb.TagNumber(4)
  set eulerDeg($0.Vec3 value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEulerDeg() => $_has(3);
  @$pb.TagNumber(4)
  void clearEulerDeg() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Vec3 ensureEulerDeg() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.Quat get orientation => $_getN(4);
  @$pb.TagNumber(5)
  set orientation($0.Quat value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOrientation() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrientation() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Quat ensureOrientation() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.int> get markerIds => $_getList(5);

  @$pb.TagNumber(7)
  $core.int get numCameras => $_getIZ(6);
  @$pb.TagNumber(7)
  set numCameras($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNumCameras() => $_has(6);
  @$pb.TagNumber(7)
  void clearNumCameras() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get residualRms => $_getN(7);
  @$pb.TagNumber(8)
  set residualRms($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasResidualRms() => $_has(7);
  @$pb.TagNumber(8)
  void clearResidualRms() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get alive => $_getBF(8);
  @$pb.TagNumber(9)
  set alive($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAlive() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlive() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get lastSeenSec => $_getIZ(9);
  @$pb.TagNumber(10)
  set lastSeenSec($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLastSeenSec() => $_has(9);
  @$pb.TagNumber(10)
  void clearLastSeenSec() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get lastSeenNanosec => $_getIZ(10);
  @$pb.TagNumber(11)
  set lastSeenNanosec($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLastSeenNanosec() => $_has(10);
  @$pb.TagNumber(11)
  void clearLastSeenNanosec() => $_clearField(11);

  @$pb.TagNumber(12)
  $0.Vec3 get velocity => $_getN(11);
  @$pb.TagNumber(12)
  set velocity($0.Vec3 value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasVelocity() => $_has(11);
  @$pb.TagNumber(12)
  void clearVelocity() => $_clearField(12);
  @$pb.TagNumber(12)
  $0.Vec3 ensureVelocity() => $_ensure(11);
}

/// All cubes resolved in one frame. Published every frame. `cubes` is the roster
/// of every cube seen at least once since start: freshly fused cubes ride with
/// alive=true, cubes gone past the alive window stay in the roster with alive=false
/// (an explicit "stopped" heartbeat) so subscribers can tell stale from never-seen.
/// Empty only before the first cube is ever detected.
class CubePoses extends $pb.GeneratedMessage {
  factory CubePoses({
    $core.int? stampSec,
    $core.int? stampNanosec,
    $fixnum.Int64? frameSeq,
    $core.Iterable<CubePose>? cubes,
  }) {
    final result = CubePoses._();
    if (stampSec != null) result.stampSec = stampSec;
    if (stampNanosec != null) result.stampNanosec = stampNanosec;
    if (frameSeq != null) result.frameSeq = frameSeq;
    if (cubes != null) result.cubes.addAll(cubes);
    return result;
  }

  CubePoses._();

  factory CubePoses.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CubePoses()..mergeFromBuffer(data, registry);
  factory CubePoses.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CubePoses()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CubePoses',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: CubePoses.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'stampSec')
    ..aI(2, _omitFieldNames ? '' : 'stampNanosec',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'frameSeq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<CubePose>(4, _omitFieldNames ? '' : 'cubes',
        subBuilder: CubePose.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CubePoses clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CubePoses copyWith(void Function(CubePoses) updates) =>
      super.copyWith((message) => updates(message as CubePoses)) as CubePoses;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CubePoses() / CubePoses.new instead')
  static CubePoses create() => CubePoses._();
  static $pb.GeneratedMessage $_createMessage() => CubePoses._();
  @$core.override
  CubePoses createEmptyInstance() => CubePoses._();
  @$core.pragma('dart2js:noInline')
  static CubePoses getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CubePoses>(CubePoses.$_createMessage);
  static CubePoses? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get stampSec => $_getIZ(0);
  @$pb.TagNumber(1)
  set stampSec($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStampSec() => $_has(0);
  @$pb.TagNumber(1)
  void clearStampSec() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get stampNanosec => $_getIZ(1);
  @$pb.TagNumber(2)
  set stampNanosec($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStampNanosec() => $_has(1);
  @$pb.TagNumber(2)
  void clearStampNanosec() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get frameSeq => $_getI64(2);
  @$pb.TagNumber(3)
  set frameSeq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFrameSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearFrameSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<CubePose> get cubes => $_getList(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
