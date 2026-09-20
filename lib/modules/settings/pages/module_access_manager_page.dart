import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';
import '../../../core/widgets/guarded_save.dart';

class ModuleAccessManagerPage extends ConsumerWidget {
  const ModuleAccessManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final accessAsync = ref.watch(moduleAccessProvider);
    final modulesAsync = ref.watch(modulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Module access')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Text('No profiles yet — nobody has signed in'),
            );
          }
          final access = accessAsync.value ?? const {};
          final modules = modulesAsync.value ?? const [];
          return ListView.builder(
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
