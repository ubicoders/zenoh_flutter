import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/topics/format.dart';
import 'package:zenoh_flutter/topics/info_chip.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/topic_registry.dart';
import 'package:zenoh_flutter/widgets/connection_strip.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Lists every key expression seen on the discovery scope.
class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final _registry = TopicRegistry.instance;
  final _session = SessionController.instance;
  Timer? _ticker;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // The registry outlives this page; it stops itself when the session ends.
    unawaited(_registry.start());
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // Refresh Hz and staleness; skip while a viewer covers this page.
      if (mounted && _visible) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _promptKeyExpr() async {
    final keyExpr = await showDialog<String>(
      context: context,
      builder: (_) => const _KeyExprDialog(),
    );
    if (!mounted || keyExpr == null || keyExpr.isEmpty) return;
    await Navigator.pushNamed(context, '/view', arguments: keyExpr);
  }

  @override
  Widget build(BuildContext context) {
    // Also rebuilds this page when it becomes current again.
    _visible = ModalRoute.of(context)?.isCurrent ?? true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
        bottom: const ConnectionStrip(),
        actions: [
          IconButton(
            key: const Key('topics.sbio'),
            tooltip: 'swarmbotix io',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => Navigator.pushNamed(context, '/sbio'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_session, _registry]),
        builder: (context, _) => _session.state == SessionState.connected
            ? _buildTopics(context)
            : _NotConnected(state: _session.state, error: _session.errorText),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          if (_session.state != SessionState.connected) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                onPressed: _promptKeyExpr,
                icon: const Icon(Icons.add),
                label: const Text('Subscribe to a key expression…'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopics(BuildContext context) {
    final now = DateTime.now();
    final topics = _registry.topics;
    final scope = _registry.scope ?? _session.settings.discoveryScope;
    final active = _registry.running || _registry.starting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          scope: scope,
          count: topics.length,
          startedAt: _registry.running ? _registry.startedAt : null,
          starting: _registry.starting,
          now: now,
          onRetry: () => unawaited(_registry.start()),
        ),
        const Divider(height: 1),
        Expanded(
          child: topics.isEmpty
              ? _Waiting(scope: scope, active: active)
              : ListView.separated(
                  itemCount: topics.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _TopicRow(info: topics[i], now: now),
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scope,
    required this.count,
    required this.startedAt,
    required this.starting,
    required this.now,
    required this.onRetry,
  });

  final String scope;
  final int count;
  final DateTime? startedAt;
  final bool starting;
  final DateTime now;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: _tabular,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final started = startedAt;
    final topics = '$count topic${count == 1 ? '' : 's'}';
    final String text;
    if (started != null) {
      final secs = now.difference(started).inSeconds;
      text = 'Listening on $scope · $topics · $secs s';
    } else if (starting) {
      text = 'Starting discovery on $scope…';
    } else {
      text = 'Discovery stopped · $topics';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (started == null && !starting)
            TextButton(onPressed: onRetry, child: const Text('Restart')),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.info, required this.now});

  final TopicInfo info;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stale = info.isStale(now);
    final hz = info.rate.hz(now);
    final type = info.type;
    final mono = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: theme.colorScheme.onSurface,
    );
    return Opacity(
      opacity: stale ? 0.5 : 1,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/view', arguments: info.keyExpr),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(info.keyExpr, style: mono)),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 72),
                    child: Text(
                      stale ? '— Hz' : '${formatHz(hz)} Hz',
                      textAlign: TextAlign.right,
                      style: mono?.copyWith(fontFeatures: _tabular),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  InfoChip(
                    type == null ? '…' : payloadTypeLabel(type),
                    emphasized: true,
                  ),
                  InfoChip(formatBytes(info.lastSize)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.scope, required this.active});

  final String scope;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Waiting for samples on $scope…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.state, required this.error});

  final SessionState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connecting = state == SessionState.connecting;
    final err = state == SessionState.error ? error : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connecting)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(
                Icons.link_off,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: 12),
            Text(
              connecting ? 'Connecting…' : 'Not connected',
              style: theme.textTheme.titleMedium,
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back to settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyExprDialog extends StatefulWidget {
  const _KeyExprDialog();

  @override
  State<_KeyExprDialog> createState() => _KeyExprDialogState();
}

class _KeyExprDialogState extends State<_KeyExprDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final keyExpr = _controller.text.trim();
    if (keyExpr.isNotEmpty) Navigator.of(context).pop(keyExpr);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subscribe'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.go,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: const InputDecoration(
          labelText: 'Key expression',
          hintText: 'demo/example/**',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: const Text('Subscribe'),
          ),
        ),
      ],
    );
  }
}
