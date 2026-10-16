import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/fbs/ros2/Header_std_msgs_generated.dart'
    as std_msgs;
import 'package:zenoh_flutter/fbs/ros2/Temperature_sensor_msgs_generated.dart'
    as sensor_msgs;
import 'package:zenoh_flutter/fbs/ros2/Time_builtin_interfaces_generated.dart'
    as builtin_interfaces;
import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';

const _temperatureEncoding =
    'application/flatbuffers;ros2/sensor_msgs/Temperature';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

DecodedMessage? _decodeTemperature(Uint8List bytes) =>
    decodeMessage(bytes, PayloadType.flatbuffers, _temperatureEncoding);

void main() {
  test('decodes a Temperature serialised by Python', () {
    // flatc --python from the same `flatc --proto` schema sb compiles:
    // header(stamp(sec=1700000000, nanosec=7), frame_id="thermo"),
    // temperature 36.4, variance 0.25.
    final bytes = _hex(
      '140000000000000000000a00180014000c0004000a000000'
      '000000000000d03f333333333333424004000000f4ffffff'
      '1c0000000c00000008000c0008000400080000000700000000f15365'
      '06000000746865726d6f0000',
    );
    final decoded = _decodeTemperature(bytes)!;
    expect(decoded.blob, isNull);
    final fields = {
      'header': {
        'stamp': {'sec': 1700000000, 'nanosec': 7},
        'frameId': 'thermo',
      },
      'temperature': 36.4,
      'variance': 0.25,
    };
    expect(jsonDecode(decoded.fieldsJson), fields);
    // The bare FlatBuffers name is accepted too.
    expect(
      jsonDecode(
        decodeMessage(
          bytes,
          PayloadType.flatbuffers,
          'application/flatbuffers;sensor_msgs.Temperature',
        )!.fieldsJson,
      ),
      fields,
    );
  });

  test('unknown schemas and garbage bytes give null, never throw', () {
    expect(
      decodeMessage(
        Uint8List(16),
        PayloadType.flatbuffers,
        'application/flatbuffers;ros2/sensor_msgs/Nope',
      ),
      isNull,
    );
    final rejected = [
      Uint8List(0),
      _hex('0c0000'),
      _hex('ff000000000000000000000000000000'), // root offset past the end
      utf8.encode('definitely not a flatbuffer'),
    ];
    for (final bytes in rejected) {
      expect(() => _decodeTemperature(bytes), returnsNormally);
      expect(_decodeTemperature(bytes), isNull);
    }
    // Truncations and random corruptions of a valid buffer never throw.
    final random = math.Random(42);
    final temperature = sensor_msgs.TemperatureObjectBuilder(
      header: std_msgs.HeaderObjectBuilder(
        stamp: builtin_interfaces.TimeObjectBuilder(sec: 1, nanosec: 2),
        frameId: 'thermo',
      ),
      temperature: 36.4,
    ).toBytes();
    for (var n = 0; n < temperature.length; n++) {
      expect(
        () => _decodeTemperature(Uint8List.sublistView(temperature, 0, n)),
        returnsNormally,
      );
    }
    for (var i = 0; i < 500; i++) {
      final corrupt = Uint8List.fromList(temperature);
      corrupt[random.nextInt(corrupt.length)] = random.nextInt(256);
      expect(() => _decodeTemperature(corrupt), returnsNormally);
    }
  });
}
