import 'package:flutter/material.dart';

import '../../settings/routes.dart';

/// For a user who has a role but can't open any section except Settings.
/// Distinct from UnauthorizedPage, which means "your account has no role".
class NoModulesPage extends StatelessWidget {
  const NoModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => const SettingsRoute().push(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apps_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'No modules yet',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "You don't have access to any modules yet. "
                'Ask an admin to grant access.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
