import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/window_size.dart';
import '../widgets/empty_state.dart';
import 'pages/allow_list_manager_page.dart';
import 'pages/module_access_manager_page.dart';
import 'pages/roles_manager_page.dart';
import 'pages/settings_page.dart';

part 'routes.g.dart';

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Wide: the hub is the left pane, so the right pane waits for a pick.
    if (context.isTwoPane) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.tune,
          title: 'Choose a setting',
          message: 'Pick something from the list to change it here.',
        ),
      );
    }
    return const SettingsPage();
  }
}

@TypedGoRoute<AllowListRoute>(path: '/settings/allow-list')
class AllowListRoute extends GoRouteData with $AllowListRoute {
  const AllowListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AllowListManagerPage();
}

@TypedGoRoute<RolesRoute>(path: '/settings/roles')
class RolesRoute extends GoRouteData with $RolesRoute {
  const RolesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RolesManagerPage();
}

@TypedGoRoute<ModuleAccessRoute>(path: '/settings/module-access')
class ModuleAccessRoute extends GoRouteData with $ModuleAccessRoute {
  const ModuleAccessRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ModuleAccessManagerPage();
}
