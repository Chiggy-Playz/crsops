/// Set by the release workflow from the git tag (`--dart-define=APP_VERSION=1.4.2`).
/// Empty in local builds.
const appVersion = String.fromEnvironment('APP_VERSION');

/// Short commit hash, set by the release workflow (`--dart-define=GIT_SHA=…`).
const gitSha = String.fromEnvironment('GIT_SHA');

/// What Settings shows: `1.4.2 · a1b2c3d`, or `Development build` locally.
String versionLabel({String version = appVersion, String sha = gitSha}) {
  if (version.isEmpty) {
    return 'Development build';
  }
  if (sha.isEmpty) {
    return version;
  }
  return '$version · $sha';
}
