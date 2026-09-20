import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/auth_providers.dart';

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
              onTap: () => Navigator.of(context).pushNamed('/settings/allow-list'),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Roles'),
              onTap: () => Navigator.of(context).pushNamed('/settings/roles'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Module access'),
              onTap: () => Navigator.of(context).pushNamed('/settings/module-access'),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Event types'),
              onTap: () => Navigator.of(context).pushNamed('/employees/event-types'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Shift defaults'),
              onTap: () => Navigator.of(context).pushNamed('/attendance/shift-defaults'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Attendance status types'),
              onTap: () => Navigator.of(context).pushNamed('/attendance/status-types'),
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
