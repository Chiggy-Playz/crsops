import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/attendance/routes.dart';
import '../../modules/settings/routes.dart';
import '../auth/models/app_session.dart';
import '../employees/routes.dart';

const signInPath = '/sign-in';
const unauthorizedPath = '/unauthorized';
const loadingPath = '/loading';

/// Module id as seeded in `core.modules`. Kept as a named constant (not a
/// literal at the call site) so a rename fails loudly in one place; future
/// modules (challan, asset) add theirs here. This is the *module registry*
/// id, not the Postgres schema name — repositories' `.schema('attendance')`
/// calls are a separate concept and stay as-is inside their own module.
const attendanceModuleId = 'attendance';

/// Locations that previously carried their own per-route superadmin guard.
/// Moved here during the typed-routes migration (generated redirect has no
/// Ref). Derived from the route classes' own locations, so the path strings
/// below exist in exactly one place — the `@TypedGoRoute(path:)` annotations.
/// Semantics preserved exactly: failures bounce to /unauthorized, which the
/// auth-page block below then bounces to '/' for signed-in users.
final _superadminPaths = {
  const AllowListRoute().location,
  const RolesRoute().location,
  const EventTypesRoute().location,
};

/// Same story as [_superadminPaths], for the admin-or-above guard.
final _adminPaths = {
  const ModuleAccessRoute().location,
  const ShiftDefaultsRoute().location,
  const StatusTypesRoute().location,
};

String? computeRedirect({
  required AsyncValue<AppSession?> sessionValue,
  required String currentLocation,
}) {
  if (sessionValue.isLoading) {
    return currentLocation == loadingPath ? null : loadingPath;
  }

  if (sessionValue.hasError) {
    return currentLocation == signInPath ? null : signInPath;
  }

  final session = sessionValue.value;

  if (session == null) {
    return currentLocation == signInPath ? null : signInPath;
  }

  if (session.role == null) {
    return currentLocation == unauthorizedPath ? null : unauthorizedPath;
  }

  if (_superadminPaths.contains(currentLocation)) {
    return session.isSuperadmin ? null : unauthorizedPath;
  }
  if (_adminPaths.contains(currentLocation)) {
    return session.isAdminOrAbove ? null : unauthorizedPath;
  }
  if (currentLocation == const CalendarRoute().location) {
    return session.hasModuleAccess(attendanceModuleId)
        ? null
        : unauthorizedPath;
  }

  if (currentLocation == signInPath ||
      currentLocation == unauthorizedPath ||
      currentLocation == loadingPath) {
    return '/';
  }

  return null;
}
