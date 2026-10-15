// This is a generated file - do not edit.
//
// Generated from demo.proto.

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

/// Metadata carried as field 1 of every message. Nanoseconds since the UNIX
/// epoch so coarser units are exact integer divides (ms = ns / 1'000'000).
class Header extends $pb.GeneratedMessage {
  factory Header({
    $fixnum.Int64? timestampNs,
    $fixnum.Int64? seq,
  }) {
    final result = Header._();
    if (timestampNs != null) result.timestampNs = timestampNs;
    if (seq != null) result.seq = seq;
    return result;
  }

  Header._();

  factory Header.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Header()..mergeFromBuffer(data, registry);
  factory Header.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Header()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Header',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'zenoh_demo'),
      createEmptyInstance: Header.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'timestampNs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header copyWith(void Function(Header) updates) =>
      super.copyWith((message) => updates(message as Header)) as Header;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Header() / Header.new instead')
  static Header create() => Header._();
  static $pb.GeneratedMessage $_createMessage() => Header._();
  @$core.override
  Header createEmptyInstance() => Header._();
  @$core.pragma('dart2js:noInline')
  static Header getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Header>(Header.$_createMessage);
  static Header? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampNs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampNs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampNs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampNs() => $_clearField(1);

  /// Monotonically increasing per-publisher sequence number. Gaps mean
  /// dropped samples.
  @$pb.TagNumber(2)
  $fixnum.Int64 get seq => $_getI64(1);
  @$pb.TagNumber(2)
  set seq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);
}

class Vector3 extends $pb.GeneratedMessage {
  factory Vector3({
    $core.double? x,
    $core.double? y,
    $core.double? z,
  }) {
    final result = Vector3._();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (z != null) result.z = z;
    return result;
  }

  Vector3._();

  factory Vector3.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Vector3()..mergeFromBuffer(data, registry);
  factory Vector3.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Vector3()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Vector3',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'zenoh_demo'),
      createEmptyInstance: Vector3.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'x')
    ..aD(2, _omitFieldNames ? '' : 'y')
    ..aD(3, _omitFieldNames ? '' : 'z')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Vector3 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Vector3 copyWith(void Function(Vector3) updates) =>
      super.copyWith((message) => updates(message as Vector3)) as Vector3;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Vector3() / Vector3.new instead')
  static Vector3 create() => Vector3._();
  static $pb.GeneratedMessage $_createMessage() => Vector3._();
  @$core.override
  Vector3 createEmptyInstance() => Vector3._();
  @$core.pragma('dart2js:noInline')
  static Vector3 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Vector3>(Vector3.$_createMessage);
  static Vector3? _defaultInstance;

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

/// Inertial measurement unit sample (test/imu, 50 Hz).
class Imu extends $pb.GeneratedMessage {
  factory Imu({
    Header? header,
    Vector3? accel,
    Vector3? gyro,
    $core.double? temp,
  }) {
    final result = Imu._();
    if (header != null) result.header = header;
    if (accel != null) result.accel = accel;
    if (gyro != null) result.gyro = gyro;
    if (temp != null) result.temp = temp;
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
      package: const $pb.PackageName(_omitMessageNames ? '' : 'zenoh_demo'),
      createEmptyInstance: Imu.$_createMessage)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: Header.$_createMessage)
    ..aOM<Vector3>(2, _omitFieldNames ? '' : 'accel',
        subBuilder: Vector3.$_createMessage)
    ..aOM<Vector3>(3, _omitFieldNames ? '' : 'gyro',
        subBuilder: Vector3.$_createMessage)
    ..aD(4, _omitFieldNames ? '' : 'temp')
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
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  Vector3 get accel => $_getN(1);
  @$pb.TagNumber(2)
  set accel(Vector3 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAccel() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccel() => $_clearField(2);
  @$pb.TagNumber(2)
  Vector3 ensureAccel() => $_ensure(1);

  @$pb.TagNumber(3)
  Vector3 get gyro => $_getN(2);
  @$pb.TagNumber(3)
  set gyro(Vector3 value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGyro() => $_has(2);
  @$pb.TagNumber(3)
  void clearGyro() => $_clearField(3);
  @$pb.TagNumber(3)
  Vector3 ensureGyro() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.double get temp => $_getN(3);
  @$pb.TagNumber(4)
  set temp($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTemp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTemp() => $_clearField(4);
}

/// One encoded camera frame (test/cam, 10 Hz).
class Image extends $pb.GeneratedMessage {
  factory Image({
    Header? header,
    $core.int? width,
    $core.int? height,
    $core.String? format,
    $core.List<$core.int>? data,
  }) {
    final result = Image._();
    if (header != null) result.header = header;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (format != null) result.format = format;
    if (data != null) result.data = data;
    return result;
  }

  Image._();

  factory Image.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromBuffer(data, registry);
  factory Image.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Image',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'zenoh_demo'),
      createEmptyInstance: Image.$_createMessage)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: Header.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'format')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image copyWith(void Function(Image) updates) =>
      super.copyWith((message) => updates(message as Image)) as Image;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Image() / Image.new instead')
  static Image create() => Image._();
  static $pb.GeneratedMessage $_createMessage() => Image._();
  @$core.override
  Image createEmptyInstance() => Image._();
  @$core.pragma('dart2js:noInline')
  static Image getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Image>(Image.$_createMessage);
  static Image? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => $_clearField(3);

  /// Container of `data`: "jpeg" or "png".
  @$pb.TagNumber(4)
  $core.String get format => $_getSZ(3);
  @$pb.TagNumber(4)
  set format($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get data => $_getN(4);
  @$pb.TagNumber(5)
  set data($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasData() => $_has(4);
  @$pb.TagNumber(5)
  void clearData() => $_clearField(5);
}

/// Opaque bytes (test/raw, 5 Hz).
class Raw extends $pb.GeneratedMessage {
  factory Raw({
    Header? header,
    $core.List<$core.int>? data,
  }) {
    final result = Raw._();
    if (header != null) result.header = header;
    if (data != null) result.data = data;
    return result;
  }

  Raw._();

  factory Raw.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Raw()..mergeFromBuffer(data, registry);
  factory Raw.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Raw()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Raw',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'zenoh_demo'),
      createEmptyInstance: Raw.$_createMessage)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: Header.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Raw clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Raw copyWith(void Function(Raw) updates) =>
      super.copyWith((message) => updates(message as Raw)) as Raw;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Raw() / Raw.new instead')
  static Raw create() => Raw._();
  static $pb.GeneratedMessage $_createMessage() => Raw._();
  @$core.override
  Raw createEmptyInstance() => Raw._();
  @$core.pragma('dart2js:noInline')
  static Raw getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Raw>(Raw.$_createMessage);
  static Raw? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
