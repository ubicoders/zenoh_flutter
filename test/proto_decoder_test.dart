import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/proto/ros2/sensor_msgs/CompressedImage.pb.dart';
import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';

const _imuEncoding = 'application/protobuf;ros2/sensor_msgs/Imu';
const _imageEncoding = 'application/protobuf;ros2/sensor_msgs/CompressedImage';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

Map<String, dynamic> _fields(DecodedMessage decoded) =>
    jsonDecode(decoded.fieldsJson) as Map<String, dynamic>;

void main() {
  test('decodes an Imu serialised by Python', () {
    // protoc --python_out from the vault's sensor_msgs/Imu.proto:
    // header(stamp(sec=1700000000, nanosec=7), frame_id="imu_link"),
    // orientation(w=1), angular_velocity(0.001, 0.002, -0.003),
    // linear_acceleration(1.5, -2.25, 9.806).
    final bytes = _hex(
      '0a140a080880e2cfaa0610071208696d755f6c696e6b120921000000000000f03f'
      '221b09fca9f1d24d62503f11fca9f1d24d62603f19fa7e6abc749368bf'
      '321b09000000000000f83f1100000000000002c019e9263108ac9c2340',
    );
    final decoded = decodeMessage(bytes, PayloadType.protobuf, _imuEncoding)!;
    expect(decoded.blob, isNull);
    final fields = {
      'header': {
        'stamp': {'sec': 1700000000, 'nanosec': 7},
        'frameId': 'imu_link',
      },
      'orientation': {'w': 1.0},
      'angularVelocity': {'x': 0.001, 'y': 0.002, 'z': -0.003},
      'linearAcceleration': {'x': 1.5, 'y': -2.25, 'z': 9.806},
    };
    expect(_fields(decoded), fields);
    // The bare protobuf name is accepted too.
    expect(
      _fields(
        decodeMessage(
          bytes,
          PayloadType.protobuf,
          'application/protobuf;sensor_msgs.Imu',
        )!,
      ),
      fields,
    );
  });

  test(
    'CompressedImage keeps the JPEG as an image blob and hides it in JSON',
    () {
      final jpeg = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        1,
        2,
      ]);
      final bytes = CompressedImage(format: 'jpeg', data: jpeg).writeToBuffer();
      final decoded = decodeMessage(
        bytes,
        PayloadType.protobuf,
        _imageEncoding,
      )!;

      expect(decoded.blob, jpeg);
      expect(decoded.blobField, 'data');
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
    },
  );

  test('unknown schemas and garbage bytes give null, never throw', () {
    expect(
      decodeMessage(
        Uint8List.fromList([8, 1]),
        PayloadType.protobuf,
        'application/protobuf;ros2/sensor_msgs/Nope',
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
        () => decodeMessage(bytes, PayloadType.protobuf, _imuEncoding),
        returnsNormally,
      );
    }
  });
}
