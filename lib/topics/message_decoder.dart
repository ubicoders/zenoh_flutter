import 'dart:typed_data';

import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/fb_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/proto_decoder.dart';

/// Decodes a structured-message payload for display: [decodeProto] for
/// [PayloadType.protobuf], [decodeFlatBuffer] for [PayloadType.flatbuffers],
/// with the message type taken from the schema suffix of [encoding]
/// (`application/flatbuffers;zenoh_demo.Imu`, see [messageSchemaOf]).
///
/// Null for any other [type], when [encoding] names no message type, or when
/// [bytes] cannot be decoded as it. Memoised per payload.
DecodedMessage? decodeMessage(
  Uint8List bytes,
  PayloadType type,
  String? encoding,
) {
  final decode = switch (type) {
    PayloadType.protobuf => decodeProto,
    PayloadType.flatbuffers => decodeFlatBuffer,
    _ => null,
  };
  final schema = messageSchemaOf(encoding);
  return decode == null || schema == null ? null : decode(schema, bytes);
}

/// Whether the decoder for [type] knows the message type [schema], i.e.
/// whether a null [decodeMessage] means bad bytes rather than an unknown
/// message.
bool isKnownMessage(PayloadType type, String schema) => switch (type) {
  PayloadType.protobuf => protoMessages.containsKey(schema),
  PayloadType.flatbuffers => fbMessages.containsKey(schema),
  _ => false,
};

/// The encoded image to draw for a payload of [type]: [bytes] itself for the
/// image types, the image inside a protobuf or FlatBuffers message (its
/// [DecodedMessage.blob]), and null when there is no image.
Uint8List? imageBytesOf(Uint8List bytes, PayloadType type, String? encoding) =>
    switch (type) {
      PayloadType.imageJpeg || PayloadType.imagePng => bytes,
      _ => switch (decodeMessage(bytes, type, encoding)) {
        final d? when d.hasImage => d.blob,
        _ => null,
      },
    };
