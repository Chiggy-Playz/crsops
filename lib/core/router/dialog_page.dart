import 'package:flutter/material.dart';

/// Shows a routed page as a modal dialog, so forms with real URLs (new/edit
/// employee) look exactly like the forms opened with showDialog — full-screen
/// on phones, centred on wide screens (FormDialog decides) — while deep links
/// and the browser back button keep working.
class DialogPage<T> extends Page<T> {
  const DialogPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
    context: context,
    settings: this,
    // Same as showFormDialog: paint under the system bars.
    useSafeArea: false,
    builder: (_) => child,
  );
}
