import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/models/app_session.dart';

typedef SessionCheck = bool Function(AppSession session);

/// One top-level destination in the nav shell — a feature module (attendance)
/// or an app-wide core area (employees, settings). Each section describes
/// itself; core (shell, redirect logic, Settings hub) only ever sees this type,
/// so core never imports a module. Not called "module" on purpose: that word
/// already means a *database* module (`ModuleNames`, `core.module_access`).
class AppSection {
  const AppSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.canAccess,
    required this.pathPrefix,
    required this.homeLocation,
    required this.routes,
    this.isLandingCandidate = true,
    this.settingsGroupTitle,
    this.settingsEntries = const [],
    this.settingsRoutes = const [],
    this.roleGuards = const {},
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Drives both nav visibility and the URL guard, so the two can't drift.
  final SessionCheck canAccess;

  /// The section owns this path and everything under it (no trailing slash).
  final String pathPrefix;
  final String homeLocation;
  final List<RouteBase> routes;

  /// Whether signing in can land here. False for Settings: a user who can
  /// only see Settings lands on the no-modules page instead.
  final bool isLandingCandidate;

  final String? settingsGroupTitle;
  final List<SettingsEntry> settingsEntries;

  /// Pages opened from the Settings hub. They live in the Settings branch
  /// (under `/settings/<section>/…`) so opening one doesn't jump tabs.
  final List<RouteBase> settingsRoutes;

  /// Exact location → check, for pages stricter than [canAccess].
  final Map<String, SessionCheck> roleGuards;

  bool owns(String location) =>
      location == pathPrefix || location.startsWith('$pathPrefix/');
}

/// A row in the Settings hub, contributed by the section that owns the page.
class SettingsEntry {
  const SettingsEntry({
    required this.icon,
    required this.title,
    required this.canSee,
    required this.location,
  });

  final IconData icon;
  final String title;
  final SessionCheck canSee;

  /// Where the row leads — taken from the owning section's typed route
  /// (`const XRoute().location`), so paths still live in one place. A location
  /// rather than a callback, so the hub can highlight the open page and open
  /// it the right way for the layout (pane vs pushed page).
  final String location;
}
