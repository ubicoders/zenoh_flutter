import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/proto/demo.pb.dart';
import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';

const _imageEncoding = 'application/protobuf;zenoh_demo.Image';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

Map<String, dynamic> _fields(DecodedMessage decoded) =>
    jsonDecode(decoded.fieldsJson) as Map<String, dynamic>;

void main() {
  test('decodes an Imu serialised by Python', () {
    // tools/demo_pb2.py: header(timestamp_ns=1700000000000000000, seq=7),
    // accel(1.5, -2.25, 9.806), gyro(0.001, 0.002, -0.003), temp 36.4.
    final bytes = _hex(
      '0a0c088080a8b1e39fe7cb171007121b09000000000000f83f'
      '1100000000000002c019e9263108ac9c23401a1b09fca9f1d24d62503f'
      '11fca9f1d24d62603f19fa7e6abc749368bf213333333333334240',
    );
    final decoded = decodeMessage(
      bytes,
      PayloadType.protobuf,
      'application/protobuf;zenoh_demo.Imu',
    )!;
    expect(decoded.blob, isNull);
    expect(_fields(decoded), {
      // uint64 fields are strings in proto3 JSON.
      'header': {'timestampNs': '1700000000000000000', 'seq': '7'},
      'accel': {'x': 1.5, 'y': -2.25, 'z': 9.806},
      'gyro': {'x': 0.001, 'y': 0.002, 'z': -0.003},
      'temp': 36.4,
    });
  });

  test('Image keeps the JPEG as an image blob and hides it in JSON', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 1, 2]);
    final bytes = Image(
      width: 640,
      height: 480,
      format: 'jpeg',
      data: jpeg,
    ).writeToBuffer();
    final decoded = decodeMessage(bytes, PayloadType.protobuf, _imageEncoding)!;

    expect(decoded.blob, jpeg);
    expect(decoded.blobType, PayloadType.imageJpeg);
    expect(decoded.hasImage, isTrue);
    expect(_fields(decoded)['data'], '<${jpeg.length} bytes>');
    expect(decoded.fieldsJson, isNot(contains(base64Encode(jpeg))));
    // The viewer draws (and evicts) the same blob object every time.
    final image = imageBytesOf(bytes, PayloadType.protobuf, _imageEncoding);
    expect(image, jpeg);
    expect(
      imageBytesOf(bytes, PayloadType.protobuf, _imageEncoding),
      same(image),
    );
  });

  test('unknown schemas and garbage bytes give null, never throw', () {
    expect(
      decodeMessage(
        Uint8List.fromList([8, 1]),
        PayloadType.protobuf,
        'application/protobuf;zenoh_demo.Nope',
      ),
      isNull,
    );
    final garbage = [
      Uint8List.fromList([0x0A, 0x7F, 0x01]), // length past the end
      Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
      utf8.encode('definitely not protobuf'),
    ];
    for (final bytes in garbage) {
      expect(
        () => decodeMessage(
          bytes,
          PayloadType.protobuf,
          'application/protobuf;zenoh_demo.Imu',
        ),
        returnsNormally,
      );
    }
  });
}
