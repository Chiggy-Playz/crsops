/// A GitHub release that has an APK this phone can install.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.apkUrl,
    required this.apkBytes,
  });

  /// `1.4.2` (the tag without its `v`).
  final String version;
  final String apkUrl;
  final int apkBytes;
}

/// One downloadable file attached to a release.
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.bytes,
  });

  final String name;
  final String url;
  final int bytes;
}

/// Whether [candidate] (`1.4.10`) is a later version than [current]
/// (`1.4.9`). Compares numbers, not text. Anything that isn't `X.Y.Z` is
/// never newer, so a malformed tag can't trigger an update.
bool isNewerVersion(String candidate, String current) {
  final candidateParts = _parseVersion(candidate);
  final currentParts = _parseVersion(current);
  if (candidateParts == null || currentParts == null) {
    return false;
  }
  for (var i = 0; i < 3; i++) {
    if (candidateParts[i] > currentParts[i]) {
      return true;
    }
    if (candidateParts[i] < currentParts[i]) {
      return false;
    }
  }
  return false;
}

List<int>? _parseVersion(String version) {
  final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(version.trim());
  if (match == null) {
    return null;
  }
  return [
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

/// The release APK built for this phone. Releases name them
/// `crs-ops-X.Y.Z-<abi>.apk`; [supportedAbis] is the phone's list, most
/// preferred first (e.g. `arm64-v8a, armeabi-v7a, armeabi`).
ReleaseAsset? pickApkAsset(
  List<ReleaseAsset> assets,
  List<String> supportedAbis,
) {
  for (final abi in supportedAbis) {
    for (final asset in assets) {
      if (asset.name.endsWith('-$abi.apk')) {
        return asset;
      }
    }
  }
  return null;
}

/// `21.7` for 21.7 MB (binary megabytes, as Android shows file sizes).
String formatMegabytes(int bytes, {int decimals = 1}) {
  return (bytes / (1024 * 1024)).toStringAsFixed(decimals);
}
