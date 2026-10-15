import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/fbs/demo_zenoh_demo_generated.dart' as fbs;
import 'package:zenoh_flutter/topics/decoded_message.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';

const _imuEncoding = 'application/flatbuffers;zenoh_demo.Imu';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

DecodedMessage? _decodeImu(Uint8List bytes) =>
    decodeMessage(bytes, PayloadType.flatbuffers, _imuEncoding);

void main() {
  test('decodes an Imu serialised by Python', () {
    // tools/demo_generated.py: header(timestamp_ns=1700000000000000000,
    // seq=7), accel(1.5, -2.25, 9.806), gyro(0.001, 0.002, -0.003), temp 36.4.
    final bytes = _hex(
      '14000000000000000c004c003c0024000c0004000c000000'
      '3333333333334240fca9f1d24d62503ffca9f1d24d62603ffa7e6abc749368bf'
      '000000000000f83f00000000000002c0e9263108ac9c2340'
      '00002a36fe9c97170700000000000000',
    );
    final decoded = _decodeImu(bytes)!;
    expect(decoded.blob, isNull);
    expect(jsonDecode(decoded.fieldsJson), {
      'header': {'timestampNs': 1700000000000000000, 'seq': 7},
      'accel': {'x': 1.5, 'y': -2.25, 'z': 9.806},
      'gyro': {'x': 0.001, 'y': 0.002, 'z': -0.003},
      'temp': 36.4,
    });
  });

  test('unknown schemas and garbage bytes give null, never throw', () {
    expect(
      decodeMessage(
        Uint8List(16),
        PayloadType.flatbuffers,
        'application/flatbuffers;zenoh_demo.Nope',
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
      expect(() => _decodeImu(bytes), returnsNormally);
      expect(_decodeImu(bytes), isNull);
    }
    // Truncations and random corruptions of a valid buffer never throw.
    final random = math.Random(42);
    final imu = fbs.ImuObjectBuilder(
      header: fbs.HeaderObjectBuilder(timestampNs: 1, seq: 2),
      accel: fbs.Vector3ObjectBuilder(x: 1, y: 2, z: 3),
      temp: 36.4,
    ).toBytes();
    for (var n = 0; n < imu.length; n++) {
      expect(
        () => _decodeImu(Uint8List.sublistView(imu, 0, n)),
        returnsNormally,
      );
    }
    for (var i = 0; i < 500; i++) {
      final corrupt = Uint8List.fromList(imu);
      corrupt[random.nextInt(corrupt.length)] = random.nextInt(256);
      expect(() => _decodeImu(corrupt), returnsNormally);
    }
  });
}
