import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/session_settings.dart';
import 'package:zenoh_flutter/widgets/port_field.dart';

/// Protocol segment + host + port. Edits [endpoint] in place, then calls
/// [onChanged]. Pass a new [endpoint] object to reset the fields.
class EndpointEditor extends StatefulWidget {
  const EndpointEditor({
    super.key,
    required this.endpoint,
    required this.keyPrefix,
    required this.onChanged,
    this.optional = false,
    this.trailing,
  });

  final Endpoint endpoint;
  final String keyPrefix;
  final VoidCallback onChanged;

  /// When true an empty host is fine and hides field errors.
  final bool optional;
  final Widget? trailing;

  @override
  State<EndpointEditor> createState() => _EndpointEditorState();
}

class _EndpointEditorState extends State<EndpointEditor> {
  late final TextEditingController _host;
  late final TextEditingController _port;

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: widget.endpoint.host);
    _port = TextEditingController(text: PortField.format(widget.endpoint.port));
  }

  @override
  void didUpdateWidget(EndpointEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.endpoint, widget.endpoint)) {
      _host.text = widget.endpoint.host;
      _port.text = PortField.format(widget.endpoint.port);
    }
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _setProtocol(TransportProtocol protocol) {
    final e = widget.endpoint;
    e.protocol = protocol;
    e.port = protocol.defaultPort;
    _port.text = PortField.format(e.port);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.endpoint;
    final p = widget.keyPrefix;
    final showErrors = !(widget.optional && e.host.isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TransportProtocol>(
          key: Key('$p.protocol'),
          showSelectedIcon: false,
          segments: [
            for (final proto in TransportProtocol.values)
              ButtonSegment(value: proto, label: Text(proto.name)),
          ],
          selected: {e.protocol},
          onSelectionChanged: (s) => _setProtocol(s.first),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: Key('$p.host'),
                controller: _host,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Host',
                  hintText: widget.optional ? 'optional' : null,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  errorText: showErrors && e.host.isEmpty ? 'required' : null,
                ),
                onChanged: (v) {
                  e.host = v.trim();
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: PortField(
                key: Key('$p.port'),
                controller: _port,
                showError: showErrors,
                onChanged: (port) {
                  e.port = port;
                  widget.onChanged();
                },
              ),
            ),
            if (widget.trailing case final trailing?) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ],
    );
  }
}
