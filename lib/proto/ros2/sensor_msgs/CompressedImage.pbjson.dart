// This is a generated file - do not edit.
//
// Generated from sensor_msgs/CompressedImage.proto.

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

@$core.Deprecated('Use compressedImageDescriptor instead')
const CompressedImage$json = {
  '1': 'CompressedImage',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.std_msgs.Header',
      '10': 'header'
    },
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `CompressedImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compressedImageDescriptor = $convert.base64Decode(
    'Cg9Db21wcmVzc2VkSW1hZ2USKAoGaGVhZGVyGAEgASgLMhAuc3RkX21zZ3MuSGVhZGVyUgZoZW'
    'FkZXISFgoGZm9ybWF0GAIgASgJUgZmb3JtYXQSEgoEZGF0YRgDIAEoDFIEZGF0YQ==');
