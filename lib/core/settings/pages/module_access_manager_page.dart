import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/app_session.dart';
import '../../auth/providers/admin_providers.dart';
import '../../layout/two_pane_layout.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../routes.dart';

class ModuleAccessManagerPage extends ConsumerWidget {
  const ModuleAccessManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PaneAppBar(
        title: 'Module access',
        parentLocation: const SettingsRoute().location,
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);
    final accessAsync = ref.watch(moduleAccessProvider);
    final modulesAsync = ref.watch(modulesProvider);

    // Gate on both together, same reasoning as RolesManagerPage: roles decide
    // which profiles even render below, so a row must never flash before
    // roles finish loading.
    if (profilesAsync.isLoading || rolesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profilesAsync.hasError) {
      return Center(child: Text('${profilesAsync.error}'));
    }
    if (rolesAsync.hasError) {
      return Center(child: Text('${rolesAsync.error}'));
    }

    final roles = rolesAsync.value ?? const {};
    // Admin-or-above always passes hasModuleAccess() regardless of any grant
    // row (see AppSession.hasModuleAccess) — granting them one is a no-op
    // that only confuses whoever's using this screen, so they're not listed.
    final profiles = profilesAsync.value!.where((p) {
      final role = roles[p.id];
      return role != AppRole.admin.name && role != AppRole.superadmin.name;
    }).toList();
    final access = accessAsync.value ?? const {};
    final modules = modulesAsync.value ?? const [];

    if (profiles.isEmpty) {
      return const Center(
        child: Text('No employee logins yet to grant module access to'),
      );
    }
    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final granted = access[profile.id] ?? const <String>{};
        final hasAll = modules.every((m) => granted.contains(m.id));
        String subtitle = granted.join(', ');
        if (granted.isEmpty) subtitle = 'No module access granted';
        // Nothing left to grant → no form that would open empty.
        final canGrant = modules.isNotEmpty && !hasAll;
        return ListTile(
          title: Text(profile.email),
          subtitle: Text(subtitle),
          trailing: Icon(hasAll ? Icons.check : Icons.add),
          onTap: canGrant
              ? () => showFormDialog<void>(
                  context: context,
                  builder: (context) => _GrantModuleAccessDialog(
                    profileId: profile.id,
                    email: profile.email,
                    granted: granted,
                    modules: modules,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _GrantModuleAccessDialog extends ConsumerStatefulWidget {
  const _GrantModuleAccessDialog({
    required this.profileId,
    required this.email,
    required this.granted,
    required this.modules,
  });
  final String profileId;
  final String email;
  final Set<String> granted;
  final List<({String id, String name})> modules;

  @override
  ConsumerState<_GrantModuleAccessDialog> createState() =>
      _GrantModuleAccessDialogState();
}

class _GrantModuleAccessDialogState
    extends ConsumerState<_GrantModuleAccessDialog> {
  String? _selectedModuleId;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _grant() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(adminRepositoryProvider)
          .grantModuleAccess(
            userId: widget.profileId,
            moduleId: _selectedModuleId!,
          ),
      onSuccess: () {
        ref.invalidate(moduleAccessProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Grant module access',
      description: 'For ${widget.email}',
      formKey: _formKey,
      saving: _saving,
      onSave: _grant,
      children: [
        DropdownMenuFormField<String>(
          initialSelection: _selectedModuleId,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Module'),
          // Only modules they don't already have.
          dropdownMenuEntries: [
            for (final m in widget.modules)
              if (!widget.granted.contains(m.id))
                DropdownMenuEntry(value: m.id, label: m.name),
          ],
          onSelected: (value) => setState(() => _selectedModuleId = value),
          validator: (value) => value == null ? 'Choose a module' : null,
        ),
      ],
    );
  }
}
