# Overnight autonomous work log

Started 2026-09-20, after Chirag said: "take any decisions on your own as per your
info, log them alongside with any questions you have... don't block development
because of it... I hope to wake up to an app in the morning."

How to read this file: **Decisions** are things I picked myself and just proceeded
with — reasoning included so you can override if I got it wrong. **Blocked on you**
are things I genuinely cannot do without your action (an account login, a real
credential) — I built everything up to that boundary and kept going elsewhere rather
than stopping.

---

## Environment check (done)

- Flutter 3.47.5, Dart 3.13.4 available. All platform folders already scaffolded
  (android/ios/linux/macos/web/windows) from the original `flutter create`.
- Docker available — means I can run **local Supabase** (`supabase start`) and test
  real migrations/RLS against a real local Postgres, without needing your live cloud
  project or credentials.
- Supabase CLI was **not** installed — installed it myself via `mise use -g
  supabase@latest` (2.117.0). **Decision, not asking**: this is a local dev-tool
  install, not a state change to any account/service, so I didn't treat it as
  needing your go-ahead.

## Blocked on you (need your action, can't proceed past these myself)

- [ ] **Real Supabase cloud project.** I can't create one — needs your account login
  in a browser. I'm building and testing everything against **local Supabase**
  (Docker) in the meantime, so the moment you create the real project and give me
  its URL/anon key, migrations apply directly with no rework.
- [ ] **Google OAuth client ID/secret.** Needs registration in Google Cloud Console
  under your account. I'll build the sign-in code assuming this exists as config,
  but can't test a real Google sign-in end-to-end without it.
- [ ] **The two real bootstrap emails** (yours + your dad's) for
  `core.allowed_signup_emails` — I don't have these, so the bootstrap SQL will use
  placeholders you need to fill in before running it against the real project.
- [ ] **Supabase project + Google OAuth setup itself** — you said you'll do this
  yourself in the morning, so I'm not attempting it or local Docker-Supabase as a
  stand-in. Focus shifted to writing the actual code (SQL migration files + Dart) and
  making sure the Flutter app compiles, not standing up/testing infrastructure.

## Update: real Supabase access unblocked (Chirag logged in + linked)

Chirag ran `supabase login` himself and a real "CRS Ops" project already existed
(created 2026-09-19, ref `ocalljagckzyvngprlxo`, region South Asia/Mumbai — along with
`Test`, `Rough-CRSManager`, `CRSManager`, `AssetManager` in the same org). Linked this
repo to it (`supabase link --project-ref ocalljagckzyvngprlxo`) — connects over the
network to the real remote Postgres, no Docker/local Supabase needed at all. Confirmed
clean slate: `supabase migration list` shows zero migrations applied yet. **This fully
resolves the earlier Docker-permission blocker** — told him he doesn't need to run the
`usermod`/docker fix before sleeping, it's no longer needed.

From here: the Phase 1 migration gets genuinely applied and verified against this real
project (not just written-and-hoped), since we now have real access.

## Executing Phase 1's plan

Using `/superpowers:executing-plans` directly (not subagent-driven), per your
instruction. Working on branch `v1-implementation` (not `master`) since the skill
forbids building on master without explicit consent and you hadn't given that
specifically — plain feature branch, no separate worktree directory (this is a solo
overnight session, didn't seem worth the extra machinery).

**Adapting the plan's DB steps**: it was written assuming local Docker Supabase
(`supabase start`, `psql` against `127.0.0.1:54322`). Turned out not to matter —
`supabase db push --linked` applies migrations to the real hosted project directly
(no DB password needed, uses the CLI login token), and `supabase db query --linked`
runs arbitrary SQL against it the same way. So **every RLS/function verification in
Phase 1 actually ran for real against your live project**, not just written and
hoped — genuinely better than what the plan itself assumed was possible.

### Two real bugs found via that live verification (not caught by review alone)

1. **`core.employees.color` was `integer`** (Postgres signed 32-bit, max ~2.1
   billion) — but a fully-opaque Flutter `Color.value` (alpha=0xFF), e.g.
   `0xFF4CAF50` = 4,283,215,696, exceeds that. Every normal opaque color would have
   failed to insert. This was a bug in **`plan.md` itself** (said "color int"), not
   just the phase-1 plan's SQL — fixed both, migration column is now `bigint`.
2. **The whole `core` schema had RLS policies but zero `GRANT` statements** for the
   `authenticated` role — no `usage on schema core`, no `select/insert/update/delete`
   on any table, no `execute` on any function. RLS restricts *which rows* a role can
   see; it doesn't substitute for the underlying grant. Without this, **every single
   `.from()`/`.rpc()` call from a signed-in user would have failed** with "permission
   denied for schema core," regardless of how correct the RLS policies were. This
   wasn't in `plan.md`'s design at all — added `alter default privileges` too, so
   future `core`-schema additions (Phase 2 onward) get the same grants automatically
   without needing to remember this again.

Also fixed, found by Phase 2's plan-writing pass (not execution): `event_types`'s
insert/update RLS only checked `is_admin_or_above()`, not the superadmin-only
restriction the design calls for on structural (`active`/`inactive`-tagged) rows — a
plain admin could've inserted/edited one via a direct API call. Now: superadmin for
anything structural, admin-or-above still self-service for purely descriptive types.

All three fixes are in `supabase/migrations/20260919223550_...sql` and
`...223735_...sql` (kept as separate corrective migrations rather than editing
migration 1 in place, even though nothing had relied on it yet — better habit to
build now). **Verified against the real project after each fix** — allow-list
rejection, `employee_status_as_of` boundary semantics, `employee_timeline`
interleaving, module-access bypass/denial, the self-escalation-prevention case (the
old app's actual bug), and the corrected event_types split all pass for real. Test
data cleaned up afterward — the project is genuinely empty again, ready for your real
bootstrap.

### A fourth bug, in the Dart/Flutter code this time

`.from('<table>')` on a `SupabaseClient` defaults to the `public` schema — since
literally everything in this app lives in `core`/`attendance`, every repository call
needs `_client.schema('core').from(...)` (or `.schema('attendance')`) explicitly, or
it silently queries a table that doesn't exist. Caught this by checking the actual
installed `postgrest`/`supabase` package source (`~/.pub-cache/hosted/pub.dev/`), not
assuming — fixed `RolesRepository` in Phase 1, and found the **already-written Phase
2 plan** had baked in the same bug at scale (7 call sites, plus an incorrect comment
claiming Phase 1 sets a global default schema, which it doesn't) — fixed that plan
file directly before execution ever reached it. Worth double-checking Phase 3
onward's plans for the same pattern once they're written, especially `.rpc()` calls
into `attendance`'s functions, which need the same `.schema('attendance')`
qualification.

### A fifth bug: google_sign_in's API changed since the plan was written

The plan's Task 19 code used `GoogleSignIn(scopes: [...])` + `.signIn()` — that API no
longer exists in the installed `google_sign_in: 7.2.0`. Confirmed via the actual
package source (not guessing): it's now a singleton (`GoogleSignIn.instance`)
requiring a one-time `.initialize()` call, and `.authenticate()` replaces `.signIn()`
(throws `GoogleSignInException` instead of returning null on cancel). Fixed
`AuthRepository._signInWithGoogleNative` to match, with a memoized static Future
guarding the "call initialize exactly once" requirement. Still can't be tested
end-to-end without a real Android device + OAuth client ID, but it now at least
compiles against the real API instead of one that doesn't exist anymore.

### A sixth bug: the resolved Riverpod version is 3.x, plan code assumed 2.x

`flutter pub add` resolved `flutter_riverpod: 3.4.3` (a major version with real
breaking changes) — the plan's router code assumed 2.x's `FutureProvider` having both
`.future` and `.stream` modifiers, and `AsyncValue.valueOrNull`. Checked the actual
installed package source: in 3.x, generated function-style providers only expose
`.future` (no `.stream` at all), and `AsyncValue.valueOrNull` was renamed to plain
`.value` (still nullable). Fixed `app_router.dart` to bridge session changes to
`GoRouter`'s `refreshListenable` via `ref.listen` instead of a stream subscription
(version-safe regardless of provider type), and fixed the `.value` rename. Checked
Phase 2's already-written plan for the same patterns (`valueOrNull`, `.notifier`) —
clean, doesn't use them. Worth double-checking Phase 3 onward for the same thing once
written, especially anything touching `AsyncNotifier`/streams directly.

### Phase 1 complete — status summary

All 21 of Phase 1's 22 tasks are done and committed on branch `v1-implementation`
(Task 22, end-to-end manual verification, is blocked on real Google OAuth setup —
see below). Every task that could be verified for real, was: the full `core` schema
against your actual linked Supabase project (not a local stub), all unit/widget
tests (19 total, all passing), `dart analyze` clean across all of `lib/`, and a real
`flutter build web` succeeded end to end. Also found: `flutter build linux` needs
`cmake`, which isn't installed and I can't install without your sudo password —
**`flutter build apk --debug` succeeded** (downloaded and installed the Android NDK
+ a CMake copy inside the Android SDK's own managed directory automatically, no
sudo needed for that one since it's self-contained) — a real 176MB debug APK at
`build/app/outputs/flutter-apk/app-debug.apk`. **Then reused that same
Android-SDK-managed `cmake` binary (`/home/chiggy/Android/Sdk/cmake/3.22.1/bin`) by
prepending it to `PATH` for the Linux build too** — worked, `flutter build linux
--debug` succeeded, real executable at
`build/linux/x64/debug/bundle/crs_ops`. So no system-wide `cmake` install is
actually needed at all; that workaround covers it. **All three target platforms
(Web, Android, Linux) now build successfully, end to end, for real.**

**Six real bugs found and fixed tonight, via actually building/running things, not
just writing code and assuming it works:**
1. `core.employees.color` was `integer`, too small for an opaque Flutter color.
2. The entire `core` schema had RLS but no baseline `GRANT`s for `authenticated`.
3. `event_types` insert/update RLS didn't actually enforce the superadmin-only
   restriction on structural rows the design called for.
4. Every Dart repository's `.from()`/`.rpc()` call needs explicit
   `.schema('core')`/`.schema('attendance')` — bare calls silently target `public`.
5. `google_sign_in`'s API changed since the plan was written (no more
   `GoogleSignIn()`/`.signIn()`) — rewritten against the actual installed 7.x API.
6. The resolved Riverpod version is 3.x, not 2.x — `AsyncValue.valueOrNull` is now
   `.value`, and generated `FutureProvider`-style providers dropped `.stream`
   entirely (fixed the router's refresh bridge to use `ref.listen` instead).

Also fixed in passing: `Supabase.initialize`'s `anonKey` parameter is deprecated in
favor of `publishableKey` in the installed version.

**What's still genuinely blocked on you** (see the top of this file too):
- Google OAuth client registration (Google Cloud Console) + enabling the provider
  in Supabase Studio, and exposing `core`/`attendance` schemas via PostgREST
  (Studio → Settings → API) — both dashboard actions, can't be done from here.
- The real bootstrap (your + your dad's emails into the allow-list, then role
  grants) — needs the above to exist first so there's something to sign in with.
  `supabase/README.md` has the exact SQL ready to run, in order.

Once OAuth is set up, Task 22's remaining steps (sign-in rejection/acceptance,
`core.profiles` populating for real, unauthorized redirect, nav breakpoint on a
real running app) are straightforward to run through.

### Phase 2 (Employee core) in progress

Same rigorous approach continuing: real TDD, real `dart analyze`, real test runs.
Already fixed before execution (Task 6's repository code had the same
`.schema('core')` gap Phase 1's `RolesRepository` had — 4 of the 11 `.from()` calls
were split across lines, so an earlier same-line-only `sed` fix missed them; fixed
all of them properly this time).

**A seventh bug, in Task 10's own test**: `tester.enterText()` doesn't trigger a
widget rebuild by itself, so the save button's `onPressed` (recomputed each build
from the name controller's text) was still evaluated with the pre-edit empty text
when `tap()` fired immediately after — test failed with 0 employees saved instead
of 1. Fixed by adding `await tester.pump();` between `enterText` and `tap`.


## Scope correction (from Chirag, mid-session)

He clarified: focus on writing code and making sure it **compiles** — not setting up
or running local infrastructure for live integration testing overnight — and use
`/superpowers:executing-plans` for execution, not the subagent-driven-development path
I'd defaulted toward. He'll set up the real Supabase project/OAuth himself in the
morning.

I'd already run `supabase init` (just scaffolds the `supabase/` folder migrations live
in — needed regardless, per plan.md's own design) before this correction landed, and
briefly tried `supabase start` (hit a Docker permission issue — your user isn't in the
`docker` group; I can't `sudo` without your password) before stopping that line of
work per the correction. **Left alone, your call if you want it later**: `sudo
usermod -aG docker chiggy` then log out/in (or `newgrp docker`) would fix that if you
ever want local Supabase running.

---
