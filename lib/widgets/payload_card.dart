import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenoh_flutter/topics/format.dart';
import 'package:zenoh_flutter/topics/info_chip.dart';
import 'package:zenoh_flutter/topics/message_decoder.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/raw_image.dart';

/// Renders one payload according to its [PayloadType].
///
/// Long-press copies the raw payload (UTF-8 for text/json, the decoded
/// fields as JSON for protobuf and FlatBuffers, hex otherwise).
class PayloadCard extends StatelessWidget {
  const PayloadCard({
    super.key,
    required this.bytes,
    required this.type,
    this.encoding,
    this.paused = false,
    this.decodedImage,
    this.externalDecode = false,
    this.decodeFailed = false,
  });

  final Uint8List bytes;
  final PayloadType type;

  /// The zenoh encoding of [bytes]. For [PayloadType.protobuf] and
  /// [PayloadType.flatbuffers] its schema suffix
  /// (`application/flatbuffers;ros2/sensor_msgs/Temperature`) picks the
  /// message type.
  final String? encoding;

  /// Shows a "PAUSED" chip in the top-right corner.
  final bool paused;

  /// Image types: a frame the caller already decoded (e.g. off the UI
  /// thread for large images). Painted instead of decoding the image bytes
  /// ([imageBytesOf]). The caller owns it and disposes it.
  ///
  /// A message holding raw pixels (a `sensor_msgs/Image`, [rawImageOf]) is
  /// drawn from this alone: the caller converts it ([decodeRawImage]), this
  /// card never does, and shows a spinner until it is set.
  final ui.Image? decodedImage;

  /// Image types only: the caller decodes the image bytes ([imageBytesOf])
  /// itself, so this card never does. Until [decodedImage] is set a spinner
  /// (or, with [decodeFailed], an error) is shown.
  final bool externalDecode;

  /// Image types with [externalDecode], and raw-pixel messages: decoding
  /// failed.
  final bool decodeFailed;

  /// Text and JSON longer than this are truncated on screen (not on copy).
  static const int maxDisplayChars = 64 * 1024;

  /// Bytes shown in the binary hex dump.
  static const int hexPreviewBytes = 64;

  // Memoised per payload object so periodic rebuilds don't re-format.
  static final Expando<String> _jsonCache = Expando('payloadJson');
  static final Expando<String> _textCache = Expando('payloadText');
  static final Expando<String> _hexCache = Expando('payloadHex');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.6;
    return GestureDetector(
      onLongPress: () => _copy(context),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _body(context, maxBodyHeight),
            ),
            if (paused)
              Positioned(
                top: 8,
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const InfoChip('PAUSED', emphasized: true),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, double maxHeight) {
    switch (type) {
      case PayloadType.json:
        return _JsonBody(
          text: _jsonCache[bytes] ??= _prettyJson(bytes),
          maxHeight: maxHeight,
        );
      case PayloadType.text:
        return _TextBody(
          text: _textCache[bytes] ??= utf8.decode(bytes, allowMalformed: true),
          maxHeight: maxHeight,
        );
      case PayloadType.imageJpeg:
      case PayloadType.imagePng:
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Center(heightFactor: 1, child: _image(context, bytes)),
        );
      case PayloadType.protobuf:
      case PayloadType.flatbuffers:
        return _messageBody(context, maxHeight);
      case PayloadType.binary:
        return _HexBody(
          bytes: bytes,
          hex: _hexCache[bytes] ??= _hexDump(bytes),
        );
    }
  }

  /// A protobuf or FlatBuffers message: its schema, then the fields as
  /// JSON, then the image or hex dump of its bytes field (if any), or the
  /// uncompressed image the message is. Falls back to a hex dump of the raw
  /// payload when the message type is unknown or the bytes are bad.
  Widget _messageBody(BuildContext context, double maxHeight) {
    final theme = Theme.of(context);
    final schema = messageSchemaOf(encoding);
    final decoded = decodeMessage(bytes, type, encoding);
    if (decoded == null) {
      final String problem;
      if (schema == null) {
        problem = 'no message type in encoding ${encoding ?? '(none)'}';
      } else if (isKnownMessage(type, schema)) {
        problem = 'cannot decode $schema';
      } else {
        problem = 'unknown message $schema';
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          _HexBody(bytes: bytes, hex: _hexCache[bytes] ??= _hexDump(bytes)),
        ],
      );
    }

    final blob = decoded.blob;
    final field = decoded.blobField;
    final raw = decoded.rawImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            InfoChip(decoded.schema, emphasized: true),
            if (raw != null) InfoChip(raw.label),
            if (blob != null && field != null)
              InfoChip('$field · ${formatBytes(blob.length)}'),
          ],
        ),
        const SizedBox(height: 8),
        if (raw != null) ...[
          _JsonBody(text: decoded.fieldsJson, maxHeight: maxHeight * 0.3),
          const SizedBox(height: 8),
          if (raw.problem case final problem?)
            _errorLine(context, 'cannot draw image: $problem')
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Center(heightFactor: 1, child: _rawImage(context, raw)),
            ),
        ] else if (blob != null && decoded.hasImage) ...[
          _JsonBody(text: decoded.fieldsJson, maxHeight: maxHeight * 0.3),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Center(heightFactor: 1, child: _image(context, blob)),
          ),
        ] else if (blob != null) ...[
          _JsonBody(text: decoded.fieldsJson, maxHeight: maxHeight * 0.5),
          const SizedBox(height: 8),
          _HexBody(bytes: blob, hex: _hexCache[blob] ??= _hexDump(blob)),
        ] else
          _JsonBody(text: decoded.fieldsJson, maxHeight: maxHeight),
      ],
    );
  }

  /// Draws the encoded image [data]: [bytes] for the image types, the
  /// message's bytes field for protobuf and FlatBuffers.
  Widget _image(BuildContext context, Uint8List data) {
    final image = decodedImage;
    if (image != null) {
      return RawImage(image: image, fit: BoxFit.contain);
    }
    if (externalDecode) {
      return decodeFailed
          ? _imageError(context, data)
          : const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
    }
    return Image.memory(
      data,
      gaplessPlayback: true,
      fit: BoxFit.contain,
      errorBuilder: (context, _, _) => _imageError(context, data),
    );
  }

  /// Draws the uncompressed image [frame] from [decodedImage], which the
  /// caller makes from it.
  Widget _rawImage(BuildContext context, RawImageFrame frame) {
    final image = decodedImage;
    if (image != null) {
      return RawImage(image: image, fit: BoxFit.contain);
    }
    if (decodeFailed) {
      return _errorLine(context, 'cannot draw image (${frame.label})');
    }
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _imageError(BuildContext context, Uint8List data) =>
      _errorLine(context, 'cannot decode image (${data.length} bytes)');

  Widget _errorLine(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final text = switch (type) {
      PayloadType.json ||
      PayloadType.text => utf8.decode(bytes, allowMalformed: true),
      PayloadType.protobuf || PayloadType.flatbuffers =>
        decodeMessage(bytes, type, encoding)?.fieldsJson ?? _hex(bytes),
      _ => _hex(bytes),
    };
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
      );
  }

  static String _prettyJson(Uint8List bytes) {
    final raw = utf8.decode(bytes, allowMalformed: true);
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _hex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// 16 bytes per row: `0000  48 65 6c ...  6f 00  |Hel...o.|`.
  static String _hexDump(Uint8List bytes) {
    final n = math.min(bytes.length, hexPreviewBytes);
    final sb = StringBuffer();
    for (var row = 0; row < n; row += 16) {
      if (row > 0) sb.writeln();
      sb.write(row.toRadixString(16).padLeft(4, '0'));
      sb.write('  ');
      final ascii = StringBuffer();
      for (var i = row; i < row + 16; i++) {
        if (i == row + 8) sb.write(' ');
        if (i < n) {
          final b = bytes[i];
          sb.write(b.toRadixString(16).padLeft(2, '0'));
          sb.write(' ');
          ascii.writeCharCode(b >= 0x20 && b < 0x7F ? b : 0x2E);
        } else {
          sb.write('   ');
        }
      }
      sb.write(' |$ascii|');
    }
    return sb.toString();
  }
}

String _clip(String text) {
  if (text.length <= PayloadCard.maxDisplayChars) return text;
  final rest = text.length - PayloadCard.maxDisplayChars;
  return '${text.substring(0, PayloadCard.maxDisplayChars)}\n… ($rest more characters, long-press to copy all)';
}

TextStyle? _monoStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.35,
      color: Theme.of(context).colorScheme.onSurface,
    );

class _JsonBody extends StatelessWidget {
  const _JsonBody({required this.text, required this.maxHeight});

  final String text;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        primary: false,
        child: SingleChildScrollView(
          primary: false,
          scrollDirection: Axis.horizontal,
          child: Text(_clip(text), softWrap: false, style: _monoStyle(context)),
        ),
      ),
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.text, required this.maxHeight});

  final String text;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.isEmpty) {
      return Text(
        '(empty payload)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        primary: false,
        child: SizedBox(
          width: double.infinity,
          child: SelectableText(
            _clip(text),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexBody extends StatelessWidget {
  const _HexBody({required this.bytes, required this.hex});

  final Uint8List bytes;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = bytes.length;
    final header = n > PayloadCard.hexPreviewBytes
        ? '$n bytes · first ${PayloadCard.hexPreviewBytes} bytes'
        : '$n bytes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          primary: false,
          scrollDirection: Axis.horizontal,
          child: Text(hex, softWrap: false, style: _monoStyle(context)),
        ),
      ],
    );
  }
}
