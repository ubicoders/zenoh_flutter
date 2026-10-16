// This is a generated file - do not edit.
//
// Generated from sensor_msgs/Imu.proto.

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

@$core.Deprecated('Use imuDescriptor instead')
const Imu$json = {
  '1': 'Imu',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.std_msgs.Header',
      '10': 'header'
    },
    {
      '1': 'orientation',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.geometry_msgs.Quaternion',
      '10': 'orientation'
    },
    {
      '1': 'orientation_covariance',
      '3': 3,
      '4': 3,
      '5': 1,
      '10': 'orientationCovariance'
    },
    {
      '1': 'angular_velocity',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.geometry_msgs.Vector3',
      '10': 'angularVelocity'
    },
    {
      '1': 'angular_velocity_covariance',
      '3': 5,
      '4': 3,
      '5': 1,
      '10': 'angularVelocityCovariance'
    },
    {
      '1': 'linear_acceleration',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.geometry_msgs.Vector3',
      '10': 'linearAcceleration'
    },
    {
      '1': 'linear_acceleration_covariance',
      '3': 7,
      '4': 3,
      '5': 1,
      '10': 'linearAccelerationCovariance'
    },
  ],
};

/// Descriptor for `Imu`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imuDescriptor = $convert.base64Decode(
    'CgNJbXUSKAoGaGVhZGVyGAEgASgLMhAuc3RkX21zZ3MuSGVhZGVyUgZoZWFkZXISOwoLb3JpZW'
    '50YXRpb24YAiABKAsyGS5nZW9tZXRyeV9tc2dzLlF1YXRlcm5pb25SC29yaWVudGF0aW9uEjUK'
    'Fm9yaWVudGF0aW9uX2NvdmFyaWFuY2UYAyADKAFSFW9yaWVudGF0aW9uQ292YXJpYW5jZRJBCh'
    'Bhbmd1bGFyX3ZlbG9jaXR5GAQgASgLMhYuZ2VvbWV0cnlfbXNncy5WZWN0b3IzUg9hbmd1bGFy'
    'VmVsb2NpdHkSPgobYW5ndWxhcl92ZWxvY2l0eV9jb3ZhcmlhbmNlGAUgAygBUhlhbmd1bGFyVm'
    'Vsb2NpdHlDb3ZhcmlhbmNlEkcKE2xpbmVhcl9hY2NlbGVyYXRpb24YBiABKAsyFi5nZW9tZXRy'
    'eV9tc2dzLlZlY3RvcjNSEmxpbmVhckFjY2VsZXJhdGlvbhJECh5saW5lYXJfYWNjZWxlcmF0aW'
    '9uX2NvdmFyaWFuY2UYByADKAFSHGxpbmVhckFjY2VsZXJhdGlvbkNvdmFyaWFuY2U=');
