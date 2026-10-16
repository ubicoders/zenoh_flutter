/// The subscribers `sb io` generated for this module, as the swarmbotix io
/// screen (pages/sbio_page.dart) shows them.
///
/// [sbioTopics] mirrors the `subscribers:` map of `sb.module.yaml`; the
/// classes come from `lib/swarmbotix_io/subscribers/`, which
/// `sb io add sub` / `sb io update` generate. After adding a subscriber with
/// sb, add its line here (and its message to tools/gen_ros2_messages.sh and
/// the decoders if the type is new).
library;

import 'dart:typed_data';

import 'package:zenoh_flutter/swarmbotix_io/subscribers/cam.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/chatter.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/cube_poses.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/debug_image.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/image.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/imu.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/markers.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/raw.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/relay_debug_image.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/relay_image.dart';
import 'package:zenoh_flutter/swarmbotix_io/subscribers/temperature.dart';
import 'package:zenoh_flutter/zenoh_flutter.dart';

/// An entry's `encoding:` in sb.module.yaml, with the zenoh encoding prefix
/// sb publishers stamp for it (sbcli_pubsub.md §14.3).
enum SbEncoding {
  proto('application/protobuf'),
  fb('application/flatbuffers');

  const SbEncoding(this.mime);

  final String mime;
}

/// One opened generated subscriber. The generated classes share no
/// interface, so each [SbioTopic.open] wraps its own in this.
class SbioReceiver {
  const SbioReceiver({required this.tryRecvLatest, required this.close});

  /// The generated `tryRecvLatest()`: the newest payload since the last
  /// call, or null.
  final Uint8List? Function() tryRecvLatest;

  /// The generated `close()`: undeclares the subscriber.
  final Future<void> Function() close;
}

/// One `subscribers:` entry of sb.module.yaml.
class SbioTopic {
  const SbioTopic({
    required this.name,
    required this.keyExpr,
    required this.type,
    required this.encoding,
    required this.open,
  });

  /// Entry name; also the generated file's name.
  final String name;

  /// The wire key, from the generated `<Name>Topic` constant.
  final String keyExpr;

  /// Vault message type, `<style>/<ns>/<Leaf>`.
  final String type;

  final SbEncoding encoding;

  /// Declares the generated subscriber on [Session].
  final Future<SbioReceiver> Function(Session session) open;

  /// The zenoh encoding the sb publisher of this key stamps, e.g.
  /// `application/protobuf;ros2/sensor_msgs/Imu`. The generated Dart
  /// subscriber returns bare bytes, so the screen decodes with this.
  String get wireTag => '${encoding.mime};$type';
}

final List<SbioTopic> sbioTopics = List.unmodifiable([
  SbioTopic(
    name: 'imu',
    keyExpr: ImuTopic,
    type: 'ros2/sensor_msgs/Imu',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await ImuSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'temperature',
    keyExpr: TemperatureTopic,
    type: 'ros2/sensor_msgs/Temperature',
    encoding: SbEncoding.fb,
    open: (session) async {
      final sub = await TemperatureSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'chatter',
    keyExpr: ChatterTopic,
    type: 'ros2/std_msgs/String',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await ChatterSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'cam',
    keyExpr: CamTopic,
    type: 'ros2/sensor_msgs/CompressedImage',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await CamSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'raw',
    keyExpr: RawTopic,
    type: 'ros2/std_msgs/UInt8MultiArray',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await RawSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'markers',
    keyExpr: MarkersTopic,
    type: 'ros2/custom/MarkerDetections',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await MarkersSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'cube_poses',
    keyExpr: CubePosesTopic,
    type: 'ros2/custom/CubePoses',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await CubePosesSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  // The test publisher's raw frames: mono8 and rgb8, 640x512.
  SbioTopic(
    name: 'image',
    keyExpr: ImageTopic,
    type: 'ros2/sensor_msgs/Image',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await ImageSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'debug_image',
    keyExpr: DebugImageTopic,
    type: 'ros2/sensor_msgs/Image',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await DebugImageSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  // The ws-ips image relay, instance sb00 (sb01..sb03 are opened from
  // Topics). Nothing arrives until the relay runs; the card waits.
  SbioTopic(
    name: 'relay_image',
    keyExpr: RelayImageTopic,
    type: 'ros2/sensor_msgs/Image',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await RelayImageSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
  SbioTopic(
    name: 'relay_debug_image',
    keyExpr: RelayDebugImageTopic,
    type: 'ros2/sensor_msgs/Image',
    encoding: SbEncoding.proto,
    open: (session) async {
      final sub = await RelayDebugImageSubscriber.open(session);
      return SbioReceiver(tryRecvLatest: sub.tryRecvLatest, close: sub.close);
    },
  ),
]);
