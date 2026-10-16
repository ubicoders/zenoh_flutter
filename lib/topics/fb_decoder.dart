import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:zenoh_flutter/fbs/ros2/Header_std_msgs_generated.dart'
    as std_msgs;
import 'package:zenoh_flutter/fbs/ros2/Temperature_sensor_msgs_generated.dart'
    as sensor_msgs;
import 'package:zenoh_flutter/fbs/ros2/Time_builtin_interfaces_generated.dart'
    as builtin_interfaces;
import 'package:zenoh_flutter/topics/decoded_message.dart';

/// Decodes a whole FlatBuffer whose root is one particular table. May throw
/// on malformed bytes; [decodeFlatBuffer] catches.
typedef FbMessageDecoder = DecodedMessage Function(Uint8List bytes);

/// Every FlatBuffers root table the viewer can decode, keyed by its sb vault
/// name (e.g. `ros2/sensor_msgs/Temperature`), as named in the
/// `application/flatbuffers;<name>` zenoh encoding that sb publishers stamp.
/// Each table is also reachable by its bare FlatBuffers name
/// (`sensor_msgs.Temperature`).
///
/// Unlike `protoMessages` (proto_decoder.dart), every table needs its own
/// entry here with a short hand-written converter to JSON fields:
/// FlatBuffers has no runtime reflection in Dart, so the code flatc
/// generates has typed getters but no way to list a table's fields or
/// their names. After adding a message to `FB_MESSAGES` in
/// `tools/gen_ros2_messages.sh` and regenerating `lib/fbs/ros2/`, add a
/// [_table] line and a converter below. A table carrying a byte vector
/// (e.g. an encoded image) can be a function that passes it as the `blob` of
/// [DecodedMessage.fromFields] instead, so it is drawn like the image inside
/// a protobuf message.
final Map<String, FbMessageDecoder> fbMessages = Map.unmodifiable(
  Map.fromEntries([
    ..._table(
      'ros2/sensor_msgs/Temperature',
      sensor_msgs.Temperature.reader,
      _temperature,
    ),
  ]),
);

/// The [fbMessages] entries for root table [schema] (a vault name
/// `<style>/<ns>/<Leaf>`), under that name and under `<ns>.<Leaf>`: reads it
/// with [reader] and shows it as the JSON map [fields] builds.
List<MapEntry<String, FbMessageDecoder>> _table<T>(
  String schema,
  fb.Reader<T> reader,
  Map<String, Object?> Function(T table) fields,
) {
  DecodedMessage decode(Uint8List bytes) => DecodedMessage.fromFields(
    schema: schema,
    fields: fields(reader.read(_bufferOf(bytes), 0)),
  );
  final qualified = schema.substring(schema.indexOf('/') + 1);
  return [
    MapEntry(schema, decode),
    MapEntry(qualified.replaceAll('/', '.'), decode),
  ];
}

// Memoised per payload object so periodic rebuilds don't re-decode. The
// schema is kept alongside since the result depends on it.
final Expando<({String schema, DecodedMessage? decoded})> _cache = Expando(
  'decodedFlatBuffer',
);

/// Decodes [bytes] as a FlatBuffer whose root table is [schema] (a key of
/// [fbMessages]).
///
/// Returns null when [schema] is unknown or [bytes] is not a plausible
/// FlatBuffer; never throws. Dart has no FlatBuffers verifier, so bytes
/// that pass the cheap structural check without really being a [schema]
/// can still decode to meaningless values.
///
/// Most callers want `decodeMessage` (message_decoder.dart), which also
/// handles protobuf and reads the schema from the zenoh encoding.
DecodedMessage? decodeFlatBuffer(String schema, Uint8List bytes) {
  final cached = _cache[bytes];
  if (cached != null && cached.schema == schema) return cached.decoded;
  final decoded = _decode(schema, bytes);
  _cache[bytes] = (schema: schema, decoded: decoded);
  return decoded;
}

DecodedMessage? _decode(String schema, Uint8List bytes) {
  final decode = fbMessages[schema];
  if (decode == null || !_plausibleRoot(bytes)) return null;
  try {
    return decode(bytes);
  } catch (_) {
    // RangeError for an offset past the end, StateError, ... : bad bytes.
    return null;
  }
}

/// Smallest FlatBuffer with a root table: the root offset, the table's
/// vtable offset and a vtable holding just its own size and the table's.
const int _minBufferBytes = 12;

/// Cheap structural check of the root table, standing in for the verifier
/// Dart lacks: the root offset, the root table, its vtable and every field
/// offset in it must lie inside [bytes]. This turns away most garbage (text,
/// protobuf, truncated buffers) before any field is read.
bool _plausibleRoot(Uint8List bytes) {
  final n = bytes.length;
  if (n < _minBufferBytes) return false;
  final data = ByteData.sublistView(bytes);
  final table = data.getUint32(0, Endian.little);
  if (table < 4 || table > n - 4) return false;
  final vtable = table - data.getInt32(table, Endian.little);
  if (vtable < 0 || vtable > n - 4) return false;
  final vtableSize = data.getUint16(vtable, Endian.little);
  final tableSize = data.getUint16(vtable + 2, Endian.little);
  if (vtableSize < 4 || vtableSize.isOdd || vtable + vtableSize > n) {
    return false;
  }
  if (tableSize < 4 || table + tableSize > n) return false;
  for (var slot = vtable + 4; slot < vtable + vtableSize; slot += 2) {
    final field = data.getUint16(slot, Endian.little);
    if (field != 0 && (field < 4 || field >= tableSize)) return false;
  }
  return true;
}

/// A buffer context over exactly [bytes].
///
/// Not [fb.BufferContext.fromBytes], which views from the start of [bytes]
/// to the end of its underlying buffer: for a payload sliced out of a bigger
/// buffer, a bad offset would read the neighbouring bytes instead of
/// throwing a [RangeError].
fb.BufferContext _bufferOf(Uint8List bytes) =>
    fb.BufferContext(ByteData.sublistView(bytes));

// Converters, one per table. `flatc --proto` turns every proto message into
// a table, so a nested message is a sub-table: one that is not set is left
// out, as unset message fields are in proto3 JSON, and so is an unset
// string. Scalars read their schema default when not set, so they are
// always present. Field names are lowerCamelCase as in proto3 JSON.

Map<String, Object?> _temperature(sensor_msgs.Temperature t) => {
  if (t.header case final header?) 'header': _header(header),
  'temperature': _double(t.temperature),
  'variance': _double(t.variance),
};

Map<String, Object?> _header(std_msgs.Header header) => {
  if (header.stamp case final stamp?) 'stamp': _time(stamp),
  'frameId': ?header.frameId,
};

Map<String, Object?> _time(builtin_interfaces.Time time) => {
  'sec': time.sec,
  'nanosec': time.nanosec,
};

/// [value] as JSON: non-finite values, which JSON has no number for, become
/// `"NaN"`, `"Infinity"` or `"-Infinity"` as in proto3 JSON.
Object _double(double value) => value.isFinite ? value : value.toString();
