import 'package:flutter/material.dart';
import 'package:zenoh_flutter/topics/format.dart';

/// Three equal tiles: publish rate, draw rate and last payload size.
class RateMeter extends StatelessWidget {
  const RateMeter({
    super.key,
    required this.pubHz,
    required this.drawHz,
    required this.lastSize,
  });

  /// Samples received per second.
  final double pubHz;

  /// Samples put on screen per second.
  final double drawHz;

  /// Size in bytes of the payload on screen; null shows a dash.
  final int? lastSize;

  @override
  Widget build(BuildContext context) {
    final size = lastSize;
    return Row(
      children: [
        Expanded(
          child: _Tile(value: formatHz(pubHz), label: 'PUB HZ'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(value: formatHz(drawHz), label: 'DRAW HZ'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(
            value: size == null ? '—' : formatBytes(size),
            label: 'LAST',
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
