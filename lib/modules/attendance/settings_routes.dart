import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/shift_defaults_manager_page.dart';
import 'pages/status_types_manager_page.dart';

part 'settings_routes.g.dart';

// Attendance pages opened from the Settings hub. They live in the Settings
// branch of the nav shell, under /settings/attendance/, so opening one keeps
// the Settings tab selected instead of jumping to Attendance.

@TypedGoRoute<ShiftDefaultsRoute>(path: '/settings/attendance/shift-defaults')
class ShiftDefaultsRoute extends GoRouteData with $ShiftDefaultsRoute {
  const ShiftDefaultsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ShiftDefaultsManagerPage();
}

@TypedGoRoute<StatusTypesRoute>(path: '/settings/attendance/status-types')
class StatusTypesRoute extends GoRouteData with $StatusTypesRoute {
  const StatusTypesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StatusTypesManagerPage();
}
