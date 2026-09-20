import 'package:flutter/material.dart';

/// Wraps [child] with a dimmed scrim + spinner and blocks input while [busy]
/// is true — used anywhere a page keeps its list visible during a write
/// instead of replacing it with a bare full-screen spinner.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.busy, required this.child});

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(absorbing: busy, child: child),
        if (busy)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
