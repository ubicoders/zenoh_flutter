// This is a generated file - do not edit.
//
// Generated from std_msgs/String.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class String extends $pb.GeneratedMessage {
  factory String({
    $core.String? data,
  }) {
    final result = String._();
    if (data != null) result.data = data;
    return result;
  }

  String._();

  factory String.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      String()..mergeFromBuffer(data, registry);
  factory String.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      String()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'String',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'std_msgs'),
      createEmptyInstance: String.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'data')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  String clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  String copyWith(void Function(String) updates) =>
      super.copyWith((message) => updates(message as String)) as String;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use String() / String.new instead')
  static String create() => String._();
  static $pb.GeneratedMessage $_createMessage() => String._();
  @$core.override
  String createEmptyInstance() => String._();
  @$core.pragma('dart2js:noInline')
  static String getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<String>(String.$_createMessage);
  static String? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get data => $_getSZ(0);
  @$pb.TagNumber(1)
  set data($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
