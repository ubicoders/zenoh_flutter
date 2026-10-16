// This is a generated file - do not edit.
//
// Generated from std_msgs/MultiArrayLayout.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'MultiArrayDimension.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class MultiArrayLayout extends $pb.GeneratedMessage {
  factory MultiArrayLayout({
    $core.Iterable<$0.MultiArrayDimension>? dim,
    $core.int? dataOffset,
  }) {
    final result = MultiArrayLayout._();
    if (dim != null) result.dim.addAll(dim);
    if (dataOffset != null) result.dataOffset = dataOffset;
    return result;
  }

  MultiArrayLayout._();

  factory MultiArrayLayout.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MultiArrayLayout()..mergeFromBuffer(data, registry);
  factory MultiArrayLayout.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MultiArrayLayout()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MultiArrayLayout',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'std_msgs'),
      createEmptyInstance: MultiArrayLayout.$_createMessage)
    ..pPM<$0.MultiArrayDimension>(1, _omitFieldNames ? '' : 'dim',
        subBuilder: $0.MultiArrayDimension.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'dataOffset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiArrayLayout clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MultiArrayLayout copyWith(void Function(MultiArrayLayout) updates) =>
      super.copyWith((message) => updates(message as MultiArrayLayout))
          as MultiArrayLayout;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MultiArrayLayout() / MultiArrayLayout.new instead')
  static MultiArrayLayout create() => MultiArrayLayout._();
  static $pb.GeneratedMessage $_createMessage() => MultiArrayLayout._();
  @$core.override
  MultiArrayLayout createEmptyInstance() => MultiArrayLayout._();
  @$core.pragma('dart2js:noInline')
  static MultiArrayLayout getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiArrayLayout>(
          MultiArrayLayout.$_createMessage);
  static MultiArrayLayout? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.MultiArrayDimension> get dim => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get dataOffset => $_getIZ(1);
  @$pb.TagNumber(2)
  set dataOffset($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDataOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataOffset() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
