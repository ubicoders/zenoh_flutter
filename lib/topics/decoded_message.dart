import 'dart:convert';
import 'dart:typed_data';

import 'package:zenoh_flutter/topics/payload_type.dart';

/// A structured message (protobuf or FlatBuffers) decoded for display.
class DecodedMessage {
  const DecodedMessage({
    required this.schema,
    required this.fieldsJson,
    this.blob,
    this.blobType,
    this.blobField,
  });

  /// Pretty-prints [fields] (a JSON-encodable value, normally a map) and
  /// sniffs [blob] to fill [blobType].
  factory DecodedMessage.fromFields({
    required String schema,
    required Object? fields,
    String? blobField,
    Uint8List? blob,
  }) {
    final PayloadType? blobType;
    if (blob == null) {
      blobType = null;
    } else {
      final sniffed = detectPayloadType(blob);
      blobType = isImagePayload(sniffed) ? sniffed : PayloadType.binary;
    }
    return DecodedMessage(
      schema: schema,
      fieldsJson: const JsonEncoder.withIndent('  ').convert(fields),
      blob: blob,
      blobType: blobType,
      blobField: blobField,
    );
  }

  /// Fully qualified message name, e.g. `zenoh_demo.Imu`.
  final String schema;

  /// The message as JSON, indented by two spaces: proto3 JSON for protobuf,
  /// the table's hand-written mapping for FlatBuffers. Byte fields, nested
  /// ones included, read `<N bytes>` instead of base64.
  final String fieldsJson;

  /// Contents of the message's first non-empty top-level bytes field (e.g. an
  /// encoded camera frame), or null when there is none.
  final Uint8List? blob;

  /// What [blob] looks like: [PayloadType.imageJpeg], [PayloadType.imagePng]
  /// or [PayloadType.binary]. Null without a [blob].
  final PayloadType? blobType;

  /// Name of the field [blob] came from, as it appears in [fieldsJson]
  /// (e.g. `data`).
  final String? blobField;

  /// True when [blob] is an encoded image.
  bool get hasImage => isImagePayload(blobType);
}
