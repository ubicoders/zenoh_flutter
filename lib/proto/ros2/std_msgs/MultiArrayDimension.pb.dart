// This is a generated file - do not edit.
//
// Generated from std_msgs/MultiArrayDimension.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class MultiArrayDimension extends $pb.GeneratedMessage {
  factory MultiArrayDimension({
    $core.String? label,
    $core.int? size,
    $core.int? stride,
  }) {
    final result = MultiArrayDimension._();
    if (label != null) result.label = label;
    if (size != null) result.size = size;
    if (stride != null) result.stride = stride;
    return result;
  }

  MultiArrayDimension._();

  factory MultiArrayDimension.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MultiArrayDimension()..mergeFromBuffer(data, registry);
  factory MultiArrayDimension.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MultiArrayDimension()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MultiArrayDimension',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'std_msgs'),
      createEmptyInstance: MultiArrayDimension.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aI(2, _omitFieldNames ? '' : 'size', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'stride', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiArrayDimension clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiArrayDimension copyWith(void Function(MultiArrayDimension) updates) =>
      super.copyWith((message) => updates(message as MultiArrayDimension))
          as MultiArrayDimension;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use MultiArrayDimension() / MultiArrayDimension.new instead')
  static MultiArrayDimension create() => MultiArrayDimension._();
  static $pb.GeneratedMessage $_createMessage() => MultiArrayDimension._();
  @$core.override
  MultiArrayDimension createEmptyInstance() => MultiArrayDimension._();
  @$core.pragma('dart2js:noInline')
  static MultiArrayDimension getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MultiArrayDimension>(
          MultiArrayDimension.$_createMessage);
  static MultiArrayDimension? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get size => $_getIZ(1);
  @$pb.TagNumber(2)
  set size($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get stride => $_getIZ(2);
  @$pb.TagNumber(3)
  set stride($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStride() => $_has(2);
  @$pb.TagNumber(3)
  void clearStride() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
