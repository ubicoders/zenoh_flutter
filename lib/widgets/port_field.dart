import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenoh_flutter/session/session_settings.dart';

/// Digits-only port input. Reports -1 for empty text so validation rejects it.
class PortField extends StatelessWidget {
  const PortField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.allowAny = false,
    this.showError = true,
  });

  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  /// Allow 0 (= any free port).
  final bool allowAny;
  final bool showError;

  static int parse(String text) => int.tryParse(text.trim()) ?? -1;

  static String format(int port) => port < 0 ? '' : '$port';

  @override
  Widget build(BuildContext context) {
    final port = parse(controller.text);
    final valid = isValidPort(port, allowAny: allowAny);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: 'Port',
        isDense: true,
        border: const OutlineInputBorder(),
        suffixText: allowAny && port == 0 ? 'any' : null,
        errorText: showError && !valid
            ? (allowAny ? '0–65535' : '1–65535')
            : null,
      ),
      onChanged: (text) => onChanged(parse(text)),
    );
  }
}
