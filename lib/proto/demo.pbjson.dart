// This is a generated file - do not edit.
//
// Generated from demo.proto.

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

@$core.Deprecated('Use headerDescriptor instead')
const Header$json = {
  '1': 'Header',
  '2': [
    {'1': 'timestamp_ns', '3': 1, '4': 1, '5': 4, '10': 'timestampNs'},
    {'1': 'seq', '3': 2, '4': 1, '5': 4, '10': 'seq'},
  ],
};

/// Descriptor for `Header`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headerDescriptor = $convert.base64Decode(
    'CgZIZWFkZXISIQoMdGltZXN0YW1wX25zGAEgASgEUgt0aW1lc3RhbXBOcxIQCgNzZXEYAiABKA'
    'RSA3NlcQ==');

@$core.Deprecated('Use vector3Descriptor instead')
const Vector3$json = {
  '1': 'Vector3',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 1, '10': 'y'},
    {'1': 'z', '3': 3, '4': 1, '5': 1, '10': 'z'},
  ],
};

/// Descriptor for `Vector3`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vector3Descriptor = $convert.base64Decode(
    'CgdWZWN0b3IzEgwKAXgYASABKAFSAXgSDAoBeRgCIAEoAVIBeRIMCgF6GAMgASgBUgF6');

@$core.Deprecated('Use imuDescriptor instead')
const Imu$json = {
  '1': 'Imu',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.zenoh_demo.Header',
      '10': 'header'
    },
    {
      '1': 'accel',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.zenoh_demo.Vector3',
      '10': 'accel'
    },
    {
      '1': 'gyro',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.zenoh_demo.Vector3',
      '10': 'gyro'
    },
    {'1': 'temp', '3': 4, '4': 1, '5': 1, '10': 'temp'},
  ],
};

/// Descriptor for `Imu`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imuDescriptor = $convert.base64Decode(
    'CgNJbXUSKgoGaGVhZGVyGAEgASgLMhIuemVub2hfZGVtby5IZWFkZXJSBmhlYWRlchIpCgVhY2'
    'NlbBgCIAEoCzITLnplbm9oX2RlbW8uVmVjdG9yM1IFYWNjZWwSJwoEZ3lybxgDIAEoCzITLnpl'
    'bm9oX2RlbW8uVmVjdG9yM1IEZ3lybxISCgR0ZW1wGAQgASgBUgR0ZW1w');

@$core.Deprecated('Use imageDescriptor instead')
const Image$json = {
  '1': 'Image',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.zenoh_demo.Header',
      '10': 'header'
    },
    {'1': 'width', '3': 2, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 13, '10': 'height'},
    {'1': 'format', '3': 4, '4': 1, '5': 9, '10': 'format'},
    {'1': 'data', '3': 5, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Image`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDescriptor = $convert.base64Decode(
    'CgVJbWFnZRIqCgZoZWFkZXIYASABKAsyEi56ZW5vaF9kZW1vLkhlYWRlclIGaGVhZGVyEhQKBX'
    'dpZHRoGAIgASgNUgV3aWR0aBIWCgZoZWlnaHQYAyABKA1SBmhlaWdodBIWCgZmb3JtYXQYBCAB'
    'KAlSBmZvcm1hdBISCgRkYXRhGAUgASgMUgRkYXRh');

@$core.Deprecated('Use rawDescriptor instead')
const Raw$json = {
  '1': 'Raw',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.zenoh_demo.Header',
      '10': 'header'
    },
    {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Raw`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rawDescriptor = $convert.base64Decode(
    'CgNSYXcSKgoGaGVhZGVyGAEgASgLMhIuemVub2hfZGVtby5IZWFkZXJSBmhlYWRlchISCgRkYX'
    'RhGAIgASgMUgRkYXRh');
