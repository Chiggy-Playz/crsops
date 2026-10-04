import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../errors/app_exception.dart';
import '../../sections/app_sections_provider.dart';
import '../../theme/theme_mode_provider.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/selection_sheet.dart';
import '../settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final sections = ref.watch(appSectionsProvider);

    // Each section contributes its own rows; a group only appears if this
    // user can see at least one of them. Settings' own (app-wide access) group
    // comes first, then the other sections in nav order.
    final groups = [
      if (session != null)
        for (final section in [
          settingsSection,
          ...sections.where((s) => !identical(s, settingsSection)),
        ])
          (
            title: section.settingsGroupTitle ?? section.label,
            entries: [
              for (final entry in section.settingsEntries)
                if (entry.canSee(session)) entry,
            ],
          ),
    ].where((g) => g.entries.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _GroupHeader('Appearance'),
          const _ThemeTile(),
          for (final group in groups) ...[
            _GroupHeader(group.title),
            for (final entry in group.entries)
              ListTile(
                leading: Icon(entry.icon),
                title: Text(entry.title),
                onTap: () => entry.open(context),
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } on AppException catch (e) {
                if (context.mounted) showErrorSnackBar(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

const _themeOptions = [
  SelectionOption(
    value: ThemeMode.system,
    label: 'System default',
    icon: Icons.brightness_auto_outlined,
  ),
  SelectionOption(
    value: ThemeMode.light,
    label: 'Light',
    icon: Icons.light_mode_outlined,
  ),
  SelectionOption(
    value: ThemeMode.dark,
    label: 'Dark',
    icon: Icons.dark_mode_outlined,
  ),
];

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    final current = _themeOptions.firstWhere((o) => o.value == mode);

    return ListTile(
      leading: Icon(current.icon),
      title: const Text('Theme'),
      subtitle: Text(current.label),
      onTap: () async {
        final picked = await showSelectionSheet(
          context: context,
          title: 'Theme',
          options: _themeOptions,
          selected: mode,
        );
        if (picked != null) {
          ref.read(themeModeControllerProvider.notifier).set(picked);
        }
      },
    );
  }
}
