import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_exception.dart';
import '../../widgets/error_snackbar.dart';
import '../providers/auth_providers.dart';

class UnauthorizedPage extends ConsumerWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('No access yet'),
            const SizedBox(height: 8),
            const Text('Ask an admin to grant you a role.'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } on AppException catch (e) {
                  showErrorSnackBar(e);
                }
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
