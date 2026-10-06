import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/guarded_save.dart';
import '../../providers/challan_providers.dart';

/// Runs a challan write, shows its error if it fails, and refreshes
/// everything that shows challans if it succeeds. Returns whether it worked.
Future<bool> runChallanAction(
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final succeeded = await runGuardedAction(action);
  if (succeeded) ref.read(challansRevisionProvider.notifier).bump();
  return succeeded;
}
