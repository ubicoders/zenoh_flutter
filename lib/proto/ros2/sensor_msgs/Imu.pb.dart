// This is a generated file - do not edit.
//
// Generated from sensor_msgs/Imu.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../geometry_msgs/Quaternion.pb.dart' as $1;
import '../geometry_msgs/Vector3.pb.dart' as $2;
import '../std_msgs/Header.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Imu extends $pb.GeneratedMessage {
  factory Imu({
    $0.Header? header,
    $1.Quaternion? orientation,
    $core.Iterable<$core.double>? orientationCovariance,
    $2.Vector3? angularVelocity,
    $core.Iterable<$core.double>? angularVelocityCovariance,
    $2.Vector3? linearAcceleration,
    $core.Iterable<$core.double>? linearAccelerationCovariance,
  }) {
    final result = Imu._();
    if (header != null) result.header = header;
    if (orientation != null) result.orientation = orientation;
    if (orientationCovariance != null)
      result.orientationCovariance.addAll(orientationCovariance);
    if (angularVelocity != null) result.angularVelocity = angularVelocity;
    if (angularVelocityCovariance != null)
      result.angularVelocityCovariance.addAll(angularVelocityCovariance);
    if (linearAcceleration != null)
      result.linearAcceleration = linearAcceleration;
    if (linearAccelerationCovariance != null)
      result.linearAccelerationCovariance.addAll(linearAccelerationCovariance);
    return result;
  }

  Imu._();

  factory Imu.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Imu()..mergeFromBuffer(data, registry);
  factory Imu.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Imu()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Imu',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sensor_msgs'),
      createEmptyInstance: Imu.$_createMessage)
    ..aOM<$0.Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: $0.Header.$_createMessage)
    ..aOM<$1.Quaternion>(2, _omitFieldNames ? '' : 'orientation',
        subBuilder: $1.Quaternion.$_createMessage)
    ..p<$core.double>(
        3, _omitFieldNames ? '' : 'orientationCovariance', $pb.PbFieldType.KD)
    ..aOM<$2.Vector3>(4, _omitFieldNames ? '' : 'angularVelocity',
        subBuilder: $2.Vector3.$_createMessage)
    ..p<$core.double>(5, _omitFieldNames ? '' : 'angularVelocityCovariance',
        $pb.PbFieldType.KD)
    ..aOM<$2.Vector3>(6, _omitFieldNames ? '' : 'linearAcceleration',
        subBuilder: $2.Vector3.$_createMessage)
    ..p<$core.double>(7, _omitFieldNames ? '' : 'linearAccelerationCovariance',
        $pb.PbFieldType.KD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Imu clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Imu copyWith(void Function(Imu) updates) =>
      super.copyWith((message) => updates(message as Imu)) as Imu;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Imu() / Imu.new instead')
  static Imu create() => Imu._();
  static $pb.GeneratedMessage $_createMessage() => Imu._();
  @$core.override
  Imu createEmptyInstance() => Imu._();
  @$core.pragma('dart2js:noInline')
  static Imu getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Imu>(Imu.$_createMessage);
  static Imu? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header($0.Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.Quaternion get orientation => $_getN(1);
  @$pb.TagNumber(2)
  set orientation($1.Quaternion value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOrientation() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrientation() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Quaternion ensureOrientation() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.double> get orientationCovariance => $_getList(2);

  @$pb.TagNumber(4)
  $2.Vector3 get angularVelocity => $_getN(3);
  @$pb.TagNumber(4)
  set angularVelocity($2.Vector3 value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAngularVelocity() => $_has(3);
  @$pb.TagNumber(4)
  void clearAngularVelocity() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Vector3 ensureAngularVelocity() => $_ensure(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.double> get angularVelocityCovariance => $_getList(4);

  @$pb.TagNumber(6)
  $2.Vector3 get linearAcceleration => $_getN(5);
  @$pb.TagNumber(6)
  set linearAcceleration($2.Vector3 value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLinearAcceleration() => $_has(5);
  @$pb.TagNumber(6)
  void clearLinearAcceleration() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Vector3 ensureLinearAcceleration() => $_ensure(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.double> get linearAccelerationCovariance => $_getList(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
