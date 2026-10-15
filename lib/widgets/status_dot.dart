import 'package:flutter/material.dart';
import 'package:zenoh_flutter/session/session_controller.dart';

/// Small round session-state indicator.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.state, this.size = 8});

  final SessionState state;
  final double size;

  static Color colorFor(SessionState state, ColorScheme scheme) =>
      switch (state) {
        SessionState.connected => Colors.green,
        SessionState.error => scheme.error,
        _ => scheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorFor(state, Theme.of(context).colorScheme),
        shape: BoxShape.circle,
      ),
    );
  }
}
