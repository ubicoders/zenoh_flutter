// This is a generated file - do not edit.
//
// Generated from sensor_msgs/CompressedImage.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../std_msgs/Header.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CompressedImage extends $pb.GeneratedMessage {
  factory CompressedImage({
    $0.Header? header,
    $core.String? format,
    $core.List<$core.int>? data,
  }) {
    final result = CompressedImage._();
    if (header != null) result.header = header;
    if (format != null) result.format = format;
    if (data != null) result.data = data;
    return result;
  }

  CompressedImage._();

  factory CompressedImage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompressedImage()..mergeFromBuffer(data, registry);
  factory CompressedImage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompressedImage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompressedImage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sensor_msgs'),
      createEmptyInstance: CompressedImage.$_createMessage)
    ..aOM<$0.Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: $0.Header.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressedImage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressedImage copyWith(void Function(CompressedImage) updates) =>
      super.copyWith((message) => updates(message as CompressedImage))
          as CompressedImage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompressedImage() / CompressedImage.new instead')
  static CompressedImage create() => CompressedImage._();
  static $pb.GeneratedMessage $_createMessage() => CompressedImage._();
  @$core.override
  CompressedImage createEmptyInstance() => CompressedImage._();
  @$core.pragma('dart2js:noInline')
  static CompressedImage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompressedImage>(
          CompressedImage.$_createMessage);
  static CompressedImage? _defaultInstance;

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
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
