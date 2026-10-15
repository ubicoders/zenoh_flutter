import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';
import 'package:zenoh_flutter/proto/demo.pb.dart' as demo;
import 'package:zenoh_flutter/topics/decoded_message.dart';

/// Every protobuf message the viewer can decode, keyed by its fully
/// qualified name (e.g. `zenoh_demo.Imu`), as named in the
/// `application/protobuf;<name>` zenoh encoding.
///
/// The names come from the generated metadata, so a new message only needs
/// its constructor added to the list below after regenerating `lib/proto/`.
final Map<String, GeneratedMessage Function()> protoMessages = _byName([
  demo.Header.new,
  demo.Vector3.new,
  demo.Imu.new,
  demo.Image.new,
  demo.Raw.new,
]);

Map<String, GeneratedMessage Function()> _byName(
  List<GeneratedMessage Function()> constructors,
) => Map.unmodifiable({
  for (final create in constructors)
    create().info_.qualifiedMessageName: create,
});

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
    return DecodedMessage.fromFields(
      schema: schema,
      fields: _redactBytes(message, message.toProto3Json()),
      blobField: field,
      blob: blob,
    );
  } catch (_) {
    return null;
  }
}

/// The first non-empty singular bytes field of [message], by tag number.
(String?, Uint8List?) _firstBlob(GeneratedMessage message) {
  for (final field in message.info_.sortedByTag) {
    if (field.isRepeated || !PbFieldType.isBytes(field.type)) continue;
    final value = message.getField(field.tagNumber);
    if (value is List<int> && value.isNotEmpty) {
      return (
        field.name,
        value is Uint8List ? value : Uint8List.fromList(value),
      );
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
