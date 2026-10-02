# CRS Ops — Supabase bootstrap runbook

One-time manual steps. Not an app feature — see Phase 1 plan Tasks 1 and 9.

## Project setup

- Hosted project ref: `ocalljagckzyvngprlxo` ("CRS Ops", org `victorious-apricot-fly`,
  South Asia/Mumbai) — already existed, linked this repo to it via `supabase link`.
- `core` schema migrations applied and verified against this real project (see git
  log / `OVERNIGHT_LOG.md` for what was checked).
- **Still needed from you** (dashboard actions, can't be done from here):
  - [ ] Enable Google as an Auth provider (Studio → Authentication → Providers →
    Google) — needs a Google Cloud Console OAuth client ID/secret first
    (APIs & Services → Credentials → OAuth client ID), with the Supabase-provided
    redirect URL added as an authorized redirect URI.
  - [ ] Expose `core` and `attendance` schemas via PostgREST (Studio → Settings →
    API → *Exposed schemas*) — otherwise every `.from()`/`.rpc()` call 404s even
    though the underlying tables/grants are correct.

## Bootstrap (one-time, manual — run against the HOSTED project, in this exact order)

1. In the Supabase SQL editor, before either of you has ever signed in:

   ```sql
   insert into core.allowed_signup_emails (email, note) values
     ('<your-email>', 'you'),
     ('<dads-email>', 'dad');
   ```

2. You and your dad each sign in once via the app (now permitted by the allow-list).

3. Still as you, in the SQL editor, grant roles:

   ```sql
   insert into core.user_roles (user_id, role_id, granted_by)
     select id, 'superadmin', id from auth.users where email = '<your-email>';
   insert into core.user_roles (user_id, role_id, granted_by)
     select u.id, 'admin', (select id from auth.users where email = '<your-email>')
     from auth.users u where u.email = '<dads-email>';
   ```

This cannot be done from the app itself — no superadmin is logged in yet to use an
in-app console. A "manage roles"/"manage allow-list" screen exists from Phase 6 onward
for every grant *after* this one-time step.

**Status:** not yet executed — requires Google OAuth provider setup (above) and the
sign-in screen (Task 19, written but not end-to-end tested — no real OAuth client
exists yet) to both work first, so you and your dad have something to sign in with.
Revisit once those exist.

## Legacy data import (one-time per cutover, manual — run against the HOSTED project)

Imports the old `crs_attendance` Firestore export into `core`/`attendance`. See
`docs/plan/2026-10-03-chore-import-legacy-attendance-data-plan.md` for the full design.

1. Generate the SQL from a fresh export: `dart run tool/generate_legacy_import.dart
   <path-to-export.json>` → writes `supabase/legacy_imports/<timestamp>.sql`
   (gitignored — contains real employee names/salaries, never commit it).
2. Review the generated file by hand, then paste it into Studio's SQL editor (or
   `supabase db execute -f <file>`). It's one transaction and self-verifies row counts
   against the source file before committing.
3. To re-import with a fresher export later, run `supabase/legacy_imports/undo.sql`
   first — deliberately, by hand — then repeat step 1 with the new export. The import
   refuses to run a second time without this (an empty-table guard), so this is the
   only way to re-run it. `undo.sql` truncates exactly three tables —
   `core.employees`, `core.employee_events`, `attendance.attendance_days` — the ones
   this tool writes. It deliberately does **not** use `CASCADE` and will error instead
   of running if `core.employee_ledger_entries` (the finance ledger, which this tool
   never touches) has any real rows by then.

- [ ] Ran the legacy data import (date: ______, export file: ______)
