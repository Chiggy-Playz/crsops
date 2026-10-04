import 'package:flutter/material.dart';

import '../../core/modules/module_names.dart';
import '../../core/sections/app_section.dart';
import 'routes.dart' as routes;
import 'settings_routes.dart' as settings_routes;

final attendanceSection = AppSection(
  label: 'Attendance',
  icon: Icons.event_available_outlined,
  selectedIcon: Icons.event_available,
  canAccess: (s) => s.hasModuleAccess(ModuleNames.attendance),
  pathPrefix: '/attendance',
  homeLocation: const routes.CalendarRoute().location,
  routes: routes.$appRoutes,
  settingsEntries: [
    SettingsEntry(
      icon: Icons.schedule_outlined,
      title: 'Shift defaults',
      canSee: (s) => s.isAdminOrAbove,
      open: (context) =>
          const settings_routes.ShiftDefaultsRoute().push(context),
    ),
    SettingsEntry(
      icon: Icons.label_outline,
      title: 'Status types',
      canSee: (s) => s.isAdminOrAbove,
      open: (context) => const settings_routes.StatusTypesRoute().push(context),
    ),
  ],
  settingsRoutes: settings_routes.$appRoutes,
  roleGuards: {
    const settings_routes.ShiftDefaultsRoute().location: (s) =>
        s.isAdminOrAbove,
    const settings_routes.StatusTypesRoute().location: (s) => s.isAdminOrAbove,
  },
);
