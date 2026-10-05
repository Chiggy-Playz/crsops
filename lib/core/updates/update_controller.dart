import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_version.dart';
import '../logging/app_talker.dart';
import 'app_release.dart';
import 'update_repository.dart';

part 'update_controller.g.dart';

/// Only Android release builds update themselves: web is always current on
/// reload, desktop has no APK, and local builds have no version to compare.
bool get inAppUpdatesEnabled =>
    !kIsWeb && Platform.isAndroid && appVersion.isNotEmpty;

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking({required this.userInitiated});

  final bool userInitiated;
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate({required this.userInitiated});

  final bool userInitiated;
}

class UpdateCheckFailed extends UpdateState {
  const UpdateCheckFailed({required this.userInitiated});

  final bool userInitiated;
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.release);

  final AppRelease release;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(
    this.release, {
    required this.receivedBytes,
    required this.totalBytes,
  });

  final AppRelease release;
  final int receivedBytes;
  final int totalBytes;

  /// 0–1, or null while the size is unknown.
  double? get fraction => totalBytes > 0 ? receivedBytes / totalBytes : null;

  /// 0–100, or null while the size is unknown.
  int? get percent {
    final value = fraction;
    if (value == null) {
      return null;
    }
    return (value * 100).floor();
  }
}

class UpdateDownloadFailed extends UpdateState {
  const UpdateDownloadFailed(this.release);

  final AppRelease release;
}

class UpdateReady extends UpdateState {
  const UpdateReady(this.release, this.apk);

  final AppRelease release;
  final File apk;
}

@Riverpod(keepAlive: true)
UpdateRepository updateRepository(Ref ref) => UpdateRepository();

@Riverpod(keepAlive: true)
class UpdateController extends _$UpdateController {
  bool _cancelRequested = false;

  @override
  UpdateState build() => const UpdateIdle();

  bool get _isBusy => state is UpdateChecking || state is UpdateDownloading;

  /// Asks GitHub for the latest release. [userInitiated] (the Settings
  /// version tile) also reports "up to date" and failures; the silent startup
  /// check only speaks up when there's an update.
  Future<void> check({required bool userInitiated}) async {
    if (!inAppUpdatesEnabled || _isBusy) {
      return;
    }
    final current = state;
    // Already downloaded: offer the install again instead of re-checking.
    if (current is UpdateReady) {
      state = UpdateReady(current.release, current.apk);
      return;
    }

    state = UpdateChecking(userInitiated: userInitiated);
    try {
      final release = await ref
          .read(updateRepositoryProvider)
          .fetchLatestRelease();
      if (release != null && isNewerVersion(release.version, appVersion)) {
        state = UpdateAvailable(release);
      } else {
        state = UpdateUpToDate(userInitiated: userInitiated);
      }
    } catch (e, st) {
      appTalker.handle(e, st, 'Update check failed');
      state = UpdateCheckFailed(userInitiated: userInitiated);
    }
  }

  Future<void> download(AppRelease release) async {
    if (state is UpdateDownloading) {
      return;
    }
    _cancelRequested = false;
    state = UpdateDownloading(
      release,
      receivedBytes: 0,
      totalBytes: release.apkBytes,
    );

    var lastReportedBytes = 0;
    try {
      final apk = await ref
          .read(updateRepositoryProvider)
          .downloadApk(
            release,
            onProgress: (receivedBytes, totalBytes) {
              // Chunks arrive every few KB; repaint about every 1% instead.
              final step = totalBytes > 0 ? totalBytes ~/ 100 : 256 * 1024;
              final finished = receivedBytes == totalBytes;
              if (receivedBytes - lastReportedBytes >= step || finished) {
                lastReportedBytes = receivedBytes;
                state = UpdateDownloading(
                  release,
                  receivedBytes: receivedBytes,
                  totalBytes: totalBytes,
                );
              }
            },
          );
      state = UpdateReady(release, apk);
    } catch (e, st) {
      if (_cancelRequested) {
        state = const UpdateIdle();
        return;
      }
      appTalker.handle(e, st, 'Update download failed');
      state = UpdateDownloadFailed(release);
    }
  }

  void cancelDownload() {
    if (state is! UpdateDownloading) {
      return;
    }
    _cancelRequested = true;
    ref.read(updateRepositoryProvider).cancelDownload();
  }

  /// Opens Android's installer. False when the user first has to allow
  /// installs for CRS Ops (that setting is open now; they tap Install again).
  Future<bool> install() async {
    final current = state;
    if (current is! UpdateReady) {
      return false;
    }
    return ref.read(updateRepositoryProvider).installApk(current.apk);
  }
}
