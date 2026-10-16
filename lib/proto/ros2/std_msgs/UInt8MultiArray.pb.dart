// This is a generated file - do not edit.
//
// Generated from std_msgs/UInt8MultiArray.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'MultiArrayLayout.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class UInt8MultiArray extends $pb.GeneratedMessage {
  factory UInt8MultiArray({
    $0.MultiArrayLayout? layout,
    $core.List<$core.int>? data,
  }) {
    final result = UInt8MultiArray._();
    if (layout != null) result.layout = layout;
    if (data != null) result.data = data;
    return result;
  }

  UInt8MultiArray._();

  factory UInt8MultiArray.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UInt8MultiArray()..mergeFromBuffer(data, registry);
  factory UInt8MultiArray.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UInt8MultiArray()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UInt8MultiArray',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'std_msgs'),
      createEmptyInstance: UInt8MultiArray.$_createMessage)
    ..aOM<$0.MultiArrayLayout>(1, _omitFieldNames ? '' : 'layout',
        subBuilder: $0.MultiArrayLayout.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UInt8MultiArray clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UInt8MultiArray copyWith(void Function(UInt8MultiArray) updates) =>
      super.copyWith((message) => updates(message as UInt8MultiArray))
          as UInt8MultiArray;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UInt8MultiArray() / UInt8MultiArray.new instead')
  static UInt8MultiArray create() => UInt8MultiArray._();
  static $pb.GeneratedMessage $_createMessage() => UInt8MultiArray._();
  @$core.override
  UInt8MultiArray createEmptyInstance() => UInt8MultiArray._();
  @$core.pragma('dart2js:noInline')
  static UInt8MultiArray getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UInt8MultiArray>(
          UInt8MultiArray.$_createMessage);
  static UInt8MultiArray? _defaultInstance;

  @$pb.TagNumber(1)
  $0.MultiArrayLayout get layout => $_getN(0);
  @$pb.TagNumber(1)
  set layout($0.MultiArrayLayout value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLayout() => $_has(0);
  @$pb.TagNumber(1)
  void clearLayout() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.MultiArrayLayout ensureLayout() => $_ensure(0);

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
