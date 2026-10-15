import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:zenoh_flutter/fbs/demo_zenoh_demo_generated.dart' as demo;
import 'package:zenoh_flutter/topics/decoded_message.dart';

/// Decodes a whole FlatBuffer whose root is one particular table. May throw
/// on malformed bytes; [decodeFlatBuffer] catches.
typedef FbMessageDecoder = DecodedMessage Function(Uint8List bytes);

/// Every FlatBuffers root table the viewer can decode, keyed by its fully
/// qualified name (e.g. `zenoh_demo.Imu`), as named in the
/// `application/flatbuffers;<name>` zenoh encoding.
///
/// Unlike `protoMessages` (proto_decoder.dart), every table needs its own
/// entry here with a short hand-written converter to JSON fields:
/// FlatBuffers has no runtime reflection in Dart, so the code flatc
/// generates has typed getters but no way to list a table's fields or
/// their names. After adding a root table to `tools/fbs/demo.fbs` and
/// regenerating `lib/fbs/`, add a [_table] line and a converter below. A
/// table carrying a byte vector (e.g. an encoded image) can be a function
/// that passes it as the `blob` of [DecodedMessage.fromFields] instead, so it
/// is drawn like the image inside a protobuf message.
final Map<String, FbMessageDecoder> fbMessages = Map.unmodifiable(
  Map.fromEntries([_table('zenoh_demo.Imu', demo.Imu.reader, _imu)]),
);

/// The [fbMessages] entry for root table [schema]: reads it with [reader]
/// and shows it as the JSON map [fields] builds.
MapEntry<String, FbMessageDecoder> _table<T>(
  String schema,
  fb.Reader<T> reader,
  Map<String, Object?> Function(T table) fields,
) => MapEntry(
  schema,
  (bytes) => DecodedMessage.fromFields(
    schema: schema,
    fields: fields(reader.read(_bufferOf(bytes), 0)),
  ),
);

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

// Converters, one per table or struct. Struct fields that are not set are
// left out, as unset message fields are in proto3 JSON; scalars read their
// schema default when not set, so they are always present.

Map<String, Object?> _imu(demo.Imu imu) => {
  if (imu.header case final header?) 'header': _header(header),
  if (imu.accel case final accel?) 'accel': _vector3(accel),
  if (imu.gyro case final gyro?) 'gyro': _vector3(gyro),
  'temp': _double(imu.temp),
};

Map<String, Object?> _header(demo.Header header) => {
  'timestampNs': _uint64(header.timestampNs),
  'seq': _uint64(header.seq),
};

Map<String, Object?> _vector3(demo.Vector3 v) => {
  'x': _double(v.x),
  'y': _double(v.y),
  'z': _double(v.z),
};

/// [value] as JSON: non-finite values, which JSON has no number for, become
/// `"NaN"`, `"Infinity"` or `"-Infinity"` as in proto3 JSON.
Object _double(double value) => value.isFinite ? value : value.toString();

/// A uint64 field as JSON. Dart ints are signed 64-bit, so values from 2^63
/// up read back negative; those are shown as their unsigned decimal string.
Object _uint64(int value) =>
    value >= 0 ? value : BigInt.from(value).toUnsigned(64).toString();
