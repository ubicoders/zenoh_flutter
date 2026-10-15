import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/log_entry.dart';
import 'package:zenoh_flutter/session/session_controller.dart';

/// Shows the session's system log, newest first.
Future<void> showSessionLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) =>
          _SessionLog(scrollController: scrollController),
    ),
  );
}

class _SessionLog extends StatelessWidget {
  const _SessionLog({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = SessionController.instance;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final logs = controller.logs;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Text('Session log', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text('${logs.length}', style: theme.textTheme.labelSmall),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('sessionLog.clear'),
                    onPressed: logs.isEmpty ? null : controller.clearLogs,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: logs.isEmpty ? 1 : logs.length,
                itemBuilder: (context, i) => logs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'No events yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : _LogLine(entry: logs[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final LogEntry entry;

  static String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${_time(entry.timestamp)}  ',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            TextSpan(
              text: entry.message,
              style: TextStyle(color: entry.isError ? scheme.error : null),
            ),
          ],
        ),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
