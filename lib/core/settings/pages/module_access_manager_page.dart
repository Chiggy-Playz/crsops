import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/admin_providers.dart';
import '../../widgets/guarded_save.dart';

class ModuleAccessManagerPage extends ConsumerWidget {
  const ModuleAccessManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);
    final accessAsync = ref.watch(moduleAccessProvider);
    final modulesAsync = ref.watch(modulesProvider);

    // Gate on both together, same reasoning as RolesManagerPage: roles decide
    // which profiles even render below, so a row must never flash before
    // roles finish loading.
    if (profilesAsync.isLoading || rolesAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Module access')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (profilesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Module access')),
        body: Center(child: Text('${profilesAsync.error}')),
      );
    }
    if (rolesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Module access')),
        body: Center(child: Text('${rolesAsync.error}')),
      );
    }

    final roles = rolesAsync.value ?? const {};
    // Admin-or-above always passes hasModuleAccess() regardless of any grant
    // row (see AppSession.hasModuleAccess) — granting them one is a no-op
    // that only confuses whoever's using this screen, so they're not listed.
    final profiles = profilesAsync.value!
        .where((p) => roles[p.id] != 'admin' && roles[p.id] != 'superadmin')
        .toList();
    final access = accessAsync.value ?? const {};
    final modules = modulesAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Module access')),
      body: profiles.isEmpty
          ? const Center(
              child: Text('No employee logins yet to grant module access to'),
            )
          : ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final granted = access[profile.id] ?? const <String>{};
                return ListTile(
                  title: Text(profile.email),
                  subtitle: Text(
                    granted.isEmpty
                        ? 'No module access granted'
                        : granted.join(', '),
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: modules.isEmpty
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (context) => _GrantModuleAccessDialog(
                            profileId: profile.id,
                            modules: modules,
                          ),
                        ),
                );
              },
            ),
    );
  }
}

class _GrantModuleAccessDialog extends ConsumerStatefulWidget {
  const _GrantModuleAccessDialog({
    required this.profileId,
    required this.modules,
  });
  final String profileId;
  final List<({String id, String name})> modules;

  @override
  ConsumerState<_GrantModuleAccessDialog> createState() =>
      _GrantModuleAccessDialogState();
}

class _GrantModuleAccessDialogState
    extends ConsumerState<_GrantModuleAccessDialog> {
  String? _selectedModuleId;
  bool _saving = false;

  Future<void> _grant() async {
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
    return AlertDialog(
      title: const Text('Grant module access'),
      content: SizedBox(
        width: 280,
        child: DropdownMenu<String>(
          initialSelection: _selectedModuleId,
          expandedInsets: EdgeInsets.zero,
          hintText: 'Select a module',
          dropdownMenuEntries: widget.modules
              .map((m) => DropdownMenuEntry(value: m.id, label: m.name))
              .toList(),
          onSelected: (value) => setState(() => _selectedModuleId = value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || _selectedModuleId == null ? null : _grant,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Grant'),
        ),
      ],
    );
  }
}
