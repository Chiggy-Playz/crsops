import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/admin_providers.dart';
import '../../layout/two_pane_layout.dart';
import '../../widgets/busy_overlay.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';

class AllowListManagerPage extends ConsumerStatefulWidget {
  const AllowListManagerPage({super.key});

  @override
  ConsumerState<AllowListManagerPage> createState() =>
      _AllowListManagerPageState();
}

class _AllowListManagerPageState extends ConsumerState<AllowListManagerPage> {
  bool _busy = false;

  Future<void> _openAddDialog() => showFormDialog<void>(
    context: context,
    builder: (context) => const _AddAllowedEmailDialog(),
  );

  Future<void> _remove(String email) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove allow-listed email?',
      message: '$email will no longer be able to sign up.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _busy = v),
      action: () => ref.read(adminRepositoryProvider).removeAllowedEmail(email),
      onSuccess: () => ref.invalidate(allowedEmailsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(allowedEmailsProvider);

    return Scaffold(
      appBar: PaneAppBar(
        title: 'Signup allow-list',
        parentLocation: '/settings',
      ),
      body: BusyOverlay(
        busy: _busy,
        child: emailsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (emails) {
            if (emails.isEmpty) {
              return const Center(child: Text('No allow-listed emails yet'));
            }
            return ListView.builder(
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final entry = emails[index];
                return ListTile(
                  title: Text(entry.email),
                  subtitle: entry.note == null ? null : Text(entry.note!),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _remove(entry.email),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddAllowedEmailDialog extends ConsumerStatefulWidget {
  const _AddAllowedEmailDialog();

  @override
  ConsumerState<_AddAllowedEmailDialog> createState() =>
      _AddAllowedEmailDialogState();
}

class _AddAllowedEmailDialogState
    extends ConsumerState<_AddAllowedEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final email = _emailController.text.trim().toLowerCase();
    final note = _noteController.text.trim();

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(adminRepositoryProvider)
          .addAllowedEmail(email: email, note: note.isEmpty ? null : note),
      onSuccess: () {
        ref.invalidate(allowedEmailsProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Add allowed email',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _emailController,
          autofocus: !FormDialog.isCompact(context),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: 'They can sign up with this address',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Enter an email';
            if (!text.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}
