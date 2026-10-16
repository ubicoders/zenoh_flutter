// This is a generated file - do not edit.
//
// Generated from sensor_msgs/Image.proto.

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

@$core.Deprecated('Use imageDescriptor instead')
const Image$json = {
  '1': 'Image',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.std_msgs.Header',
      '10': 'header'
    },
    {'1': 'height', '3': 2, '4': 1, '5': 13, '10': 'height'},
    {'1': 'width', '3': 3, '4': 1, '5': 13, '10': 'width'},
    {'1': 'encoding', '3': 4, '4': 1, '5': 9, '10': 'encoding'},
    {'1': 'is_bigendian', '3': 5, '4': 1, '5': 13, '10': 'isBigendian'},
    {'1': 'step', '3': 6, '4': 1, '5': 13, '10': 'step'},
    {'1': 'data', '3': 7, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Image`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDescriptor = $convert.base64Decode(
    'CgVJbWFnZRIoCgZoZWFkZXIYASABKAsyEC5zdGRfbXNncy5IZWFkZXJSBmhlYWRlchIWCgZoZW'
    'lnaHQYAiABKA1SBmhlaWdodBIUCgV3aWR0aBgDIAEoDVIFd2lkdGgSGgoIZW5jb2RpbmcYBCAB'
    'KAlSCGVuY29kaW5nEiEKDGlzX2JpZ2VuZGlhbhgFIAEoDVILaXNCaWdlbmRpYW4SEgoEc3RlcB'
    'gGIAEoDVIEc3RlcBISCgRkYXRhGAcgASgMUgRkYXRh');
