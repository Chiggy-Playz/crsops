import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';

class AllowListManagerPage extends ConsumerStatefulWidget {
  const AllowListManagerPage({super.key});

  @override
  ConsumerState<AllowListManagerPage> createState() => _AllowListManagerPageState();
}

class _AllowListManagerPageState extends ConsumerState<AllowListManagerPage> {
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _canAdd => _emailController.text.trim().isNotEmpty;

  Future<void> _add() async {
    await ref.read(adminRepositoryProvider).addAllowedEmail(
          email: _emailController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
    _emailController.clear();
    _noteController.clear();
    ref.invalidate(allowedEmailsProvider);
    setState(() {});
  }

  Future<void> _remove(String email) async {
    await ref.read(adminRepositoryProvider).removeAllowedEmail(email);
    ref.invalidate(allowedEmailsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(allowedEmailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Signup allow-list')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _canAdd ? _add : null, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
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
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(entry.email),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
