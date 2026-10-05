import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/app_session.dart';
import '../../auth/providers/admin_providers.dart';
import '../../layout/two_pane_layout.dart';
import '../../utils/status_metadata.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../routes.dart';

class RolesManagerPage extends ConsumerWidget {
  const RolesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PaneAppBar(
        title: 'Roles',
        parentLocation: const SettingsRoute().location,
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);

    // Two independent async fetches back this page — gate on both together so
    // a row never briefly shows "no role granted" before roles finish loading.
    if (profilesAsync.isLoading || rolesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profilesAsync.hasError) {
      return Center(child: Text('${profilesAsync.error}'));
    }
    if (rolesAsync.hasError) {
      return Center(child: Text('${rolesAsync.error}'));
    }

    // Loading/error are handled above, so profiles/roles are values here.
    final profiles = profilesAsync.value!;
    if (profiles.isEmpty) {
      return const Center(
        child: Text('No profiles yet — nobody has signed in'),
      );
    }
    final roles = rolesAsync.value ?? const {};
    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final role = roles[profile.id];
        String subtitle = 'No role granted';
        if (role != null) subtitle = 'Role: ${displayLabel(role)}';
        return ListTile(
          title: Text(profile.email),
          subtitle: Text(subtitle),
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
        await ref
            .read(adminRepositoryProvider)
            .setRole(userId: widget.profileId, roleId: _selectedRole!);
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
          dropdownMenuEntries: [
            for (final role in AppRole.values)
              DropdownMenuEntry(
                value: role.name,
                label: displayLabel(role.name),
              ),
          ],
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
