import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/rate_counter.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  test('sniffs bytes when there is no usable encoding', () {
    expect(
      detectPayloadType(_bytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])),
      PayloadType.imageJpeg,
    );
    expect(
      detectPayloadType(_bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A])),
      PayloadType.imagePng,
    );
    expect(
      detectPayloadType(utf8.encode('{"x": 1.5, "ok": true}')),
      PayloadType.json,
    );
    expect(detectPayloadType(utf8.encode('hello zenoh')), PayloadType.text);
    expect(
      detectPayloadType(_bytes([0x00, 0xC3, 0x28, 0xFF, 0xFE, 0x80])),
      PayloadType.binary,
    );
  });

  test('message encodings win over the bytes', () {
    final jpegLike = _bytes([0xFF, 0xD8, 0xFF, 0xE0]);
    expect(
      detectPayloadType(
        jpegLike,
        encoding: 'application/protobuf;ros2/sensor_msgs/CompressedImage',
      ),
      PayloadType.protobuf,
    );
    expect(
      detectPayloadType(
        utf8.encode('{"x": 1}'),
        encoding: 'application/flatbuffers;ros2/sensor_msgs/Temperature',
      ),
      PayloadType.flatbuffers,
    );
    expect(
      detectPayloadType(utf8.encode('not a jpeg'), encoding: 'image/jpeg'),
      PayloadType.imageJpeg,
    );
  });

  test('messageSchemaOf reads the schema suffix', () {
    expect(
      messageSchemaOf('application/protobuf;ros2/sensor_msgs/Imu'),
      'ros2/sensor_msgs/Imu',
    );
    expect(
      messageSchemaOf('application/flatbuffers; sensor_msgs.Temperature '),
      'sensor_msgs.Temperature',
    );
    expect(messageSchemaOf('application/protobuf'), isNull);
    expect(messageSchemaOf('application/json;schema'), isNull);
    expect(messageSchemaOf(null), isNull);
  });

  test('RateCounter counts ticks in a 1 s sliding window', () {
    final t0 = DateTime(2026, 1, 1, 12);
    final rate = RateCounter();
    for (var i = 0; i < 10; i++) {
      rate.tick(t0);
    }
    expect(rate.hz(t0), 10);
    expect(rate.total, 10);
    expect(rate.hz(t0.add(const Duration(milliseconds: 1500))), 0);
  });
}
