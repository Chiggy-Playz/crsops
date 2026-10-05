import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_version.dart';
import '../logging/app_talker.dart';
import '../router/navigator_keys.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confirm_dialog.dart';
import 'app_release.dart';
import 'update_controller.dart';

/// Turns update state changes into snackbars and the update prompt, and runs
/// the silent check once at startup. Sits above the router (in MaterialApp's
/// builder), so it lives as long as the app.
class UpdateListener extends ConsumerStatefulWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener> {
  @override
  void initState() {
    super.initState();
    if (!inAppUpdatesEnabled) {
      return;
    }
    // Let the app's own startup requests go first.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(updateControllerProvider.notifier).check(userInitiated: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, _onStateChanged);
    return widget.child;
  }

  void _onStateChanged(UpdateState? previous, UpdateState next) {
    final controller = ref.read(updateControllerProvider.notifier);

    if (next is UpdateAvailable) {
      showAppSnackBar(
        'Version ${next.release.version} is available',
        action: SnackBarAction(
          label: 'Update',
          onPressed: () => _confirmUpdate(next.release),
        ),
      );
    } else if (next is UpdateUpToDate && next.userInitiated) {
      showAppSnackBar("You're on the latest version");
    } else if (next is UpdateCheckFailed && next.userInitiated) {
      showAppSnackBar("Couldn't check for updates");
    } else if (next is UpdateDownloading && previous is! UpdateDownloading) {
      showDownloadProgressSnackBar(controller.cancelDownload);
    } else if (next is UpdateDownloadFailed) {
      showAppSnackBar(
        'Download failed',
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => controller.download(next.release),
        ),
      );
    } else if (next is UpdateReady) {
      showAppSnackBar(
        'Update ${next.release.version} is ready',
        action: SnackBarAction(label: 'Install', onPressed: _install),
      );
    } else if (next is UpdateIdle && previous is UpdateDownloading) {
      showAppSnackBar('Download cancelled');
    }
  }

  Future<void> _confirmUpdate(AppRelease release) async {
    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }
    final megabytes = formatMegabytes(release.apkBytes, decimals: 0);
    final confirmed = await showConfirmDialog(
      dialogContext,
      title: 'Update to ${release.version}?',
      message:
          'You have $appVersion. The download is about $megabytes MB, '
          'and you can keep using the app while it downloads.',
      confirmLabel: 'Update',
    );
    if (confirmed) {
      ref.read(updateControllerProvider.notifier).download(release);
    }
  }

  Future<void> _install() async {
    final controller = ref.read(updateControllerProvider.notifier);
    try {
      final started = await controller.install();
      if (!started) {
        // Android's "Install unknown apps" setting is open now. Keep the
        // install offer on screen for when they come back.
        final current = ref.read(updateControllerProvider);
        if (current is UpdateReady) {
          showAppSnackBar(
            'Allow CRS Ops to install apps, then tap Install',
            action: SnackBarAction(label: 'Install', onPressed: _install),
          );
        }
      }
    } catch (e, st) {
      appTalker.handle(e, st, 'Opening the installer failed');
      showAppSnackBar("Couldn't open the installer");
    }
  }
}

/// One long-lived snackbar whose content follows the download itself. It can
/// be swiped away (it would cover bottom sheets); the Settings version tile
/// shows the progress too, and tapping it brings this snackbar back.
void showDownloadProgressSnackBar(VoidCallback onCancel) {
  showAppSnackBarWidget(
    SnackBar(
      content: const _DownloadProgress(),
      action: SnackBarAction(label: 'Cancel', onPressed: onCancel),
    ),
  );
}

class _DownloadProgress extends ConsumerWidget {
  const _DownloadProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // Snackbars are inverted (dark on light themes and vice versa), so use
    // the inverse colors for everything drawn on them.
    final secondaryStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colorScheme.onInverseSurface.withValues(alpha: 0.72));

    String title = 'Starting download…';
    String? percentLabel;
    String? sizeLabel;
    double? fraction;
    if (state is UpdateDownloading) {
      title = 'Downloading ${state.release.version}';
      fraction = state.fraction;
      final receivedMegabytes = formatMegabytes(state.receivedBytes);
      final totalMegabytes = formatMegabytes(state.totalBytes);
      sizeLabel = '$receivedMegabytes of $totalMegabytes MB';
      final percent = state.percent;
      if (percent != null) {
        percentLabel = '$percent%';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            if (percentLabel != null)
              Text(
                percentLabel,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        if (sizeLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sizeLabel,
            style: secondaryStyle?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _ProgressBar(fraction: fraction),
      ],
    );
  }
}

/// Glides between progress updates instead of jumping each time one
/// arrives; indeterminate until the size is known.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.inversePrimary;
    final trackColor = colorScheme.onInverseSurface.withValues(alpha: 0.2);
    final borderRadius = BorderRadius.circular(3);
    const minHeight = 6.0;

    final target = fraction;
    if (target == null) {
      return LinearProgressIndicator(
        color: color,
        backgroundColor: trackColor,
        minHeight: minHeight,
        borderRadius: borderRadius,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, _) => LinearProgressIndicator(
        value: value,
        color: color,
        backgroundColor: trackColor,
        minHeight: minHeight,
        borderRadius: borderRadius,
      ),
    );
  }
}
