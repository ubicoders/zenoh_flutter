import 'dart:convert';
import 'dart:typed_data';

import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/raw_image.dart';

/// A structured message (protobuf or FlatBuffers) decoded for display.
class DecodedMessage {
  const DecodedMessage({
    required this.schema,
    required this.fieldsJson,
    this.blob,
    this.blobType,
    this.blobField,
    this.rawImage,
  });

  /// Pretty-prints [fields] (a JSON-encodable value, normally a map) and
  /// sniffs [blob] to fill [blobType].
  factory DecodedMessage.fromFields({
    required String schema,
    required Object? fields,
    String? blobField,
    Uint8List? blob,
    RawImageFrame? rawImage,
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
      rawImage: rawImage,
    );
  }

  /// The message type as the encoding named it: the sb vault name, e.g.
  /// `ros2/sensor_msgs/Imu`, or a bare `sensor_msgs.Imu`.
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

  /// The uncompressed image the message is (a `sensor_msgs/Image`), or null
  /// for every other message. Set even when the frame cannot be drawn; see
  /// [RawImageFrame.problem]. Its pixels are also [blob] (a raw frame is
  /// never [hasImage]).
  final RawImageFrame? rawImage;
}
