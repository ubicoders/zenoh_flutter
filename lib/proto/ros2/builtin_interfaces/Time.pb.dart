// This is a generated file - do not edit.
//
// Generated from builtin_interfaces/Time.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Time extends $pb.GeneratedMessage {
  factory Time({
    $core.int? sec,
    $core.int? nanosec,
  }) {
    final result = Time._();
    if (sec != null) result.sec = sec;
    if (nanosec != null) result.nanosec = nanosec;
    return result;
  }

  Time._();

  factory Time.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Time()..mergeFromBuffer(data, registry);
  factory Time.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Time()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Time',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'builtin_interfaces'),
      createEmptyInstance: Time.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'sec')
    ..aI(2, _omitFieldNames ? '' : 'nanosec', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Time clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Time copyWith(void Function(Time) updates) =>
      super.copyWith((message) => updates(message as Time)) as Time;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Time() / Time.new instead')
  static Time create() => Time._();
  static $pb.GeneratedMessage $_createMessage() => Time._();
  @$core.override
  Time createEmptyInstance() => Time._();
  @$core.pragma('dart2js:noInline')
  static Time getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Time>(Time.$_createMessage);
  static Time? _defaultInstance;

  /// Seconds since UNIX epoch (signed so pre-1970 values are representable).
  @$pb.TagNumber(1)
  $core.int get sec => $_getIZ(0);
  @$pb.TagNumber(1)
  set sec($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSec() => $_has(0);
  @$pb.TagNumber(1)
  void clearSec() => $_clearField(1);

  /// Nanoseconds within the second, [0, 1e9).
  @$pb.TagNumber(2)
  $core.int get nanosec => $_getIZ(1);
  @$pb.TagNumber(2)
  set nanosec($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNanosec() => $_has(1);
  @$pb.TagNumber(2)
  void clearNanosec() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
