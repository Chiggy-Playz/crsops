import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/admin_providers.dart';
import '../../widgets/busy_overlay.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/guarded_save.dart';

class AllowListManagerPage extends ConsumerStatefulWidget {
  const AllowListManagerPage({super.key});

  @override
  ConsumerState<AllowListManagerPage> createState() =>
      _AllowListManagerPageState();
}

class _AllowListManagerPageState extends ConsumerState<AllowListManagerPage> {
  bool _busy = false;

  Future<void> _openAddDialog() async {
    // Method-local controllers: they live and die with this dialog — nothing
    // outlives the popped route, so the GC reclaims them and an explicit
    // dispose() would race the dialog's own exit-animation rebuilds (a
    // dispose-in-finally here crashes with "used after dispose").
    final emailController = TextEditingController();
    final noteController = TextEditingController();
    final added =
        await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Add allowed email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: emailController.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    // Captured while the dialog's controllers are still alive; the dialog
    // route (and its controllers) is dropped on pop.
    final email = emailController.text.trim().toLowerCase();
    final noteText = noteController.text.trim();
    final String? note = noteText.isEmpty ? null : noteText;
    if (!added || !mounted) return;

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _busy = v),
      action: () => ref
          .read(adminRepositoryProvider)
          .addAllowedEmail(email: email, note: note),
      onSuccess: () => ref.invalidate(allowedEmailsProvider),
    );
  }

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
      appBar: AppBar(title: const Text('Signup allow-list')),
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
