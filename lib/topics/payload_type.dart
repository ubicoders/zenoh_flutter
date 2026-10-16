import 'dart:convert';
import 'dart:typed_data';

/// What a payload looks like, used to pick a renderer.
enum PayloadType {
  json,
  text,
  imageJpeg,
  imagePng,
  protobuf,
  flatbuffers,
  binary,
}

const String _protobufMime = 'application/protobuf';
const String _flatbuffersMime = 'application/flatbuffers';

const Utf8Decoder _strictUtf8 = Utf8Decoder(allowMalformed: false);

/// Detects the [PayloadType] of [bytes].
///
/// A zenoh [encoding] (e.g. `image/jpeg`, `application/json;schema`) wins
/// when it is one we understand and the bytes agree with it. Otherwise the
/// bytes are sniffed: JPEG/PNG magic numbers, then JSON, then UTF-8 text,
/// and finally binary.
///
/// `application/protobuf` always means [PayloadType.protobuf] and
/// `application/flatbuffers` always means [PayloadType.flatbuffers],
/// whatever the bytes: neither format is self-describing, so neither can be
/// sniffed.
PayloadType detectPayloadType(Uint8List bytes, {String? encoding}) {
  switch (_mimeOf(encoding)) {
    case _protobufMime:
      return PayloadType.protobuf;
    case _flatbuffersMime:
      return PayloadType.flatbuffers;
    case 'image/jpeg':
      return PayloadType.imageJpeg;
    case 'image/png':
      return PayloadType.imagePng;
    case 'application/json':
      final text = _tryUtf8(bytes);
      if (text != null && _isJson(text)) return PayloadType.json;
    case 'text/plain':
      if (_tryUtf8(bytes) != null) return PayloadType.text;
  }

  if (bytes.isEmpty) return PayloadType.text;
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
    return PayloadType.imageJpeg;
  }
  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
    return PayloadType.imagePng;
  }

  final text = _tryUtf8(bytes);
  if (text == null || _hasControlChars(text)) return PayloadType.binary;
  if (_isJson(text)) return PayloadType.json;
  return PayloadType.text;
}

/// Short human label for [t].
String payloadTypeLabel(PayloadType t) => switch (t) {
  PayloadType.json => 'json',
  PayloadType.text => 'text',
  PayloadType.imageJpeg => 'image/jpeg',
  PayloadType.imagePng => 'image/png',
  PayloadType.protobuf => 'protobuf',
  PayloadType.flatbuffers => 'flatbuffers',
  PayloadType.binary => 'binary',
};

/// The message type named by an `application/protobuf` or
/// `application/flatbuffers` [encoding]:
/// `"application/flatbuffers;ros2/sensor_msgs/Temperature"` ->
/// `"ros2/sensor_msgs/Temperature"`. The schema is everything after the
/// first `;`, so an sb vault name (`<style>/<ns>/<Leaf>`, with `/`) and a
/// bare `sensor_msgs.Temperature` both come through whole.
///
/// Null for any other encoding, or when the schema suffix is missing or
/// blank.
String? messageSchemaOf(String? encoding) {
  if (encoding == null) return null;
  final mime = _mimeOf(encoding);
  if (mime != _protobufMime && mime != _flatbuffersMime) return null;
  final semi = encoding.indexOf(';');
  if (semi < 0) return null;
  final schema = encoding.substring(semi + 1).trim();
  return schema.isEmpty ? null : schema;
}

/// [messageSchemaOf] for `application/protobuf` only:
/// `"application/protobuf;ros2/sensor_msgs/Imu"` -> `"ros2/sensor_msgs/Imu"`.
String? protobufSchemaOf(String? encoding) =>
    _mimeOf(encoding) == _protobufMime ? messageSchemaOf(encoding) : null;

/// True for the image types.
bool isImagePayload(PayloadType? t) =>
    t == PayloadType.imageJpeg || t == PayloadType.imagePng;

/// `"application/json;schema"` -> `"application/json"`.
String? _mimeOf(String? encoding) {
  if (encoding == null) return null;
  final semi = encoding.indexOf(';');
  final mime = semi < 0 ? encoding : encoding.substring(0, semi);
  return mime.trim().toLowerCase();
}

String? _tryUtf8(Uint8List bytes) {
  try {
    return _strictUtf8.convert(bytes);
  } on FormatException {
    return null;
  }
}

bool _isJson(String text) {
  if (text.trim().isEmpty) return false;
  try {
    jsonDecode(text);
    return true;
  } catch (_) {
    return false;
  }
}

bool _startsWith(Uint8List bytes, List<int> magic) {
  if (bytes.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return false;
  }
  return true;
}

/// Valid UTF-8 can still be binary (e.g. little-endian integers full of NULs).
/// Treat C0 control characters other than tab/newline/CR/FF, and DEL, as a
/// sign of binary data.
bool _hasControlChars(String text) {
  for (final c in text.codeUnits) {
    if (c == 0x09 || c == 0x0A || c == 0x0C || c == 0x0D) continue;
    if (c < 0x20 || c == 0x7F) return true;
  }
  return false;
}
