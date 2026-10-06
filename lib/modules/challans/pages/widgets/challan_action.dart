import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../providers/challan_providers.dart';

/// Runs a challan write, shows its error if it fails, and refreshes
/// everything that shows challans if it succeeds. Returns whether it worked.
Future<bool> runChallanAction(
  WidgetRef ref,
  Future<void> Function() action,
) async {
  try {
    await action();
    ref.read(challansRevisionProvider.notifier).bump();
    return true;
  } on AppException catch (e) {
    showErrorSnackBar(e);
    return false;
  }
}
