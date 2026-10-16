// This is a generated file - do not edit.
//
// Generated from std_msgs/Header.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../builtin_interfaces/Time.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Header extends $pb.GeneratedMessage {
  factory Header({
    $0.Time? stamp,
    $core.String? frameId,
  }) {
    final result = Header._();
    if (stamp != null) result.stamp = stamp;
    if (frameId != null) result.frameId = frameId;
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
      package: const $pb.PackageName(_omitMessageNames ? '' : 'std_msgs'),
      createEmptyInstance: Header.$_createMessage)
    ..aOM<$0.Time>(1, _omitFieldNames ? '' : 'stamp',
        subBuilder: $0.Time.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'frameId')
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

  /// Two-integer timestamp that is expressed as seconds and nanoseconds.
  @$pb.TagNumber(1)
  $0.Time get stamp => $_getN(0);
  @$pb.TagNumber(1)
  set stamp($0.Time value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearStamp() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Time ensureStamp() => $_ensure(0);

  /// Transform frame with which this data is associated.
  @$pb.TagNumber(2)
  $core.String get frameId => $_getSZ(1);
  @$pb.TagNumber(2)
  set frameId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFrameId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrameId() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
