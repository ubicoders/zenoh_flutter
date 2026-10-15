/// Display formatting shared by the topics list and the viewer.
library;

/// `< 10` -> one decimal (`7.5`), otherwise an integer (`200`).
String formatHz(double hz) =>
    hz < 10 ? hz.toStringAsFixed(1) : hz.round().toString();

/// `34 B`, `7.2 KB`, `1.3 MB` (binary units). Values of 100 or more drop the
/// decimal (`512 KB`).
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${_short(bytes / kb)} KB';
  return '${_short(bytes / mb)} MB';
}

String _short(double v) =>
    v < 100 ? v.toStringAsFixed(1) : v.round().toString();

/// Local wall-clock time as `HH:mm:ss.SSS`.
String formatClock(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final ms = t.millisecond.toString().padLeft(3, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
}
