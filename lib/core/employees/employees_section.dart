import 'package:flutter/material.dart';

import '../sections/app_section.dart';
import 'routes.dart' as routes;
import 'settings_routes.dart' as settings_routes;

final employeesSection = AppSection(
  label: 'Employees',
  icon: Icons.people_outline,
  selectedIcon: Icons.people,
  canAccess: (s) => s.isAdminOrAbove,
  pathPrefix: '/employees',
  homeLocation: const routes.EmployeesRoute().location,
  routes: routes.$appRoutes,
  settingsEntries: [
    SettingsEntry(
      icon: Icons.event_note_outlined,
      title: 'Event types',
      canSee: (s) => s.isSuperadmin,
      location: const settings_routes.EventTypesRoute().location,
    ),
  ],
  settingsRoutes: settings_routes.$appRoutes,
  roleGuards: {
    const settings_routes.EventTypesRoute().location: (s) => s.isSuperadmin,
  },
);
