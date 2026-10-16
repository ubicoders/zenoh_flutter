import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';
import 'package:zenoh_flutter/proto/ros2/builtin_interfaces/Time.pb.dart'
    as builtin_interfaces;
import 'package:zenoh_flutter/proto/ros2/custom/CubePoses.pb.dart'
    as custom_cube_poses;
import 'package:zenoh_flutter/proto/ros2/custom/MarkerDetections.pb.dart'
    as custom_marker_detections;
import 'package:zenoh_flutter/proto/ros2/geometry_msgs/Quaternion.pb.dart'
    as geometry_quaternion;
import 'package:zenoh_flutter/proto/ros2/geometry_msgs/Vector3.pb.dart'
    as geometry_vector3;
import 'package:zenoh_flutter/proto/ros2/sensor_msgs/CompressedImage.pb.dart'
    as sensor_compressed_image;
import 'package:zenoh_flutter/proto/ros2/sensor_msgs/Image.pb.dart'
    as sensor_image;
import 'package:zenoh_flutter/proto/ros2/sensor_msgs/Imu.pb.dart' as sensor_imu;
import 'package:zenoh_flutter/proto/ros2/std_msgs/Header.pb.dart' as std_header;
import 'package:zenoh_flutter/proto/ros2/std_msgs/MultiArrayDimension.pb.dart'
    as std_multi_array_dimension;
import 'package:zenoh_flutter/proto/ros2/std_msgs/MultiArrayLayout.pb.dart'
    as std_multi_array_layout;
import 'package:zenoh_flutter/proto/ros2/std_msgs/String.pb.dart' as std_string;
import 'package:zenoh_flutter/proto/ros2/std_msgs/UInt8MultiArray.pb.dart'
    as std_uint8_multi_array;
import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/raw_image.dart';

/// Every protobuf message the viewer can decode, keyed by its sb vault name
/// (e.g. `ros2/sensor_msgs/Imu`), as named in the
/// `application/protobuf;<name>` zenoh encoding that sb publishers stamp.
/// Each message is also reachable by its bare protobuf name
/// (`sensor_msgs.Imu`, `swarmbotix.custom.CubePoses`), for publishers that
/// tag with that instead.
///
/// The names come from the generated metadata, so a new message only needs
/// its constructor added to a list below after adding it to
/// `tools/gen_ros2_messages.sh` and regenerating `lib/proto/ros2/`.
final Map<String, GeneratedMessage Function()> protoMessages = Map.unmodifiable(
  {
    ..._byName('ros2', [
      sensor_imu.Imu.new,
      sensor_compressed_image.CompressedImage.new,
      sensor_image.Image.new,
      std_string.String.new,
      std_uint8_multi_array.UInt8MultiArray.new,
      std_header.Header.new,
      std_multi_array_layout.MultiArrayLayout.new,
      std_multi_array_dimension.MultiArrayDimension.new,
      builtin_interfaces.Time.new,
      geometry_vector3.Vector3.new,
      geometry_quaternion.Quaternion.new,
    ]),
    // The vault's custom/*.proto declare `package swarmbotix.custom`, so their
    // vault name (`ros2/custom/<Message>`) is not derived from the package.
    // Their nested messages (Vec3, Quat, MarkerDetection, CubePose, Mat3) have
    // no .proto of their own, hence no vault name, and are not listed.
    ..._byName('ros2', vaultPackage: 'custom', [
      custom_marker_detections.MarkerDetections.new,
      custom_cube_poses.CubePoses.new,
    ]),
  },
);

/// Keys each constructor by `<style>/<package>/<Message>`, the vault name,
/// and by its protobuf qualified name `<package>.<Message>`. A dotted
/// package (`a.b`) becomes nested namespaces (`<style>/a/b/<Message>`),
/// unless [vaultPackage] gives the vault directory instead
/// (`<style>/<vaultPackage>/<Message>`).
Map<String, GeneratedMessage Function()> _byName(
  String style,
  List<GeneratedMessage Function()> constructors, {
  String? vaultPackage,
}) {
  final byName = <String, GeneratedMessage Function()>{};
  for (final create in constructors) {
    final info = create().info_;
    final qualified = info.qualifiedMessageName;
    final vaultName = vaultPackage == null
        ? _vaultName(style, qualified)
        : '$style/$vaultPackage/${info.messageName}';
    byName[vaultName] = create;
    byName[qualified] = create;
  }
  return byName;
}

/// `sensor_msgs.Imu` -> `ros2/sensor_msgs/Imu`.
String _vaultName(String style, String qualifiedName) =>
    '$style/${qualifiedName.replaceAll('.', '/')}';

// Memoised per payload object so periodic rebuilds don't re-decode. The
// schema is kept alongside since the result depends on it.
final Expando<({String schema, DecodedMessage? decoded})> _cache = Expando(
  'decodedProto',
);

/// Decodes [bytes] as the protobuf message [schema] (a key of
/// [protoMessages]).
///
/// Returns null when [schema] is unknown or [bytes] cannot be parsed as it.
/// Most callers want `decodeMessage` (message_decoder.dart), which also
/// handles FlatBuffers and reads the schema from the zenoh encoding.
DecodedMessage? decodeProto(String schema, Uint8List bytes) {
  final cached = _cache[bytes];
  if (cached != null && cached.schema == schema) return cached.decoded;
  final decoded = _decode(schema, bytes);
  _cache[bytes] = (schema: schema, decoded: decoded);
  return decoded;
}

DecodedMessage? _decode(String schema, Uint8List bytes) {
  final create = protoMessages[schema];
  if (create == null) return null;
  try {
    final message = create()..mergeFromBuffer(bytes);
    final (field, blob) = _firstBlob(message);
    final rawImage = _rawImageOf(message);
    return DecodedMessage.fromFields(
      schema: schema,
      fields: _toJson(message), // last: it clears the bytes fields
      blobField: field,
      blob: blob,
      rawImage: rawImage,
    );
  } catch (_) {
    return null;
  }
}

/// The pixels of a message that is an uncompressed image
/// (`sensor_msgs/Image`), for the cards to draw; null for other messages.
RawImageFrame? _rawImageOf(GeneratedMessage message) => switch (message) {
  final sensor_image.Image image => RawImageFrame(
    width: image.width,
    height: image.height,
    encoding: image.encoding,
    step: image.step,
    bigEndian: image.isBigendian != 0,
    data: _asBytes(image.data),
  ),
  _ => null,
};

/// [value] as a [Uint8List], the same object when it already is one (as
/// the protobuf reader returns), so [_firstBlob] and [_rawImageOf] share it.
Uint8List _asBytes(List<int> value) =>
    value is Uint8List ? value : Uint8List.fromList(value);

/// The proto3 JSON of [message], every bytes value reading `<N bytes>`.
///
/// The message's own non-empty bytes fields (a camera frame, say) are
/// cleared before the conversion and put back as `<N bytes>` in field
/// order, so a frame is never base64-encoded only to be thrown away. Bytes
/// further down go through [_redactBytes]. Clears those fields of
/// [message], so it is called once everything else has been read.
Object? _toJson(GeneratedMessage message) {
  final info = message.info_;
  final lengths = <int, int>{}; // tag number -> byte count
  // google.protobuf types (Any, BytesValue) have their own JSON form.
  if (!info.qualifiedMessageName.startsWith('google.protobuf.')) {
    for (final field in info.sortedByTag) {
      if (field.isRepeated || !PbFieldType.isBytes(field.type)) continue;
      final value = message.getField(field.tagNumber);
      if (value is List<int> && value.isNotEmpty) {
        lengths[field.tagNumber] = value.length;
      }
    }
  }
  lengths.keys.forEach(message.clearField);
  final json = _redactBytes(message, message.toProto3Json());
  if (lengths.isEmpty || json is! Map<String, dynamic>) return json;
  return <String, dynamic>{
    for (final field in info.sortedByTag)
      if (lengths[field.tagNumber] case final n?)
        field.name: '<$n bytes>'
      else if (json.containsKey(field.name))
        field.name: json[field.name],
  };
}

/// The first non-empty singular bytes field of [message], by tag number.
(String?, Uint8List?) _firstBlob(GeneratedMessage message) {
  for (final field in message.info_.sortedByTag) {
    if (field.isRepeated || !PbFieldType.isBytes(field.type)) continue;
    final value = message.getField(field.tagNumber);
    if (value is List<int> && value.isNotEmpty) {
      return (field.name, _asBytes(value));
    }
  }
  return (null, null);
}

/// Replaces every bytes value in [json] (the proto3 JSON of [message]) with
/// `<N bytes>`, descending into message, repeated and map fields.
Object? _redactBytes(GeneratedMessage message, Object? json) {
  // Well-known types (Timestamp, ...) have their own non-object JSON.
  if (json is! Map<String, dynamic>) return json;
  for (final field in message.info_.sortedByTag) {
    final jsonValue = json[field.name];
    if (jsonValue == null) continue; // unset fields are left out
    final value = message.getField(field.tagNumber);
    if (field is MapFieldInfo) {
      // proto3 JSON keeps the map's order; only the keys are rewritten.
      final values = (value as Map).values.iterator;
      final jsonMap = jsonValue as Map;
      for (final key in jsonMap.keys.toList()) {
        values.moveNext();
        jsonMap[key] = _redactValue(
          field.valueFieldType,
          values.current,
          jsonMap[key],
        );
      }
    } else if (field.isRepeated) {
      final list = value as List;
      final jsonList = jsonValue as List;
      for (var i = 0; i < jsonList.length; i++) {
        jsonList[i] = _redactValue(field.type, list[i], jsonList[i]);
      }
    } else {
      json[field.name] = _redactValue(field.type, value, jsonValue);
    }
  }
  return json;
}

Object? _redactValue(int fieldType, Object? value, Object? json) {
  if (PbFieldType.isBytes(fieldType)) {
    return '<${(value as List<int>).length} bytes>';
  }
  if (PbFieldType.isGroupOrMessage(fieldType)) {
    return _redactBytes(value as GeneratedMessage, json);
  }
  return json;
}
