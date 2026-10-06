import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_version.dart';
import '../../auth/providers/auth_providers.dart';
import '../../errors/app_exception.dart';
import '../../layout/two_pane_layout.dart';
import '../../sections/app_sections_provider.dart';
import '../../theme/theme_mode_provider.dart';
import '../../updates/update_controller.dart';
import '../../updates/update_listener.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/inset_list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/selection_sheet.dart';
import '../settings_section.dart';

/// The settings hub: a full page on narrow windows, the left pane of the
/// settings two-pane layout on wide ones, where [selectedLocation] (the page
/// open on the right) is highlighted.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.selectedLocation});

  final String? selectedLocation;

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
          const SectionHeader('Appearance'),
          const _ThemeTile(),
          for (final group in groups) ...[
            SectionHeader(group.title),
            for (final entry in group.entries)
              InsetListTile(
                leading: Icon(entry.icon),
                title: Text(entry.title),
                selected: entry.location == selectedLocation,
                onTap: () => openInPane(context, entry.location),
              ),
          ],
          const SectionHeader('About'),
          const _VersionTile(),
          const Divider(),
          InsetListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } on AppException catch (e) {
                showErrorSnackBar(e);
              }
            },
          ),
        ],
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

    return InsetListTile(
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

class _VersionTile extends ConsumerWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = versionLabel();
    final updateState = ref.watch(updateControllerProvider);
    final checking = updateState is UpdateChecking;

    // Tap checks for updates (Android release builds only); long-press copies.
    // Ignored while a check runs, so it can't be spammed. During a download,
    // tap brings the progress snackbar back instead.
    VoidCallback? onTap;
    if (inAppUpdatesEnabled && !checking) {
      onTap = () {
        final controller = ref.read(updateControllerProvider.notifier);
        if (ref.read(updateControllerProvider) is UpdateDownloading) {
          showDownloadProgressSnackBar(controller.cancelDownload);
        } else {
          controller.check(userInitiated: true);
        }
      };
    }

    String subtitle = label;
    Widget? trailing;
    if (checking) {
      trailing = const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (updateState is UpdateDownloading) {
      final percent = updateState.percent;
      subtitle = '$label\nDownloading ${updateState.release.version}';
      if (percent != null) {
        subtitle = '$subtitle · $percent%';
      }
      trailing = SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: updateState.fraction,
        ),
      );
    }

    return InsetListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: label));
        showAppSnackBar('Version copied');
      },
    );
  }
}
