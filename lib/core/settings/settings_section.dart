import 'package:flutter/material.dart';

import '../sections/app_section.dart';
import 'routes.dart';

final settingsSection = AppSection(
  label: 'Settings',
  icon: Icons.settings_outlined,
  selectedIcon: Icons.settings,
  canAccess: (_) => true,
  pathPrefix: '/settings',
  homeLocation: const SettingsRoute().location,
  routes: $appRoutes,
  isLandingCandidate: false,
  settingsGroupTitle: 'Access',
  settingsEntries: [
    SettingsEntry(
      icon: Icons.mail_outline,
      title: 'Signup allow-list',
      canSee: (s) => s.isSuperadmin,
      open: (context) => const AllowListRoute().push(context),
    ),
    SettingsEntry(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Roles',
      canSee: (s) => s.isSuperadmin,
      open: (context) => const RolesRoute().push(context),
    ),
    SettingsEntry(
      icon: Icons.apps_outlined,
      title: 'Module access',
      canSee: (s) => s.isAdminOrAbove,
      open: (context) => const ModuleAccessRoute().push(context),
    ),
  ],
  roleGuards: {
    const AllowListRoute().location: (s) => s.isSuperadmin,
    const RolesRoute().location: (s) => s.isSuperadmin,
    const ModuleAccessRoute().location: (s) => s.isAdminOrAbove,
  },
);
