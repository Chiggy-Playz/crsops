# CRS Ops

Operations app for CRS: attendance today, with delivery challans and assets
to follow. Flutter (Android, web, Windows) on Supabase.

Live web app: <https://crsops.chiggydoes.tech>

## Stack

- **Flutter** 3.47.5, Material 3, Riverpod, go_router, dart_mappable
- **Supabase**: Postgres with RLS, Google sign-in, schemas `core` and
  `attendance` (see [`supabase/README.md`](supabase/README.md))
- **Hosting**: Cloudflare Worker serving the web build (`wrangler.jsonc`)
- **Releases**: GitHub Actions, on version tags

## Running locally

1. Copy `env.json.example` to `env.json` (git-ignored) and fill in the
   Supabase URL, publishable key and the Google **web** OAuth client ID.
2. Run:

   ```bash
   flutter run --dart-define-from-file=env.json          # pick a device
   flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json
   ```

Google sign-in on web returns to whatever origin started it, which must be in
Supabase → Authentication → URL Configuration → Redirect URLs
(e.g. `http://localhost:3000/**`). Desktop sign-in uses
`http://127.0.0.1:43823/**`.

Local builds show **Development build** in Settings → About.

### Code generation

Generated files (`*.g.dart`, `*.mapper.dart`, `lib/gen/`) are committed.
After changing providers, routes, models or assets:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Checks

```bash
flutter analyze
flutter test
```

## Releasing

The git tag is the version; `pubspec.yaml`'s version is a placeholder.

```bash
git tag v1.4.2
git push origin v1.4.2
```

`.github/workflows/release.yml` then:

- checks the tag is `vX.Y.Z` (minor and patch below 100) and all secrets are set
- runs analyze + tests, and in parallel builds the web app and signed APKs
- once checks pass, deploys web to the Cloudflare Worker and creates a GitHub
  Release with `crs-ops-X.Y.Z-arm64-v8a.apk` (most phones) and
  `-armeabi-v7a.apk` (older phones)

The version (`1.4.2`) and build number (`10402`) come from the tag; Settings
shows `1.4.2 · <commit>`.

**Build caches.** Tag runs can only reuse caches saved on `master`, so
`.github/workflows/warm-cache.yml` builds Android on `master` when
dependencies or build files change, weekly, and on demand. After changing
dependencies, push `master` and let it finish before tagging.

### Secrets (repo Settings → Secrets → Actions)

| Secret | Value |
|---|---|
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | as in `env.json` |
| `GOOGLE_SERVER_CLIENT_ID` | Google **web** OAuth client ("CRS Ops Supabase"), not an Android one |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | Workers deploy token + account ID |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 crs-ops-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | upload keystore credentials |

### Android signing

Release builds are signed with the upload keystore through
`android/key.properties` (git-ignored; CI writes it from secrets). Without it,
local release builds fall back to the debug key, and CI refuses to build.
The keystore's SHA-1 is registered as an Android OAuth client in Google Cloud;
Google sign-in fails in release APKs otherwise. Keep the keystore and its
password backed up.

## App icon

Sources are in `assets/branding/`. To change the icon, edit the SVGs, then:

```bash
cd assets/branding
for f in icon icon_foreground icon_windows; do rsvg-convert -w 1024 -h 1024 $f.svg -o $f.png; done
cd ../..
dart run flutter_launcher_icons
```

The web loading screen in `web/index.html` copies the app's theme colors;
`test/web/loader_colors_test.dart` fails if they drift.

## Docs

- `docs/superpowers/specs/`: design specs
- `docs/superpowers/plans/`: implementation plans
- `supabase/README.md`: database bootstrap runbook
