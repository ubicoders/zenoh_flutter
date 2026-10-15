/// One system event in the session log.
class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.message,
    this.isError = false,
  });

  final DateTime timestamp;
  final String message;
  final bool isError;
}
