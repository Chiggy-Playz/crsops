import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/auth_providers.dart';
import '../../../core/employees/routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../attendance/routes.dart';
import '../routes.dart';

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
              onTap: () => const AllowListRoute().push(context),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Roles'),
              onTap: () => const RolesRoute().push(context),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Module access'),
              onTap: () => const ModuleAccessRoute().push(context),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Event types'),
              onTap: () => const EventTypesRoute().push(context),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Shift defaults'),
              onTap: () => const ShiftDefaultsRoute().push(context),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Attendance status types'),
              onTap: () => const StatusTypesRoute().push(context),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } on AppException catch (e) {
                if (context.mounted) showErrorSnackBar(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}
