import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';

class RolesManagerPage extends ConsumerWidget {
  const RolesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles yet — nobody has signed in'));
          }
          final roles = rolesAsync.value ?? const {};
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final role = roles[profile.id];
              return ListTile(
                title: Text(profile.email),
                subtitle: Text(role == null ? 'No role granted' : 'Role: $role'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => _EditRoleDialog(profileId: profile.id, currentRole: role),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditRoleDialog extends ConsumerStatefulWidget {
  const _EditRoleDialog({required this.profileId, required this.currentRole});
  final String profileId;
  final String? currentRole;

  @override
  ConsumerState<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<_EditRoleDialog> {
  late String? _selectedRole = widget.currentRole;

  bool get _canSave => _selectedRole != null && _selectedRole != widget.currentRole;

  Future<void> _save() async {
    final repo = ref.read(adminRepositoryProvider);
    if (widget.currentRole != null) {
      await repo.revokeRole(userId: widget.profileId, roleId: widget.currentRole!);
    }
    await repo.grantRole(userId: widget.profileId, roleId: _selectedRole!);
    ref.invalidate(userRolesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: DropdownButton<String>(
        value: _selectedRole,
        hint: const Text('Select a role'),
        items: const ['superadmin', 'admin', 'employee']
            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
            .toList(),
        onChanged: (value) => setState(() => _selectedRole = value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      ],
    );
  }
}
