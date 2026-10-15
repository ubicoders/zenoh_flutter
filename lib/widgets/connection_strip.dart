import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/widgets/status_dot.dart';

/// AppBar bottom showing the session state. Tap to go back to Settings.
class ConnectionStrip extends StatelessWidget implements PreferredSizeWidget {
  const ConnectionStrip({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(28);

  @override
  Widget build(BuildContext context) {
    final controller = SessionController.instance;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('connectionStrip'),
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: SizedBox(
            height: preferredSize.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  StatusDot(state: controller.state),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.tune,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
