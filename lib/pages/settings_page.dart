import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/session/session_settings.dart';
import 'package:zenoh_flutter/widgets/endpoint_editor.dart';
import 'package:zenoh_flutter/widgets/listen_rows_editor.dart';
import 'package:zenoh_flutter/widgets/session_log_sheet.dart';
import 'package:zenoh_flutter/widgets/status_dot.dart';

/// Home route: pick a mode, fill in its form, open the session.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SessionController _controller = SessionController.instance;
  late final TextEditingController _scope;

  /// Backs the optional peer "Connect to" fields; becomes
  /// settings.peerConnect only while its host is non-empty.
  late Endpoint _peerDraft;
  Endpoint _routerDraft = _emptyEndpoint(TransportProtocol.tcp);

  String? _lanIp;
  bool _lanLoaded = false;
  bool _lanLoading = false;

  SessionSettings get _s => _controller.settings;

  static Endpoint _emptyEndpoint(TransportProtocol protocol) =>
      Endpoint(protocol: protocol, host: '', port: protocol.defaultPort);

  static bool get _scoutingMayBeBlocked =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _scope = TextEditingController(text: _s.discoveryScope);
    // Peer "Connect to" starts as tcp with an empty host unless one was saved.
    _peerDraft =
        _s.peerConnect?.nonEmptyOrNull ?? _emptyEndpoint(TransportProtocol.tcp);
    if (_s.mode == ZenohMode.router) _loadLanIp();
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _setMode(ZenohMode mode) {
    setState(() => _s.mode = mode);
    if (mode == ZenohMode.router) _loadLanIp();
  }

  void _peerConnectChanged() => setState(() {
    _s.peerConnect = _peerDraft.nonEmptyOrNull;
  });

  void _addRouter() => setState(() {
    final draft = _routerDraft;
    if (!_s.routerConnect.any((e) => e.locator == draft.locator)) {
      _s.routerConnect.add(draft.copy());
    }
    _routerDraft = _emptyEndpoint(draft.protocol);
  });

  Future<void> _loadLanIp() async {
    if (_lanLoading) return;
    _lanLoading = true;
    String? ip;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      ip = interfaces
          .expand((i) => i.addresses)
          .where((a) => !a.isLoopback)
          .firstOrNull
          ?.address;
    } catch (e) {
      _controller.log('Could not list network interfaces: $e', isError: true);
    }
    _lanLoading = false;
    if (!mounted) return;
    setState(() {
      _lanIp = ip;
      _lanLoaded = true;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await _controller.open();
    if (!mounted) return;
    if (_controller.state == SessionState.connected) {
      Navigator.pushNamed(context, '/topics');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            key: const Key('settings.log'),
            tooltip: 'Session log',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => showSessionLogSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ZenohMode>(
                key: const Key('settings.mode'),
                showSelectedIcon: false,
                segments: [
                  for (final m in ZenohMode.values)
                    ButtonSegment(value: m, label: Text(m.name)),
                ],
                selected: {_s.mode},
                onSelectionChanged: (s) => _setMode(s.first),
              ),
              const SizedBox(height: 8),
              Text(
                switch (_s.mode) {
                  ZenohMode.client =>
                    'Connects to one router or peer. Nothing listens on this device.',
                  ZenohMode.peer =>
                    'Joins a mesh. Finds others by multicast, or connect to a known router.',
                  ZenohMode.router =>
                    'This phone becomes the hub. Others connect to it.',
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...switch (_s.mode) {
                ZenohMode.client => _clientForm(),
                ZenohMode.peer => _peerForm(),
                ZenohMode.router => _routerForm(theme),
              },
              const SizedBox(height: 24),
              TextField(
                key: const Key('settings.discoveryScope'),
                controller: _scope,
                autocorrect: false,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Discovery scope',
                  helperText: 'Key expression the Topics page listens on',
                  border: const OutlineInputBorder(),
                  errorText: _s.discoveryScope.trim().isEmpty
                      ? 'required'
                      : null,
                ),
                onChanged: (v) => setState(() => _s.discoveryScope = v.trim()),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _submitArea(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _clientForm() => [
    _section('Connect to'),
    EndpointEditor(
      key: const ValueKey('client.connect'),
      keyPrefix: 'client.connect',
      endpoint: _s.clientConnect,
      onChanged: _changed,
    ),
  ];

  List<Widget> _peerForm() => [
    SwitchListTile(
      key: const Key('peer.scouting'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Multicast scouting'),
      value: _s.peerScouting,
      onChanged: (v) => setState(() => _s.peerScouting = v),
    ),
    if (_scoutingMayBeBlocked)
      _hint(
        'Blocked on the Android emulator and on iOS without an entitlement.',
        icon: Icons.warning_amber_rounded,
      ),
    ExpansionTile(
      key: const Key('peer.advanced'),
      title: const Text('Advanced'),
      subtitle: const Text('Known router address, listen endpoints'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      // Open by default only when a router address was already saved.
      initiallyExpanded: _s.peerConnect != null,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Connect to (optional)'),
        EndpointEditor(
          key: const ValueKey('peer.connect'),
          keyPrefix: 'peer.connect',
          endpoint: _peerDraft,
          optional: true,
          onChanged: _peerConnectChanged,
        ),
        _section('Listen on (optional, any combination)'),
        ListenRowsEditor(
          key: const ValueKey('peer.listen'),
          keyPrefix: 'peer.listen',
          rows: _s.peerListen,
          allowAnyPort: true,
          onChanged: _changed,
        ),
        const SizedBox(height: 8),
      ],
    ),
  ];

  List<Widget> _routerForm(ThemeData theme) => [
    _section('Listen on (any combination)'),
    ListenRowsEditor(
      key: const ValueKey('router.listen'),
      keyPrefix: 'router.listen',
      rows: _s.routerListen,
      onChanged: _changed,
    ),
    if (!_s.routerListen.any((r) => r.enabled))
      Text(
        'Enable at least one listener.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    const SizedBox(height: 8),
    _reachableAt(theme),
    const SizedBox(height: 8),
    SwitchListTile(
      key: const Key('router.scouting'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Multicast scouting'),
      subtitle: const Text('Announce on LAN'),
      value: _s.routerScouting,
      onChanged: (v) => setState(() => _s.routerScouting = v),
    ),
    _section('Connect to other routers (optional)'),
    for (final (i, e) in _s.routerConnect.indexed)
      ListTile(
        key: ValueKey('router.connect.$i'),
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(e.locator, style: const TextStyle(fontFamily: 'monospace')),
        trailing: IconButton(
          key: Key('router.connect.$i.delete'),
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _s.routerConnect.removeAt(i)),
        ),
      ),
    EndpointEditor(
      key: const ValueKey('router.connect.draft'),
      keyPrefix: 'router.connect.draft',
      endpoint: _routerDraft,
      optional: true,
      onChanged: _changed,
      trailing: IconButton.filledTonal(
        key: const Key('router.connect.add'),
        tooltip: 'Add router',
        icon: const Icon(Icons.add),
        onPressed: _routerDraft.isValid ? _addRouter : null,
      ),
    ),
  ];

  Widget _reachableAt(ThemeData theme) {
    final rows = _s.routerListen.where((r) => r.enabled && isValidPort(r.port));
    final ip = _lanIp;
    final lines = !_lanLoaded
        ? ['…']
        : ip == null
        ? ['no network']
        : [for (final r in rows) '${r.protocol.name}/$ip:${r.port}'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reachable on Wi-Fi at', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          for (final line in lines.isEmpty ? ['—'] : lines)
            SelectableText(
              line,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _submitArea(ThemeData theme) {
    final state = _controller.state;
    final busy = state == SessionState.connecting;
    final label = switch (_s.mode) {
      ZenohMode.client => 'Connect',
      ZenohMode.peer => 'Open session',
      ZenohMode.router => 'Start router',
    };
    final status = switch (state) {
      SessionState.disconnected => 'disconnected',
      SessionState.connecting => 'connecting…',
      SessionState.connected => _controller.summary,
      SessionState.error => _controller.errorText ?? 'error',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('settings.submit'),
          onPressed: _s.isValid && !busy ? _submit : null,
          child: Text(label),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: StatusDot(state: state),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                key: const Key('settings.status'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: state == SessionState.error
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (state == SessionState.connected || busy)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('settings.disconnect'),
                onPressed: _controller.close,
                child: const Text('Disconnect'),
              ),
              if (!busy)
                TextButton(
                  key: const Key('settings.topics'),
                  onPressed: () => Navigator.pushNamed(context, '/topics'),
                  child: const Text('Topics'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _hint(String text, {IconData? icon}) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
