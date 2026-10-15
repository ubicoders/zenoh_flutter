import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/session_settings.dart';
import 'package:zenoh_flutter/widgets/port_field.dart';

/// tcp/udp/ws listen rows: fixed 0.0.0.0 bind, a port and an on/off switch.
/// Edits [rows] in place, then calls [onChanged].
class ListenRowsEditor extends StatefulWidget {
  const ListenRowsEditor({
    super.key,
    required this.rows,
    required this.keyPrefix,
    required this.onChanged,
    this.allowAnyPort = false,
  });

  final List<ListenRow> rows;
  final String keyPrefix;
  final VoidCallback onChanged;

  /// Allow port 0 (= any free port).
  final bool allowAnyPort;

  @override
  State<ListenRowsEditor> createState() => _ListenRowsEditorState();
}

class _ListenRowsEditorState extends State<ListenRowsEditor> {
  late List<TextEditingController> _ports;

  @override
  void initState() {
    super.initState();
    _ports = _controllersFor(widget.rows);
  }

  @override
  void didUpdateWidget(ListenRowsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rows, widget.rows)) {
      _disposeControllers();
      _ports = _controllersFor(widget.rows);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  static List<TextEditingController> _controllersFor(List<ListenRow> rows) => [
    for (final r in rows) TextEditingController(text: PortField.format(r.port)),
  ];

  void _disposeControllers() {
    for (final c in _ports) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final clash = SessionSettings.wsClashesWithTcp(widget.rows);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.rows.length; i++)
          _row(widget.rows[i], _ports[i], mono, theme, clash),
      ],
    );
  }

  Widget _row(
    ListenRow row,
    TextEditingController port,
    TextStyle? mono,
    ThemeData theme,
    bool clash,
  ) {
    final key = '${widget.keyPrefix}.${row.protocol.name}';
    final showClash = clash && row.protocol == TransportProtocol.ws;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  row.protocol.name,
                  style: mono?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '0.0.0.0 :',
                style: mono?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: PortField(
                  key: Key('$key.port'),
                  controller: port,
                  allowAny: widget.allowAnyPort,
                  showError: row.enabled,
                  onChanged: (p) {
                    row.port = p;
                    widget.onChanged();
                  },
                ),
              ),
              const Spacer(),
              Switch(
                key: Key('$key.enabled'),
                value: row.enabled,
                onChanged: (v) {
                  row.enabled = v;
                  widget.onChanged();
                },
              ),
            ],
          ),
          if (showClash)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 2),
              child: Text(
                'same port as tcp',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
