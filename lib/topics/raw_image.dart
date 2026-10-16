/// Raw-pixel images, as carried by a `ros2/sensor_msgs/Image`: checking a
/// frame, converting it to RGBA8888 and turning it into a [ui.Image] that
/// a `RawImage` widget draws.
///
/// The protobuf decoder (proto_decoder.dart) fills
/// `DecodedMessage.rawImage` with a [RawImageFrame]; `rawImageOf`
/// (message_decoder.dart) reads it from a payload. JPEG and PNG images go
/// the other way, through `imageBytesOf` and `Image.memory`.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

/// The `sensor_msgs/Image` encodings the app draws, by their name in ROS's
/// `sensor_msgs/image_encodings.hpp`.
enum RawPixelEncoding {
  mono8(1),
  mono16(2),
  rgb8(3),
  bgr8(3),
  rgba8(4),
  bgra8(4);

  const RawPixelEncoding(this.bytesPerPixel);

  final int bytesPerPixel;

  static final Map<String, RawPixelEncoding> _byName = values.asNameMap();

  /// The encoding named [name] (`mono8`, `rgb8`, ...; case and surrounding
  /// spaces are ignored), or null when it is not one of these.
  static RawPixelEncoding? lookup(String name) =>
      _byName[name.trim().toLowerCase()];
}

/// One uncompressed image: the fields of a `sensor_msgs/Image` that say how
/// to read its pixels.
class RawImageFrame {
  RawImageFrame({
    required this.width,
    required this.height,
    required this.encoding,
    required this.step,
    required this.bigEndian,
    required this.data,
  });

  /// Columns.
  final int width;

  /// Rows.
  final int height;

  /// The message's `encoding` string, as sent.
  final String encoding;

  /// Bytes per row in [data]; at least `width * bytesPerPixel`, more when
  /// rows are padded.
  final int step;

  /// The message's `is_bigendian`; only matters for `mono16`.
  final bool bigEndian;

  /// The pixels, row after row, [step] bytes each.
  final Uint8List data;

  /// [encoding] when it is one the app draws.
  late final RawPixelEncoding? pixelEncoding = RawPixelEncoding.lookup(
    encoding,
  );

  /// Why this frame cannot be drawn (e.g. `data is 1000 bytes, less than
  /// step × height = 327680`), or null when it can.
  late final String? problem = _check();

  /// True when the frame can be converted ([problem] is null).
  bool get isDrawable => problem == null;

  /// `640x512 mono8`.
  String get label => '${width}x$height ${encoding.isEmpty ? '?' : encoding}';

  String? _check() {
    final format = pixelEncoding;
    if (format == null) {
      return encoding.isEmpty
          ? 'no encoding'
          : 'unsupported encoding "$encoding"';
    }
    if (width <= 0 || height <= 0) return 'empty image (${width}x$height)';
    final bpp = format.bytesPerPixel;
    // Integer division, so absurd uint32 sizes cannot overflow.
    if (step ~/ bpp < width) {
      return 'step $step is less than width × $bpp = ${width * bpp}';
    }
    if (data.length ~/ height < step) {
      final need = BigInt.from(step) * BigInt.from(height);
      return 'data is ${data.length} bytes, less than step × height = $need';
    }
    return null;
  }
}

/// A reusable output buffer for [rawImageToRgba]: a stream of frames of one
/// size reuses one allocation instead of allocating per frame.
///
/// Use one per stream that decodes one frame at a time; the bytes are
/// overwritten by the next conversion.
class RgbaBuffer {
  Uint8List? _bytes;

  /// A buffer of exactly [length] bytes, the previous one when it fits.
  Uint8List take(int length) {
    final bytes = _bytes;
    if (bytes != null && bytes.length == length) return bytes;
    return _bytes = Uint8List(length);
  }

  /// Drops the buffer.
  void release() => _bytes = null;
}

/// Converts [frame] to tightly packed RGBA8888 (`width * height * 4` bytes,
/// rows of `width * 4`), into [into] when given.
///
/// `mono8` becomes grey, `rgb8`/`bgr8`/`rgba8`/`bgra8` are reordered into
/// RGBA, and `mono16` is stretched to 8 bits between the frame's own
/// darkest and brightest pixel (best effort; byte order from
/// [RawImageFrame.bigEndian]). Alpha is always opaque: like
/// `rqt_image_view`, the source alpha of `rgba8`/`bgra8` is ignored. Row
/// padding (a [RawImageFrame.step] beyond `width * bytesPerPixel`) is
/// skipped.
///
/// Throws [ArgumentError] when the frame is not [RawImageFrame.isDrawable].
Uint8List rawImageToRgba(RawImageFrame frame, {RgbaBuffer? into}) {
  final problem = frame.problem;
  if (problem != null) throw ArgumentError(problem, 'frame');
  final w = frame.width;
  final h = frame.height;
  final step = frame.step;
  final src = frame.data;
  final out = into?.take(w * h * 4) ?? Uint8List(w * h * 4);
  // One 32-bit store per pixel, in host byte order, so the bytes land in
  // memory as R, G, B, A. [out] starts at offset 0 of its own buffer.
  final px = out.buffer.asUint32List(out.offsetInBytes, w * h);
  final little = Endian.host == Endian.little;
  final rShift = little ? 0 : 24;
  final gShift = little ? 8 : 16;
  final bShift = little ? 16 : 8;
  final opaque = 0xFF << (little ? 24 : 0);
  final grey = little ? 0x010101 : 0x01010100; // v * grey sets R, G and B

  var o = 0;
  switch (frame.pixelEncoding!) {
    case RawPixelEncoding.mono8:
      for (var y = 0; y < h; y++) {
        final row = y * step;
        final end = row + w;
        for (var s = row; s < end; s++) {
          px[o++] = opaque | src[s] * grey;
        }
      }
    case RawPixelEncoding.rgb8:
    case RawPixelEncoding.bgr8:
    case RawPixelEncoding.rgba8:
    case RawPixelEncoding.bgra8:
      final format = frame.pixelEncoding!;
      final bpp = format.bytesPerPixel;
      final bgr =
          format == RawPixelEncoding.bgr8 || format == RawPixelEncoding.bgra8;
      // Shift for the first and third byte of each source pixel.
      final firstShift = bgr ? bShift : rShift;
      final thirdShift = bgr ? rShift : bShift;
      for (var y = 0; y < h; y++) {
        final row = y * step;
        final end = row + w * bpp;
        for (var s = row; s < end; s += bpp) {
          px[o++] =
              opaque |
              src[s] << firstShift |
              src[s + 1] << gShift |
              src[s + 2] << thirdShift;
        }
      }
    case RawPixelEncoding.mono16:
      final hiFirst = frame.bigEndian;
      var lo = 0xFFFF;
      var hi = 0;
      for (var y = 0; y < h; y++) {
        final row = y * step;
        final end = row + w * 2;
        for (var s = row; s < end; s += 2) {
          final v = hiFirst
              ? src[s] << 8 | src[s + 1]
              : src[s + 1] << 8 | src[s];
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
      final range = hi - lo;
      // Fixed point: ((v - lo) * scale) >> 16 maps lo..hi onto 0..255. A
      // flat frame keeps its absolute level instead.
      final scale = range == 0 ? 0 : (255 << 16) ~/ range;
      for (var y = 0; y < h; y++) {
        final row = y * step;
        final end = row + w * 2;
        for (var s = row; s < end; s += 2) {
          final v = hiFirst
              ? src[s] << 8 | src[s + 1]
              : src[s + 1] << 8 | src[s];
          final g = range == 0 ? v >> 8 : ((v - lo) * scale) >> 16;
          px[o++] = opaque | g * grey;
        }
      }
  }
  return out;
}

/// Converts [frame] ([rawImageToRgba], into [scratch] when given) and makes
/// a [ui.Image] of it. The caller owns the image and must dispose it.
///
/// The conversion runs on the calling isolate, before this returns its
/// future; making the image is asynchronous (engine side). The engine has
/// copied the pixels by then too, so [scratch] is free for the next frame as
/// soon as this returns. Completes with an [ArgumentError] for a frame that
/// is not drawable, and with whatever the engine throws.
Future<ui.Image> decodeRawImage(
  RawImageFrame frame, {
  RgbaBuffer? scratch,
}) async {
  final pixels = rawImageToRgba(frame, into: scratch);
  // ImmutableBuffer copies [pixels] inside this call, before the await.
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: frame.width,
      height: frame.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    codec = await descriptor.instantiateCodec();
    return (await codec.getNextFrame()).image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
