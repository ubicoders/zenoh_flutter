// This is a generated file - do not edit.
//
// Generated from custom/MarkerDetections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// 3-vector. position: metres (RDF optical frame). euler_deg: degrees about
/// X, Y, Z in XYZ order, same frame.
class Vec3 extends $pb.GeneratedMessage {
  factory Vec3({
    $core.double? x,
    $core.double? y,
    $core.double? z,
  }) {
    final result = Vec3._();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (z != null) result.z = z;
    return result;
  }

  Vec3._();

  factory Vec3.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Vec3()..mergeFromBuffer(data, registry);
  factory Vec3.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Vec3()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Vec3',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: Vec3.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'x')
    ..aD(2, _omitFieldNames ? '' : 'y')
    ..aD(3, _omitFieldNames ? '' : 'z')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Vec3 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Vec3 copyWith(void Function(Vec3) updates) =>
      super.copyWith((message) => updates(message as Vec3)) as Vec3;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Vec3() / Vec3.new instead')
  static Vec3 create() => Vec3._();
  static $pb.GeneratedMessage $_createMessage() => Vec3._();
  @$core.override
  Vec3 createEmptyInstance() => Vec3._();
  @$core.pragma('dart2js:noInline')
  static Vec3 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Vec3>(Vec3.$_createMessage);
  static Vec3? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get z => $_getN(2);
  @$pb.TagNumber(3)
  set z($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZ() => $_has(2);
  @$pb.TagNumber(3)
  void clearZ() => $_clearField(3);
}

/// Orientation as a unit quaternion (canonical; gimbal-lock-free).
class Quat extends $pb.GeneratedMessage {
  factory Quat({
    $core.double? x,
    $core.double? y,
    $core.double? z,
    $core.double? w,
  }) {
    final result = Quat._();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (z != null) result.z = z;
    if (w != null) result.w = w;
    return result;
  }

  Quat._();

  factory Quat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Quat()..mergeFromBuffer(data, registry);
  factory Quat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Quat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Quat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: Quat.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'x')
    ..aD(2, _omitFieldNames ? '' : 'y')
    ..aD(3, _omitFieldNames ? '' : 'z')
    ..aD(4, _omitFieldNames ? '' : 'w')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Quat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Quat copyWith(void Function(Quat) updates) =>
      super.copyWith((message) => updates(message as Quat)) as Quat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Quat() / Quat.new instead')
  static Quat create() => Quat._();
  static $pb.GeneratedMessage $_createMessage() => Quat._();
  @$core.override
  Quat createEmptyInstance() => Quat._();
  @$core.pragma('dart2js:noInline')
  static Quat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Quat>(Quat.$_createMessage);
  static Quat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get z => $_getN(2);
  @$pb.TagNumber(3)
  set z($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZ() => $_has(2);
  @$pb.TagNumber(3)
  void clearZ() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get w => $_getN(3);
  @$pb.TagNumber(4)
  set w($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasW() => $_has(3);
  @$pb.TagNumber(4)
  void clearW() => $_clearField(4);
}

/// One detected marker.
class MarkerDetection extends $pb.GeneratedMessage {
  factory MarkerDetection({
    $core.int? id,
    $core.String? family,
    Vec3? position,
    Quat? orientation,
    Vec3? eulerDeg,
    $core.double? distance,
  }) {
    final result = MarkerDetection._();
    if (id != null) result.id = id;
    if (family != null) result.family = family;
    if (position != null) result.position = position;
    if (orientation != null) result.orientation = orientation;
    if (eulerDeg != null) result.eulerDeg = eulerDeg;
    if (distance != null) result.distance = distance;
    return result;
  }

  MarkerDetection._();

  factory MarkerDetection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerDetection()..mergeFromBuffer(data, registry);
  factory MarkerDetection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerDetection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkerDetection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: MarkerDetection.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'family')
    ..aOM<Vec3>(3, _omitFieldNames ? '' : 'position',
        subBuilder: Vec3.$_createMessage)
    ..aOM<Quat>(4, _omitFieldNames ? '' : 'orientation',
        subBuilder: Quat.$_createMessage)
    ..aOM<Vec3>(5, _omitFieldNames ? '' : 'eulerDeg',
        subBuilder: Vec3.$_createMessage)
    ..aD(6, _omitFieldNames ? '' : 'distance')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerDetection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerDetection copyWith(void Function(MarkerDetection) updates) =>
      super.copyWith((message) => updates(message as MarkerDetection))
          as MarkerDetection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkerDetection() / MarkerDetection.new instead')
  static MarkerDetection create() => MarkerDetection._();
  static $pb.GeneratedMessage $_createMessage() => MarkerDetection._();
  @$core.override
  MarkerDetection createEmptyInstance() => MarkerDetection._();
  @$core.pragma('dart2js:noInline')
  static MarkerDetection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarkerDetection>(
          MarkerDetection.$_createMessage);
  static MarkerDetection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get family => $_getSZ(1);
  @$pb.TagNumber(2)
  set family($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFamily() => $_has(1);
  @$pb.TagNumber(2)
  void clearFamily() => $_clearField(2);

  @$pb.TagNumber(3)
  Vec3 get position => $_getN(2);
  @$pb.TagNumber(3)
  set position(Vec3 value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearPosition() => $_clearField(3);
  @$pb.TagNumber(3)
  Vec3 ensurePosition() => $_ensure(2);

  @$pb.TagNumber(4)
  Quat get orientation => $_getN(3);
  @$pb.TagNumber(4)
  set orientation(Quat value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOrientation() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrientation() => $_clearField(4);
  @$pb.TagNumber(4)
  Quat ensureOrientation() => $_ensure(3);

  @$pb.TagNumber(5)
  Vec3 get eulerDeg => $_getN(4);
  @$pb.TagNumber(5)
  set eulerDeg(Vec3 value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasEulerDeg() => $_has(4);
  @$pb.TagNumber(5)
  void clearEulerDeg() => $_clearField(5);
  @$pb.TagNumber(5)
  Vec3 ensureEulerDeg() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.double get distance => $_getN(5);
  @$pb.TagNumber(6)
  set distance($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDistance() => $_has(5);
  @$pb.TagNumber(6)
  void clearDistance() => $_clearField(6);
}

/// All markers seen in one camera frame (the vector). Published every frame;
/// `markers` is empty when nothing was detected (heartbeat).
class MarkerDetections extends $pb.GeneratedMessage {
  factory MarkerDetections({
    $core.int? stampSec,
    $core.int? stampNanosec,
    $core.String? camera,
    $fixnum.Int64? frameSeq,
    $core.Iterable<MarkerDetection>? markers,
  }) {
    final result = MarkerDetections._();
    if (stampSec != null) result.stampSec = stampSec;
    if (stampNanosec != null) result.stampNanosec = stampNanosec;
    if (camera != null) result.camera = camera;
    if (frameSeq != null) result.frameSeq = frameSeq;
    if (markers != null) result.markers.addAll(markers);
    return result;
  }

  MarkerDetections._();

  factory MarkerDetections.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerDetections()..mergeFromBuffer(data, registry);
  factory MarkerDetections.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerDetections()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkerDetections',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'swarmbotix.custom'),
      createEmptyInstance: MarkerDetections.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'stampSec')
    ..aI(2, _omitFieldNames ? '' : 'stampNanosec',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'camera')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'frameSeq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<MarkerDetection>(5, _omitFieldNames ? '' : 'markers',
        subBuilder: MarkerDetection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerDetections clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerDetections copyWith(void Function(MarkerDetections) updates) =>
      super.copyWith((message) => updates(message as MarkerDetections))
          as MarkerDetections;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkerDetections() / MarkerDetections.new instead')
  static MarkerDetections create() => MarkerDetections._();
  static $pb.GeneratedMessage $_createMessage() => MarkerDetections._();
  @$core.override
  MarkerDetections createEmptyInstance() => MarkerDetections._();
  @$core.pragma('dart2js:noInline')
  static MarkerDetections getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarkerDetections>(
          MarkerDetections.$_createMessage);
  static MarkerDetections? _defaultInstance;

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
  $core.String get camera => $_getSZ(2);
  @$pb.TagNumber(3)
  set camera($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCamera() => $_has(2);
  @$pb.TagNumber(3)
  void clearCamera() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get frameSeq => $_getI64(3);
  @$pb.TagNumber(4)
  set frameSeq($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFrameSeq() => $_has(3);
  @$pb.TagNumber(4)
  void clearFrameSeq() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<MarkerDetection> get markers => $_getList(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
