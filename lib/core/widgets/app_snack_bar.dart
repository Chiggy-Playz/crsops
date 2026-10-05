import 'package:flutter/material.dart';

/// The app-wide ScaffoldMessenger (given to MaterialApp), so snackbars can be
/// shown from code with no BuildContext, like the startup update check.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shows a one-line message, replacing any snackbar already on screen rather
/// than queueing behind it. Snackbars float by default (see the app theme).
void showAppSnackBar(
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBarWidget(
    SnackBar(content: Text(message), action: action, duration: duration),
  );
}

/// For snackbars with custom content (e.g. a live progress bar).
void showAppSnackBarWidget(SnackBar snackBar) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
