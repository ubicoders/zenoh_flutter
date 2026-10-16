// This is a generated file - do not edit.
//
// Generated from custom/CubePoses.proto.

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

@$core.Deprecated('Use mat3Descriptor instead')
const Mat3$json = {
  '1': 'Mat3',
  '2': [
    {'1': 'm', '3': 1, '4': 3, '5': 1, '10': 'm'},
  ],
};

/// Descriptor for `Mat3`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mat3Descriptor =
    $convert.base64Decode('CgRNYXQzEgwKAW0YASADKAFSAW0=');

@$core.Deprecated('Use cubePoseDescriptor instead')
const CubePose$json = {
  '1': 'CubePose',
  '2': [
    {'1': 'cube_id', '3': 1, '4': 1, '5': 13, '10': 'cubeId'},
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Vec3',
      '10': 'position'
    },
    {
      '1': 'rotation',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Mat3',
      '10': 'rotation'
    },
    {
      '1': 'euler_deg',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Vec3',
      '10': 'eulerDeg'
    },
    {
      '1': 'orientation',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Quat',
      '10': 'orientation'
    },
    {'1': 'marker_ids', '3': 6, '4': 3, '5': 5, '10': 'markerIds'},
    {'1': 'num_cameras', '3': 7, '4': 1, '5': 13, '10': 'numCameras'},
    {'1': 'residual_rms', '3': 8, '4': 1, '5': 1, '10': 'residualRms'},
    {'1': 'alive', '3': 9, '4': 1, '5': 8, '10': 'alive'},
    {'1': 'last_seen_sec', '3': 10, '4': 1, '5': 5, '10': 'lastSeenSec'},
    {
      '1': 'last_seen_nanosec',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'lastSeenNanosec'
    },
    {
      '1': 'velocity',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.swarmbotix.custom.Vec3',
      '10': 'velocity'
    },
  ],
};

/// Descriptor for `CubePose`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cubePoseDescriptor = $convert.base64Decode(
    'CghDdWJlUG9zZRIXCgdjdWJlX2lkGAEgASgNUgZjdWJlSWQSMwoIcG9zaXRpb24YAiABKAsyFy'
    '5zd2FybWJvdGl4LmN1c3RvbS5WZWMzUghwb3NpdGlvbhIzCghyb3RhdGlvbhgDIAEoCzIXLnN3'
    'YXJtYm90aXguY3VzdG9tLk1hdDNSCHJvdGF0aW9uEjQKCWV1bGVyX2RlZxgEIAEoCzIXLnN3YX'
    'JtYm90aXguY3VzdG9tLlZlYzNSCGV1bGVyRGVnEjkKC29yaWVudGF0aW9uGAUgASgLMhcuc3dh'
    'cm1ib3RpeC5jdXN0b20uUXVhdFILb3JpZW50YXRpb24SHQoKbWFya2VyX2lkcxgGIAMoBVIJbW'
    'Fya2VySWRzEh8KC251bV9jYW1lcmFzGAcgASgNUgpudW1DYW1lcmFzEiEKDHJlc2lkdWFsX3Jt'
    'cxgIIAEoAVILcmVzaWR1YWxSbXMSFAoFYWxpdmUYCSABKAhSBWFsaXZlEiIKDWxhc3Rfc2Vlbl'
    '9zZWMYCiABKAVSC2xhc3RTZWVuU2VjEioKEWxhc3Rfc2Vlbl9uYW5vc2VjGAsgASgNUg9sYXN0'
    'U2Vlbk5hbm9zZWMSMwoIdmVsb2NpdHkYDCABKAsyFy5zd2FybWJvdGl4LmN1c3RvbS5WZWMzUg'
    'h2ZWxvY2l0eQ==');

@$core.Deprecated('Use cubePosesDescriptor instead')
const CubePoses$json = {
  '1': 'CubePoses',
  '2': [
    {'1': 'stamp_sec', '3': 1, '4': 1, '5': 5, '10': 'stampSec'},
    {'1': 'stamp_nanosec', '3': 2, '4': 1, '5': 13, '10': 'stampNanosec'},
    {'1': 'frame_seq', '3': 3, '4': 1, '5': 4, '10': 'frameSeq'},
    {
      '1': 'cubes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.swarmbotix.custom.CubePose',
      '10': 'cubes'
    },
  ],
};

/// Descriptor for `CubePoses`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cubePosesDescriptor = $convert.base64Decode(
    'CglDdWJlUG9zZXMSGwoJc3RhbXBfc2VjGAEgASgFUghzdGFtcFNlYxIjCg1zdGFtcF9uYW5vc2'
    'VjGAIgASgNUgxzdGFtcE5hbm9zZWMSGwoJZnJhbWVfc2VxGAMgASgEUghmcmFtZVNlcRIxCgVj'
    'dWJlcxgEIAMoCzIbLnN3YXJtYm90aXguY3VzdG9tLkN1YmVQb3NlUgVjdWJlcw==');
