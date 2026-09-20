import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

/// One-line user feedback for failed mutations, shared by every write path.
/// Messages are translated AppExceptions, user-safe by construction — the
/// technical detail stays in the logs, never in the SnackBar.
void showErrorSnackBar(BuildContext context, AppException error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.message)));
}
