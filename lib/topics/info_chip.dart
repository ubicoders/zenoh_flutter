import 'package:flutter/material.dart';

/// A compact outlined label used for payload type, size and "PAUSED".
///
/// Lighter than [Chip] so it fits inside list rows and app bars.
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.emphasized = false});

  final String label;

  /// Primary-coloured outline and text (used for the payload type).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasized ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: emphasized ? scheme.primary : scheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontFamily: 'monospace',
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
