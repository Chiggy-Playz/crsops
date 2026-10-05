import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app_release.dart';

/// Android updates from GitHub Releases, until the app is on the Play Store.
/// Talks to the public GitHub API (no token; 60 requests/hour per IP) and to
/// MainActivity.kt over [_channel] for the phone's ABIs and the installer.
class UpdateRepository {
  static const _latestReleaseUrl =
      'https://api.github.com/repos/Chiggy-Playz/crsops/releases/latest';
  static const _channel = MethodChannel('crs_ops/app_update');

  /// A download fails when no data has arrived for this long, rather than
  /// sitting at the same percentage forever on a dead connection.
  static const _stallTimeout = Duration(seconds: 30);

  HttpClient? _downloadClient;

  /// The latest published release and the APK for this phone, or null if it
  /// has none (e.g. a release without APKs, or an unsupported ABI).
  Future<AppRelease?> fetchLatestRelease() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseUrl));
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub returned ${response.statusCode}: $body');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String;
      final assets = [
        for (final asset in json['assets'] as List<dynamic>)
          ReleaseAsset(
            name: asset['name'] as String,
            url: asset['browser_download_url'] as String,
            bytes: asset['size'] as int,
          ),
      ];
      final abis = await supportedAbis();
      final apk = pickApkAsset(assets, abis);
      if (apk == null) {
        return null;
      }
      return AppRelease(
        version: tag.startsWith('v') ? tag.substring(1) : tag,
        apkUrl: apk.url,
        apkBytes: apk.bytes,
      );
    } finally {
      client.close();
    }
  }

  Future<List<String>> supportedAbis() async {
    final abis = await _channel.invokeListMethod<String>('supportedAbis');
    return abis ?? const [];
  }

  /// Downloads [release]'s APK into the cache (where MainActivity's
  /// FileProvider can share it with the installer), reporting bytes received.
  /// Throws if cancelled with [cancelDownload], if the connection stalls, or
  /// if it ends before the whole APK arrived.
  Future<File> downloadApk(
    AppRelease release, {
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final updatesDir = Directory('${cacheDir.path}/updates');
    // Only ever keep the APK being downloaded now.
    if (updatesDir.existsSync()) {
      updatesDir.deleteSync(recursive: true);
    }
    updatesDir.createSync();
    final file = File('${updatesDir.path}/crs-ops-${release.version}.apk');

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    _downloadClient = client;
    try {
      // GitHub redirects asset downloads to its CDN; HttpClient follows that.
      final request = await client.getUrl(Uri.parse(release.apkUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Download returned ${response.statusCode}');
      }

      var totalBytes = response.contentLength;
      if (totalBytes <= 0) {
        totalBytes = release.apkBytes;
      }
      var receivedBytes = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.timeout(_stallTimeout)) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          onProgress(receivedBytes, totalBytes);
        }
      } finally {
        await sink.close();
      }
      // A connection that closes early ends the stream without an error; a
      // partial APK would only fail later, in Android's installer.
      if (receivedBytes != totalBytes) {
        throw HttpException(
          'Download ended early: $receivedBytes of $totalBytes bytes',
        );
      }
      return file;
    } finally {
      _downloadClient = null;
      client.close();
    }
  }

  /// Aborts a running [downloadApk], which then throws.
  void cancelDownload() {
    _downloadClient?.close(force: true);
  }

  /// Opens Android's installer for [apk]. Returns false when the phone first
  /// needs "Install unknown apps" allowed for CRS Ops: MainActivity has then
  /// opened that setting instead, and the user should tap Install again.
  Future<bool> installApk(File apk) async {
    final outcome = await _channel.invokeMethod<String>('installApk', {
      'path': apk.path,
    });
    return outcome == 'started';
  }
}
