import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/providers/auth_providers.dart';
import '../../core/router/route_names.dart';
import 'pages/allow_list_manager_page.dart';
import 'pages/module_access_manager_page.dart';
import 'pages/roles_manager_page.dart';
import 'pages/settings_page.dart';

List<RouteBase> settingsRoutes(Ref ref) => [
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/allow-list',
        name: RouteNames.allowList,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const AllowListManagerPage(),
      ),
      GoRoute(
        path: '/settings/roles',
        name: RouteNames.roles,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const RolesManagerPage(),
      ),
      GoRoute(
        path: '/settings/module-access',
        name: RouteNames.moduleAccess,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const ModuleAccessManagerPage(),
      ),
    ];
