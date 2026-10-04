import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/admin_providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../../widgets/status_metadata.dart';

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
            onTap: () => showFormDialog<void>(
              context: context,
              builder: (context) => _EditRoleDialog(
                profileId: profile.id,
                email: profile.email,
                currentRole: role,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditRoleDialog extends ConsumerStatefulWidget {
  const _EditRoleDialog({
    required this.profileId,
    required this.email,
    required this.currentRole,
  });
  final String profileId;
  final String email;
  final String? currentRole;

  @override
  ConsumerState<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<_EditRoleDialog> {
  late String? _selectedRole = widget.currentRole;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        final repo = ref.read(adminRepositoryProvider);
        if (widget.currentRole != null) {
          await repo.revokeRole(
            userId: widget.profileId,
            roleId: widget.currentRole!,
          );
        }
        await repo.grantRole(userId: widget.profileId, roleId: _selectedRole!);
      },
      onSuccess: () {
        ref.invalidate(userRolesProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Change role',
      description: 'For ${widget.email}',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        DropdownMenuFormField<String>(
          initialSelection: _selectedRole,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Role'),
          dropdownMenuEntries: const ['superadmin', 'admin', 'employee']
              .map(
                (role) =>
                    DropdownMenuEntry(value: role, label: displayLabel(role)),
              )
              .toList(),
          onSelected: (value) => setState(() => _selectedRole = value),
          validator: (value) {
            if (value == null) return 'Choose a role';
            if (value == widget.currentRole) {
              return 'They already have this role';
            }
            return null;
          },
        ),
      ],
    );
  }
}
