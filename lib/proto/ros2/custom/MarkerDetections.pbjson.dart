// This is a generated file - do not edit.
//
// Generated from custom/MarkerDetections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use vec3Descriptor instead')
const Vec3$json = {
  '1': 'Vec3',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 1, '10': 'y'},
    {'1': 'z', '3': 3, '4': 1, '5': 1, '10': 'z'},
  ],
};

/// Descriptor for `Vec3`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vec3Descriptor = $convert.base64Decode(
    'CgRWZWMzEgwKAXgYASABKAFSAXgSDAoBeRgCIAEoAVIBeRIMCgF6GAMgASgBUgF6');

@$core.Deprecated('Use quatDescriptor instead')
const Quat$json = {
  '1': 'Quat',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 1, '10': 'y'},
    {'1': 'z', '3': 3, '4': 1, '5': 1, '10': 'z'},
    {'1': 'w', '3': 4, '4': 1, '5': 1, '10': 'w'},
  ],
};

/// Descriptor for `Quat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quatDescriptor = $convert.base64Decode(
    'CgRRdWF0EgwKAXgYASABKAFSAXgSDAoBeRgCIAEoAVIBeRIMCgF6GAMgASgBUgF6EgwKAXcYBC'
    'ABKAFSAXc=');

@$core.Deprecated('Use markerDetectionDescriptor instead')
const MarkerDetection$json = {
  '1': 'MarkerDetection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'family', '3': 2, '4': 1, '5': 9, '10': 'family'},
    {
      '1': 'position',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Vec3',
      '10': 'position'
    },
    {
      '1': 'orientation',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Quat',
      '10': 'orientation'
    },
    {
      '1': 'euler_deg',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Vec3',
      '10': 'eulerDeg'
    },
    {'1': 'distance', '3': 6, '4': 1, '5': 1, '10': 'distance'},
  ],
};

/// Descriptor for `MarkerDetection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markerDetectionDescriptor = $convert.base64Decode(
    'Cg9NYXJrZXJEZXRlY3Rpb24SDgoCaWQYASABKAVSAmlkEhYKBmZhbWlseRgCIAEoCVIGZmFtaW'
    'x5EjMKCHBvc2l0aW9uGAMgASgLMhcuc3dhcm1ib3RpeC5jdXN0b20uVmVjM1IIcG9zaXRpb24S'
    'OQoLb3JpZW50YXRpb24YBCABKAsyFy5zd2FybWJvdGl4LmN1c3RvbS5RdWF0UgtvcmllbnRhdG'
    'lvbhI0CglldWxlcl9kZWcYBSABKAsyFy5zd2FybWJvdGl4LmN1c3RvbS5WZWMzUghldWxlckRl'
    'ZxIaCghkaXN0YW5jZRgGIAEoAVIIZGlzdGFuY2U=');

@$core.Deprecated('Use markerDetectionsDescriptor instead')
const MarkerDetections$json = {
  '1': 'MarkerDetections',
  '2': [
    {'1': 'stamp_sec', '3': 1, '4': 1, '5': 5, '10': 'stampSec'},
    {'1': 'stamp_nanosec', '3': 2, '4': 1, '5': 13, '10': 'stampNanosec'},
    {'1': 'camera', '3': 3, '4': 1, '5': 9, '10': 'camera'},
    {'1': 'frame_seq', '3': 4, '4': 1, '5': 4, '10': 'frameSeq'},
    {
      '1': 'markers',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.swarmbotix.custom.MarkerDetection',
      '10': 'markers'
    },
  ],
};

/// Descriptor for `MarkerDetections`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markerDetectionsDescriptor = $convert.base64Decode(
    'ChBNYXJrZXJEZXRlY3Rpb25zEhsKCXN0YW1wX3NlYxgBIAEoBVIIc3RhbXBTZWMSIwoNc3RhbX'
    'BfbmFub3NlYxgCIAEoDVIMc3RhbXBOYW5vc2VjEhYKBmNhbWVyYRgDIAEoCVIGY2FtZXJhEhsK'
    'CWZyYW1lX3NlcRgEIAEoBFIIZnJhbWVTZXESPAoHbWFya2VycxgFIAMoCzIiLnN3YXJtYm90aX'
    'guY3VzdG9tLk1hcmtlckRldGVjdGlvblIHbWFya2Vycw==');
