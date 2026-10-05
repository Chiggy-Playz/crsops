import '../errors/app_exception.dart';
import 'app_snack_bar.dart';

/// One-line user feedback for failed mutations, shared by every write path.
/// Messages are translated AppExceptions, user-safe by construction — the
/// technical detail stays in the logs, never in the SnackBar.
void showErrorSnackBar(AppException error) => showAppSnackBar(error.message);
