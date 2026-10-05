# Tagged releases (web + Android) and a version tile — design

**Date:** 2026-10-05 · **Status:** draft, awaiting review

## Problem

Releasing is manual: build `build/web` locally, drag it into the Cloudflare
dashboard; there is no release APK at all (release builds are signed with the
debug key, `android/app/build.gradle.kts:36`). Nothing in the app says which
version or commit it is.

## Goal

Pushing a tag like `v1.4.2` is the whole release process:

1. The web app is built and deployed to the `crsops` Worker
   (`crsops.chiggydoes.tech`).
2. A signed release APK is built and attached to a GitHub Release `v1.4.2`.
3. Settings shows `Version 1.4.2 · a1b2c3d`.

Play Store publishing is out of scope, but the design must let it slot in as
one extra step later.

## Decisions

### D1. The tag is the only source of the version

`pubspec.yaml` stays at `1.0.0+1` forever, with a comment saying CI sets the
real version. The workflow derives everything from the tag:

- Tag must match `vX.Y.Z` (digits only); anything else fails the run
  immediately with a clear message. `Y` and `Z` must be < 100.
- `--build-name=X.Y.Z`
- `--build-number=X*10000 + Y*100 + Z` (e.g. `1.4.2` → `10402`), so every
  later version has a larger Android `versionCode`, as Play requires.
- `--dart-define=APP_VERSION=X.Y.Z --dart-define=GIT_SHA=<7-char sha>`

CI never commits back to the repo.

### D2. GitHub Actions, not Cloudflare Workers Builds

Workers Builds triggers on branch pushes, not tags, and its image has no
Flutter. One workflow, `.github/workflows/release.yml`, on `push: tags: v*`:

```
check ──┬── web      (build --wasm, wrangler deploy)
        └── android  (signed APK → GitHub Release)
```

- **check**: `flutter analyze` and `flutter test`. Web and android both
  `needs: check`, so nothing ships if either fails.
- **web** and **android** run in parallel and don't depend on each other.
- Flutter is pinned to the version used locally (3.47.5); Java 21 for Gradle.
- `env.json` is written from secrets, then passed with
  `--dart-define-from-file=env.json`, same as local builds.
- Generated `*.g.dart` files are committed, so CI doesn't run build_runner.

### D3. `wrangler.jsonc` in the repo

Mirrors what was set up in the dashboard, so a CI deploy reproduces it:

```jsonc
{
  "name": "crsops",
  "compatibility_date": "2026-10-05",
  "assets": {
    "directory": "./build/web",
    "not_found_handling": "single-page-application"
  },
  "routes": [{ "pattern": "crsops.chiggydoes.tech", "custom_domain": true }]
}
```

Deployed with `cloudflare/wrangler-action` using `CLOUDFLARE_API_TOKEN` and
`CLOUDFLARE_ACCOUNT_ID`. It also lets a manual `npx wrangler deploy` work from
a local machine.

### D4. Android signing

- `android/app/build.gradle.kts` reads `android/key.properties`
  (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; already
  gitignored). If present, release builds use it.
- If absent: locally, fall back to debug signing (keeps
  `flutter run --release` working); when the `CI` env var is set, fail the
  build instead of silently shipping a debug-signed APK.
- In CI the workflow decodes `ANDROID_KEYSTORE_BASE64` to a file and writes
  `key.properties` from the other secrets before building.
- Output: `crs-ops-X.Y.Z.apk` (universal APK), attached to a GitHub Release
  created with `softprops/action-gh-release`, release notes auto-generated
  from commits since the previous tag.

One-time manual setup (the user):

1. Generate an upload keystore with `keytool`; keep it outside the repo and
   back it up. Losing it means no further updates to the same app (until Play
   App Signing, where the upload key can be reset).
2. Register its SHA-1 as an Android OAuth client in Google Cloud
   (package `tech.chiggydoes.crs_ops`), or Google sign-in fails in release
   APKs. The existing debug client stays.
3. Add the GitHub secrets below.

Consequences: an installed debug-signed APK can't be upgraded by a release
one (uninstall once). Later, Play App Signing re-signs with Google's key; its
SHA-1 (from Play Console) becomes one more Android OAuth client.

### D5. Version tile in Settings

- `lib/core/app_version.dart`: `APP_VERSION` / `GIT_SHA` via
  `String.fromEnvironment`, and the display text: `1.4.2 · a1b2c3d`, or
  `Development build` when `APP_VERSION` is empty. No new package; same on
  web, Android and desktop.
- `settings_page.dart`: a new **About** group after the section groups,
  before the divider and Sign out, holding a `_VersionTile` (same style as
  `_ThemeTile`): leading `Icons.info_outline`, title `Version`, subtitle the
  display text. Tap copies the subtitle text to the clipboard and shows a
  "Version copied" snackbar.

## GitHub secrets

| Secret | Value |
|---|---|
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_SERVER_CLIENT_ID` | from `env.json` |
| `CLOUDFLARE_API_TOKEN` | token with "Edit Cloudflare Workers" permissions |
| `CLOUDFLARE_ACCOUNT_ID` | dashboard account ID |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | chosen at keystore creation |

## Later: Play Store

One more step in the android job: `flutter build appbundle` with the same
flags, uploaded with a Play upload action using a service-account secret.
Nothing else changes.

## Out of scope

- Play Store publishing (see above).
- Desktop (Linux/Windows) release artifacts.
- Pre-release tags (`v1.4.2-beta.1`).
- Changelog files; GitHub's generated notes are enough.

## Verification

- `flutter analyze` clean, existing tests pass.
- Locally: Settings shows `Development build`; with
  `--dart-define=APP_VERSION=1.4.2 --dart-define=GIT_SHA=abc1234` it shows
  `1.4.2 · abc1234`, and tapping copies it.
- Locally: `flutter build apk --release` with a `key.properties` signs with the
  upload key (`keytool -printcert -jarfile` shows its SHA-1); without one it
  still builds (debug key); with `CI=true` and no file it fails.
- First real tag (`v1.0.0`): workflow green; site updated at
  `crsops.chiggydoes.tech` with the new version in Settings; GitHub Release has
  the APK; it installs and Google sign-in works.
