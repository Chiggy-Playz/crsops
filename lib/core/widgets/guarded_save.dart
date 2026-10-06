import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import 'error_snackbar.dart';

/// Shared write wrapper for dialogs and pages: saving-flag handling,
/// translated error feedback, and a success continuation — the shape every
/// `_save`/`_grant` repeats. Callers pass the repo call as [action] and
/// invalidate-plus-pop as [onSuccess]; both run only while mounted, so
/// call sites need no `mounted` checks of their own.
Future<void> runGuardedSave(
  BuildContext context, {
  required void Function(bool saving) setSaving,
  required Future<void> Function() action,
  required void Function() onSuccess,
}) async {
  setSaving(true);
  try {
    await action();
    if (context.mounted) onSuccess();
  } on AppException catch (e) {
    showErrorSnackBar(e);
  } finally {
    if (context.mounted) setSaving(false);
  }
}

/// The no-form counterpart of [runGuardedSave], for one-tap writes (archive,
/// delete, a switch): runs [action] and shows its error as a snackbar.
/// Returns whether it worked, so the caller can refresh on success.
Future<bool> runGuardedAction(Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on AppException catch (e) {
    showErrorSnackBar(e);
    return false;
  }
}
