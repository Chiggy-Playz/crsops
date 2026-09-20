import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/providers/auth_providers.dart';
import '../../../core/router/route_names.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final isSuperadmin = session?.isSuperadmin ?? false;
    final isAdminOrAbove = session?.isAdminOrAbove ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Signup allow-list'),
              onTap: () => context.pushNamed(RouteNames.allowList),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Roles'),
              onTap: () => context.pushNamed(RouteNames.roles),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Module access'),
              onTap: () => context.pushNamed(RouteNames.moduleAccess),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Event types'),
              onTap: () => context.pushNamed(RouteNames.eventTypes),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Shift defaults'),
              onTap: () => context.pushNamed(RouteNames.shiftDefaults),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Attendance status types'),
              onTap: () => context.pushNamed(RouteNames.statusTypes),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
