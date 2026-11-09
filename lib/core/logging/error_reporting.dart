import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_version.dart';

/// Where Sentry sends reports, set per build (`--dart-define SENTRY_DSN=…`).
/// Empty in local builds, which switches reporting off.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Database errors that are the user's doing, not a bug: a duplicate, no
/// permission, something still in use, a row that's gone, or one of our own
/// functions refusing with a message written for the user. Everything else
/// from the database (a bad type, a missing function, …) is a bug worth
/// hearing about.
const _expectedDatabaseCodes = {'23505', '23503', '42501', 'PGRST116', 'P0001'};

/// Starts Sentry (if this build has a DSN) around [appRunner], which Sentry
/// also uses to catch the errors Flutter and the zone would otherwise lose.
Future<void> runWithErrorReporting(FutureOr<void> Function() appRunner) async {
  if (_sentryDsn.isEmpty) {
    await appRunner();
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    // Names, emails and IPs stay out; only an id is attached (see
    // [watchSignedInUser]).
    options.sendDefaultPii = false;
    options.environment = appVersion.isEmpty ? 'development' : 'production';
    if (appVersion.isNotEmpty) options.release = 'crs-ops@$appVersion';
  }, appRunner: appRunner);
}

/// Tags every report with the signed-in user's id, so a report can be traced
/// to who hit it. Cleared on sign-out.
void watchSignedInUser(Stream<AuthState> authStateChanges) {
  authStateChanges.listen((state) {
    final id = state.session?.user.id;
    Sentry.configureScope(
      (scope) => scope.setUser(id == null ? null : SentryUser(id: id)),
    );
  });
}

/// Reports an error the app caught and turned into a friendly message.
/// Without this, Sentry would only ever see crashes. A no-op when Sentry
/// isn't running.
void reportHandledError(Object error, StackTrace stackTrace) {
  if (error is PostgrestException &&
      _expectedDatabaseCodes.contains(error.code)) {
    return;
  }
  unawaited(
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (error is PostgrestException) {
          scope.setTag('db_code', error.code ?? 'none');
        }
      },
    ),
  );
}
