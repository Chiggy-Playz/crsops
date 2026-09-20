import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';
import '../../../core/widgets/status_metadata.dart';

class RolesManagerPage extends ConsumerWidget {
  const RolesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);

    // Two independent async fetches back this page — gate on both together so
    // a row never briefly shows "no role granted" before roles finish loading.
    if (profilesAsync.isLoading || rolesAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (profilesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        body: Center(child: Text('${profilesAsync.error}')),
      );
    }
    if (rolesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        body: Center(child: Text('${rolesAsync.error}')),
      );
    }

    // Loading/error are handled above, so profiles/roles are values here —
    // no .when() needed (its loading/error arms would be unreachable).
    final profiles = profilesAsync.value!;
    if (profiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        body: const Center(
          child: Text('No profiles yet — nobody has signed in'),
        ),
      );
    }
    final roles = rolesAsync.value ?? const {};
    return Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      body: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final role = roles[profile.id];
          return ListTile(
            title: Text(profile.email),
            subtitle: Text(
              role == null ? 'No role granted' : 'Role: ${displayLabel(role)}',
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) =>
                  _EditRoleDialog(profileId: profile.id, currentRole: role),
            ),
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
  bool _saving = false;

  bool get _canSave =>
      !_saving && _selectedRole != null && _selectedRole != widget.currentRole;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (widget.currentRole != null) {
        await repo.revokeRole(
          userId: widget.profileId,
          roleId: widget.currentRole!,
        );
      }
      await repo.grantRole(userId: widget.profileId, roleId: _selectedRole!);
      ref.invalidate(userRolesProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: SizedBox(
        width: 280,
        child: DropdownMenu<String>(
          initialSelection: _selectedRole,
          expandedInsets: EdgeInsets.zero,
          hintText: 'Select a role',
          dropdownMenuEntries: const [
            'superadmin',
            'admin',
            'employee',
          ].map((role) => DropdownMenuEntry(value: role, label: role)).toList(),
          onSelected: (value) => setState(() => _selectedRole = value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
