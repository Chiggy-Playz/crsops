# CRS Ops — Attendance/Employee Management Module (v1)

## Context

CRS Ops is a new Flutter app for Chirag's dad's business, replacing an old Flutter+Firebase
attendance app (`crs_attendance`) that had a real security bug (self-service admin
escalation in Firestore rules) and a data model too thin for real needs (a single
`disabled: bool` broke down once rehires mattered). This is a fresh `flutter create`
scaffold at `/home/chiggy/Projects/crs_ops` — no custom code exists yet.

**CRS = Computer Rental Services** — the business rents out computers, learned this
session. That's directly why the "asset" module means computer-hardware inventory
specifically (CPU/RAM/storage, serial numbers), not a mismatch needing generalizing to
"broader equipment" — it's literally the core business.

Attendance is module 1 of what will become a **multi-module** app. Confirmed in this
session, more concrete than "someday" (per the older `PROJECT_BRIEF.md` handoff doc): the
planned modules are **attendance** (this one), **challan** (recreating CRS Manager's
delivery-challan tracking inside this unified app, not just "an eventual merge"), and
**asset** (computer-hardware inventory — tracking, location, request/approval workflow,
audit log). Two prior real attempts at asset tracking exist, both never shipped to
production: a feature embedded in CRS Manager (abandoned, not representative of good
patterns), and a separate, more complete standalone app, `/home/chiggy/Projects/
asset_manager` (real releases, v1.1.0+3, Bloc-based, its own 17-migration Supabase
schema) — worth doing properly this time, in the new unified app, likely drawing on
`asset_manager`'s request/approval + audit-log + location-hierarchy patterns (and
definitely its self-hosted APK-update mechanism — see below) even though it never shipped
either. Employees will eventually get their own logins with access granted per-module.
That future shape — and specifically knowing challan and asset are real, named future
modules rather than a vague placeholder — is why auth/roles and the employee entity are
being designed as app-wide (`core/`) foundations now, confirmed in this session's
Flutter-structure discussion (`core/employees/`), not bolted onto attendance later.

Settled, not open for debate: Flutter (Android+Web+Desktop), Supabase/Postgres (separate
project from CRS Manager), Material 3 UI, Google sign-in via Supabase Auth (custom-styled
screen, not the old app's bare button), append-only event-log employee status.

**Deliberate architectural choice, not incidental**: business logic that must give the
*same* answer everywhere (effective status, week-off defaults, late/early/overtime, gaps)
lives in Postgres functions/views, not duplicated in Dart. The Flutter app is mostly UI +
`.rpc()`/`.from()` calls over what the database already computed. Chosen specifically so
the calendar, reports, and the gap-flag can never quietly drift apart from each other the
way three separate Dart implementations of the same rule eventually would — the tradeoff
being that a real chunk of this app's logic lives in `supabase/migrations/*.sql`, not just
`lib/`, and needs to be read/maintained as such.

New requirements driving this plan (from this session):
1. A **configurable set of week-off weekdays** defaults to week-off automatically
   (computed, never stored) — not hardcoded to Saturday+Sunday. Default is **Sunday
   only** pending confirmation with your dad; Saturday can be added to the config later
   with no code change if that turns out to be wrong.
2. No maintained holiday calendar — a "mark as company holiday" bulk action, usable on
   **any date** (past, today, or future) from the attendance-for-day screen, builds it up
   organically, alongside "mark all present." Not restricted to "today."
3. A day has exactly two independent halves — **first half and second half** — each with
   its own status. Nothing more granular than that.
4. Actual time-in/time-out entry, with late/early/overtime **derived** at read time
   against a default 10:30–18:30 shift — not stored as separate drifting fields. ("Derived"
   means: not its own database column, computed fresh each time from `time_in`/`time_out`
   vs. whatever the shift-default times currently are — so changing the default later
   recalculates every past day's flags automatically instead of leaving stale values.)
5. A manual, append-only **finance ledger** per employee (salary payments, advances,
   with notes) — explicitly *not* automated payroll computed from attendance.
6. Leave stays a single generic status with a free-text note for v1, but the status
   representation must be open-ended so specific leave types can be added later without
   a schema rewrite.
7. An app-wide RBAC foundation (admin vs employee roles, module-scoped access) that can
   never be self-granted — directly fixing the old app's escalation bug — even though
   only admin accounts (Chirag + dad) do anything in v1.

## Schema (Supabase/Postgres)

Two schemas: **`core`** (auth/roles/employees/finance — app-wide, reusable by future
modules) and **`attendance`** (attendance-specific transactional data only). This keeps
the module boundary real at the DB level, matching the Flutter-side module boundary below.

**Setup step, easy to miss:** Supabase only exposes the `public` schema via PostgREST by
default. In Studio → Settings → API → *Exposed schemas*, add `core` and `attendance`, or
`supabase_flutter`'s `.from()`/`.rpc()` calls will 404.

**Second setup step, easy to miss and found the hard way in this session** (via real
execution, not review — every RLS/function test failed with "permission denied for
schema core" until this was added): PostgREST exposure alone isn't enough. The
underlying Postgres `authenticated` role also needs actual `GRANT`s — RLS restricts
*which rows* a role can see, it doesn't substitute for baseline schema/table/function
privilege. Every migration that creates a new schema needs, once, near the top:
`grant usage on schema <schema> to authenticated;` plus `grant select, insert, update,
delete on all tables in schema <schema> to authenticated;` and `grant execute on all
functions in schema <schema> to authenticated;` — and `alter default privileges in
schema <schema> grant ... to authenticated;` so tables/functions added by *later*
migrations in the same schema inherit the grants automatically. No `anon` grants
anywhere in this app — everything requires sign-in, gated further by the allow-list.

**Design rule for categorical/open-ended values** (event type, attendance status, and
ledger entry type all needed this decided explicitly, in this session): a value earns its
own lookup table only when the app needs to read **attached metadata** off it — display
config (icon/color) or a classification flag (active/inactive). Open-endedness alone
doesn't require a table; a plain `text` column plus a UI that offers existing values
(dropdown-from-distinct, or a seeded dropdown) already prevents typos without a table, an
FK, or a migration to add a new value. Applied below: `event_types` and (new)
`status_types` are real tables, because both need metadata the UI reads; `entry_type`
stays plain text, because it needs none.

### `core` schema

- `core.allowed_signup_emails (email text primary key, note text, added_by, added_at)` —
  the signup allow-list (req. 7, extended in this session: RBAC alone stops an
  unauthorized user from *doing* anything, but Google OAuth via Supabase Auth still lets
  literally anyone create an `auth.users` row on first sign-in — this table closes that
  gap at the account-creation step itself, not just at the authorization step after).
  Seeded with your + your dad's email as part of bootstrap, **before** either of you signs
  in for the first time. Onboarding a real employee login later (module 2) is one SQL
  insert here, ahead of sending them the app — no dashboard settings to remember, no
  temporarily re-enabling public signups.
- `core.check_allowed_signup()` — a `before insert on auth.users for each row` trigger
  function that raises an exception (case-insensitive email match) if `new.email` isn't in
  `allowed_signup_emails`, rejecting the account creation outright. Fires for every auth
  method (Google OAuth included), unlike Supabase's dashboard-level "allow signups" toggle,
  which community reports show isn't reliably provider-agnostic across OAuth providers —
  a DB trigger doesn't depend on that.
- `core.profiles` — one row per Supabase Auth user (`id` FK → `auth.users`), auto-populated
  by an `on_auth_user_created` trigger (`security definer` function) on `auth.users` insert
  — only reachable at all once `check_allowed_signup` has let the row through.
- `core.roles` — lookup, seeded with three tiers: `superadmin` (you — full system control,
  including who else holds `admin`/`superadmin`), `admin` (your dad — full operational
  control over business data, day-to-day "boss" role), `employee` (future logins, scoped
  to whatever module access they're granted).
- `core.user_roles (user_id, role_id, granted_by, granted_at)` — **the role-granting
  table.** RLS: readable by the row's own user or an admin-or-above; **writable only by a
  superadmin** — not by a plain admin. This is deliberate, not an oversight: your dad
  (admin) can run the business day-to-day, but promoting someone to `admin` or
  `superadmin` is a higher-stakes action reserved for you, so a compromised/mistaken admin
  action can't escalate further. This is the direct fix for the old Firestore bug, applied
  one level stricter than a flat "any admin can grant roles" would be.
- `core.modules (id, name, description)` — registry, seeded with `('attendance', ...)`.
- `core.module_access (user_id, module_id, granted_by, granted_at)` — foundation for
  "employee X can access module Y." Unlike `user_roles`, this **is** writable by
  admin-or-above (your dad deciding which employees get access to which module later is
  exactly the operational call he should be able to make himself, per your earlier note)
  — just never self-service by the employee being granted access.
- `core.employees (id, user_id nullable FK, name, color bigint, salary numeric, notes,
  created_at)` — `user_id` is nullable now, filled in later when an employee gets a
  login. **`color` is `bigint`, not `int`** (found via real execution during Phase 1
  implementation, not just review): a fully-opaque Flutter `Color.value` (alpha=0xFF),
  e.g. `0xFF4CAF50` = 4,283,215,696, exceeds signed 32-bit `integer`'s ~2.1 billion
  max — every normal opaque color would fail to insert with plain `int`.
- `core.event_types (id text primary key, status_effect text check (status_effect in
  ('active','inactive')) null, icon_name text, color_hex text, description text)` — the
  known vocabulary of event types. `status_effect` is `null` for purely descriptive types
  (`promotion`, `note`, ...) and `'active'`/`'inactive'` for the handful that change an
  employee's derived status (`joined`/`rehired` → active, `left` → inactive). `icon_name`/
  `color_hex` drive the timeline UI's look per type — DB-configurable so a type's display
  can be set or changed via SQL, no app release needed (see Dart-side note below on how
  `icon_name` resolves to an actual icon). **Two different people write to this table,
  deliberately:**
  - The `active`/`inactive`-tagged rows are seeded once in the schema migration, by you,
    with real `icon_name`/`color_hex` values. Deciding a label changes what "active"
    *means* is a structural decision, not routine data entry — your dad never adds one of
    these himself.
  - Purely descriptive rows (`status_effect = null`) are **self-service for admin-or-above**
    — your dad can type a brand-new label (`warning`, `salary_revision`, whatever comes up)
    straight from the "Add event" dialog on the employee page; the app inserts it into
    `event_types` with `status_effect = null` and `icon_name`/`color_hex` left `null`
    (renders with a generic fallback icon/grey until you optionally give it a real look via
    SQL) the first time it's used, then it's just available in the dropdown afterward. No
    SQL required to use it; SQL only needed later if you want to style it properly.
- `core.employee_events (id, employee_id, event_type text references core.event_types(id),
  event_date, note, created_by, created_at)` — append-only. `event_type` has an **FK to
  `event_types`**, not a free-floating string — this is what makes the "open-ended" design
  safe rather than typo-prone: an unknown type is rejected at insert time (no silent
  `'Left'` vs `'left'` mismatch), while adding a genuinely new type is still just an insert
  into `event_types`, never an `ALTER TYPE` migration.
- `core.employee_current_status` — a **view** joining `employee_events` to `event_types`,
  filtering `where status_effect is not null`, taking the latest by `event_date` per
  employee. Active/inactive is derived entirely from data in `event_types`, so a future
  status-affecting type (e.g. `resigned` → inactive) needs one migration inserting one row
  — the view's logic itself never changes.
- `core.employee_status_as_of(p_employee_id, p_date)` — a **function** answering "was this
  employee active on this specific past date?", built from **inclusive intervals**: each
  `joined`/`rehired` event opens an active interval running through the *next* `left`
  event's date (both endpoints inclusive), or through today if there isn't one yet.
  Confirmed boundary semantics: `rehired`'s date is the first active day back; `left`'s
  date is the last working day, still active/markable, with inactive starting the day
  after. This is what makes attendance queries join-date-aware (see `effective_range_status`
  below) — someone who joined Wednesday never gets treated as "employed but unmarked" for
  Monday or Tuesday, and the gap between a `left` and a later `rehired` is correctly
  excluded entirely, not shown as missing attendance.
- `core.employee_ledger_entries (id, employee_id, entry_date, amount numeric, entry_type
  text, note, created_by, created_at)` — the finance ledger (req. 5). `entry_type` stays
  plain `text` with **no lookup table** — unlike `event_type`/attendance status, it carries
  no metadata the app needs to read (no icon/color, no active/inactive-style
  classification), so a table would add a migration + FK for no functional gain. Typo
  safety instead comes from the UI: the "Add payment" dialog offers a dropdown of
  `select distinct entry_type from core.employee_ledger_entries order by 1` plus an
  explicit "add new" option, so your dad picks an existing category rather than retyping
  it, while a genuinely new one is still just a keystroke away.
- `core.employee_timeline` — a **view** `union all`-ing events and ledger entries by date,
  so the employee detail screen renders one ordered list from one query.

### `attendance` schema

- `attendance.shift_defaults (id, effective_from date, default_start time, default_end
  time, week_off_days smallint[], created_by, created_at, unique(effective_from))` —
  **append-only, not a singleton.** Seeded with one row, `default_start = 10:30`,
  `default_end = 18:30`, `week_off_days = '{7}'` (Sunday only) — confirmed to hold for all
  of history being imported from `crs_attendance`, not just going forward. **`effective_from`
  must predate the oldest imported attendance record** (not "launch date" — a real gap
  caught in this session: every `shift_defaults` lookup is `largest effective_from <= the
  date being evaluated`, so a launch-dated seed row would leave every imported historical
  date with zero matching rows, breaking `effective_range_status`/`derived_flags` on
  exactly the data being migrated in). Use a safe sentinel like `2000-01-01`, well before
  any real employee's join date, rather than trying to pin an exact "always been true
  since" date. Changing the shift hours or week-off days later **inserts a new row** with
  `effective_from` = the date the change takes effect — it never edits an existing row.
  This matters concretely:
  if a day was evaluated as "on time" under the rule active that day, a rule change next
  week must never retroactively relabel it late. Every lookup picks the row with the
  largest `effective_from <= the date being evaluated` (a `lateral` join per date, not a
  single fixed join), so historical days keep the rule that was actually in force then.
- `attendance.status_types (id text primary key, label text, icon_name text, color_hex
  text, description text)` — the known vocabulary of attendance statuses (`present`,
  `absent`, `leave`, `holiday`, `week_off`, ...), seeded once with the v1 set. This
  **needs** a real table (unlike `entry_type` above) because the day-view/reports UI reads
  `icon_name`/`color_hex` per status to render it — a plain-text column has nowhere to
  attach that metadata. DB-configurable so a future `leave_sick` is a SQL insert (with its
  own icon/color), not a code change — the app fetches this table once, cached
  client-side, and renders any row it finds, including ones added after the app was last
  built. Entry is always dropdown-driven from this table, never freeform typing, so
  there's no typo risk to guard against separately.
- `attendance.attendance_days (id, employee_id, date, first_half_status text references
  attendance.status_types(id), second_half_status text references
  attendance.status_types(id), time_in time, time_out time, note, created_by, updated_at,
  unique(employee_id, date))` — one row **only when something was explicitly marked**;
  week-off days and unmarked days have no row (req. 1 — computed, not stored).

**Effective status and derived flags are SQL functions**, called via `.rpc()`, so the
day-view and the reports view share one implementation and can't drift apart:

- `attendance.effective_range_status(p_start date, p_end date, p_employee_id uuid default
  null) returns table (employee_id uuid, date date, first_half_status text,
  second_half_status text, is_explicit boolean, is_week_off boolean, time_in time, time_out
  time, note text)` — cross-joins `core.employees` (filtered first to `p_employee_id` when
  given, so the cross-join is against one row, not all of them) with `generate_series
  (p_start, p_end, '1 day')`, **filtered to dates where `core.employee_status_as_of(e.id,
  d.date) = 'active'`** (an employee who joined mid-range simply doesn't generate rows for
  the days before they existed), left-joins `attendance_days`, and for each remaining date
  `d` does a `lateral` lookup of the `shift_defaults` row with the latest `effective_from <=
  d` to get *that date's* `week_off_days` before applying `extract(isodow from d) = any
  (week_off_days)` — never the current/latest config applied blindly to every date. `null`
  (all employees) serves the calendar and attendance-for-day screens; a real id serves a
  reports screen scoped to one employee, computed server-side instead of fetched-then-
  discarded client-side. Deliberately **no single rolled-up "day status" column** — just
  the raw facts (`first_half_status`/`second_half_status`/`is_explicit`/`is_week_off`
  independently); this keeps the open "how does a mixed present/absent half-day roll up in
  a report summary count" question (see Screens) fully decoupled from this function, free
  to be answered per-screen (or changed later) without touching the source of truth. This
  one function is the single source of truth for "what does this employee's status look
  like on this date," reused by the Calendar screen, reports, and the gap indicator below —
  fixing it here fixes it everywhere, nothing can drift out of sync between those three
  surfaces.
- `attendance.recent_gaps(p_window_days integer default 7) returns table (employee_id uuid,
  date date)` — the **passive, ambient version** of "what's unmarked," strictly bounded to
  a short trailing window (today minus `p_window_days` through yesterday). "Today"/
  "yesterday" are computed as `(now() at time zone 'Asia/Kolkata')::date` inline — the
  business is India-only and IST has no DST to drift across, so this needs no
  database-wide timezone setting, just an explicit conversion at the one place "today" is
  evaluated (confirmed in this session over just hardcoding a UTC+5:30 interval add, for
  the same result but self-documenting intent). It's a thin filter over
  `effective_range_status`'s own output — rows where `not is_explicit and not is_week_off`
  (i.e. a real working day for an active employee, with no record at all — no single
  "status" field needed for this check) — so it can never disagree with what the
  calendar/reports already show. The short window is deliberate: it answers "did I forget
  something *recently*," not "audit my entire history," so pre-existing old gaps in the
  data never get flagged as nags — they simply age out of the window. An explicit
  **report** run over an older range still shows its accurate unmarked count regardless of
  age (see Screens) — that's a deliberate ask, not a nag, since you went and requested it.
  Only ever called with the default 7 in v1 (the Calendar screen's "last 7 days" marker) —
  `p_window_days` stays a parameter rather than a hardcoded `7` purely so a future
  "configurable nag window" setting costs nothing to add later.
- `attendance.derived_flags(p_start date, p_end date, p_employee_id uuid default null)
  returns table (employee_id uuid, date date, time_in time, time_out time, worked_minutes
  integer, is_late boolean, is_early boolean, overtime_minutes integer)` — late/early/
  overtime, queried directly off `attendance_days` (not routed through
  `effective_range_status`, and **not** filtered by `employee_status_as_of` — an old record
  from when someone was still active must still get scored even if they've since left).
  **Scoped to `where time_in is not null or time_out is not null`** — its only consumer is
  the Reports screen's late/early/overtime drill-down (an exceptions list), and most days
  get marked via the simple no-time-entered "just present" flow (req. 4), so a fully
  time-less day produces no row at all rather than a trivial all-on-time one; this also
  matters for performance, since most `attendance_days` rows will have no time data. A
  **partial entry** (only one of `time_in`/`time_out` set) still produces a row: the
  missing side is assumed on-time using *that date's* `shift_defaults` (`default_start`/
  `default_end` via the same `lateral` lookup, never a hardcoded literal), so it can never
  itself trigger a late/early flag, while the side with real data still computes normally
  (e.g. `time_in` set, `time_out` missing → `is_early` is always `false` for that row, but
  `is_late`/`worked_minutes`/`overtime_minutes` compute off the real `time_in`). Per-date
  `lateral` lookup into `shift_defaults` throughout, same as everywhere else (a shift-time
  change only affects days from its `effective_from` onward, never earlier ones), and the
  same optional `p_employee_id` filter as `effective_range_status` for the same reason.
  **Overnight-shift correctness fix:** an overnight shift (e.g. `time_in = 10:30`, `time_out
  = 01:00` the next day, from your "morning guy working till 1am" example) has `time_out <
  time_in` as bare `time` values. The function must detect that case and add 24h before
  computing `worked_minutes`, and must suppress `is_early` when it fires — otherwise a
  genuine massive-overtime day would be misreported as "left early."

**Performance, checked explicitly in this session** (small business, but must not degrade
as attendance history accumulates over years): the risk isn't the `employees`/`generate_
series` cross-join itself (tiny, or filtered to one row via `p_employee_id`) — it's that
`effective_range_status`/`derived_flags` call `core.employee_status_as_of(e.id, d.date)`
once per `(employee, date)` row, and an unfiltered "all employees, long range" report could
mean tens of thousands of calls. Each call is cheap **only** with the right index behind
it, so the migration must include:
- `create index on core.employee_events (employee_id, event_date);` — without this,
  `employee_status_as_of` scans the *entire* events table on every call instead of a tiny
  per-employee slice, and that scan cost grows with total history across all employees, not
  just the one being queried.
- `attendance.attendance_days` already gets an index for free from its `unique(employee_id,
  date)` constraint — no separate index needed there.
- All four functions (`employee_status_as_of`, `effective_range_status`, `recent_gaps`,
  `derived_flags`) should be declared `STABLE` (they only read data, never write) rather
  than the default `VOLATILE`, so Postgres's planner can optimize them more aggressively.

These land as part of the actual migration SQL, not now — noting them here so they aren't
lost before that point.

### RLS pattern

Three `security definer` SQL functions (avoids RLS recursively re-checking itself):
`core.is_superadmin()`, `core.is_admin_or_above()` (`superadmin` or `admin`), and
`core.has_module_access(p_module)`. General shape: **admin-or-above has full read/write on
business data (employees, attendance, finance ledger, module_access); only superadmin can
write `user_roles`; a non-admin (future employee login) can only read rows linked to their
own `user_id`** — nothing is self-service-writable at any tier.

**Bootstrap, by design, needs manual steps**: the first superadmin can't grant themselves
the role through the app (that's the point), and now neither of you can even *sign in* the
first time without being allow-listed first. Order matters:
1. In the Supabase SQL editor, before either of you has ever signed in:
   `insert into core.allowed_signup_emails (email, note) values ('<your-email>', 'you'),
   ('<dads-email>', 'dad')`.
2. You and your dad each sign in once (now permitted).
3. Still as you, grant roles: `insert into core.user_roles (user_id, role_id, granted_by)
   values ('<your-uid>', 'superadmin', '<your-uid>')`, then `insert into core.user_roles
   (user_id, role_id, granted_by) values ('<dad-uid>', 'admin', '<your-uid>')`.

Document this in `supabase/README.md` as a one-time runbook, not an app feature. (A "manage
roles"/"manage allow-list" screen for you to do steps 1 and 3 without SQL is a reasonable
later addition, not needed for two people.)

Check all SQL into `crs_ops/supabase/migrations/*.sql` via the Supabase CLI
(`supabase migration new core_and_attendance_schema`) so it's versioned, not only pasted
into the hosted SQL editor.

## Flutter app structure

Keep **Riverpod + `riverpod_generator` + `go_router` + `dart_mappable`** — same patterns
as `crs_attendance`, still idiomatic. Swap `cloud_firestore`/`firebase_auth`/
`google_sign_in`-only for **`supabase_flutter`**.

**Reconsidered against Bloc/Cubit in this session, confirmed Riverpod.** Checked CRS
Manager's actual code (not just assumed) as a possible consistency argument: it turns out
to use neither Bloc nor Cubit — it's the plain `provider` package with one large
`ChangeNotifier` "god object" holding all app state as public mutable fields, plus
hand-written mutable models (no `freezed`/`dart_mappable`/codegen at all). Since CRS
Manager is stable and effectively unmaintained (no recent commits) and its pattern isn't
one worth mirroring anyway, consistency-with-it was dropped as a factor entirely — this is
decided purely on what fits CRS Ops. Riverpod wins on its own merits: this app's actual
complexity (status computation, shift history, derived flags) is deliberately server-side
(see the functions above), so the Flutter layer is mostly async fetch/display/mutate, not
client-side state machines — exactly Riverpod's strength, via composable, independently
testable providers (`ProviderContainer` needs no widget tree to test) rather than one
shared mutable object. Bloc's Event/State formalism earns its ceremony for screens with
many enumerable transitions; nothing currently planned here looks like that shape.
`dart_mappable` stays for models — `freezed` was only worth considering as a Bloc-state-class
pairing, which is moot now.

**Two flagged package/approach decisions, defaulted rather than re-asked:**
- **Calendar**: use `table_calendar` (MIT) instead of `syncfusion_flutter_calendar` (the
  old app's choice, which needs a Syncfusion community license). A month view + tap-a-day
  + colored status dots doesn't need Syncfusion's extra features. Revisit only if a v2 need
  for richer calendar UI shows up.
- **Google sign-in per platform**: native `google_sign_in` (ID-token flow into
  `supabase.auth.signInWithIdToken`) on Android; Supabase's `signInWithOAuth` browser-
  redirect flow on Web and Linux desktop. Validate this split with a small spike at the
  start of Phase 0 before building the full sign-in screen around it.

**Logging & error handling** (added this session, foundational — set up in Phase 1, used
by every phase after): `talker`, with `talker_riverpod_logger` to automatically log
provider/state changes and errors, and `talker_flutter`'s `TalkerScreen` exposed as a
hidden **"View logs"** entry in Settings' admin console (admin-or-above), so if something
breaks for your dad on his device, he can open it and screenshot/describe what's there
instead of you needing a debugger attached to diagnose it remotely. **Persisted to local
disk** (talker's file-output support, cheap — a few lines), not memory-only, so a genuine
hard crash — the case this feature exists for — doesn't wipe the very log you needed.

Distinct from logging itself: **`core/errors/`** holds a sealed `AppException` type and a
translator mapping raw exceptions (`PostgrestException`, `AuthException`, socket/network
errors) to a short, human-readable message a screen can actually show — "no internet
connection, check your connection and try again" instead of a raw stack trace or a silent
failure. The repository layer catches specific exceptions, logs the full technical detail
via `talker` (for you), and returns/rethrows the translated `AppException` (for whoever's
using the app in the moment) — every repository call some UI awaits should end in either a
successful result or a friendly, specific error, never an unhandled crash or a screen that
just quietly does nothing.

**Offline as its own state, not just another error**: `connectivity_plus` distinguishes
"you're not online at all" from "this one request failed for some other reason." A genuine
no-internet state gets a dedicated full-screen treatment (icon, "No internet connection,"
a retry button) — the same category as Chrome's offline dinosaur or Gmail's offline
banner — rather than a generic error `SnackBar`. This app is **online-only by design** (no
offline-first caching) — a deliberate, conscious choice for a wifi'd office, not an
oversight.

**Every async screen needs four states**, not just success: loading, error (via
`AppException` above), empty (e.g. "no employees yet" — distinct from a spinner and from a
crash), and offline. Stated explicitly here so it isn't accidentally skipped
screen-by-screen during the polish phase.

**English only** — confirmed this session, no Hindi/localization support needed.

**Auto-updates, direction confirmed, full design deferred**: **Shorebird** (production-
ready on Android/iOS/Windows/Linux/macOS as of 2026) as the primary update path — patches
Dart-code changes to already-installed apps with no app-store review. It can't patch
native-level changes (new plugin, new permission, engine bump) — those rare releases still
need a full rebuild, distributed via a self-hosted fallback mechanism, not the everyday
path. Web needs neither — a redeploy just *is* the new version.

**The fallback mechanism already has a validated reference implementation** — checked in
`asset_manager` this session (never shipped to production itself, but the update mechanism
specifically is solid, real, working code): a **private** Supabase Storage bucket
(`app-updates`) holds the APK plus a `metadata/latest.json` (`{apkPath, versionCode,
versionName, sha256}`); a Supabase **Edge Function** (`check-update`) authenticates the
caller's JWT and returns a **15-minute signed URL** for the APK rather than exposing the
bucket publicly; the client compares `versionCode` against `package_info_plus`'s installed
build number, downloads via `dio` with progress, then installs via `open_filex`
(`REQUEST_INSTALL_PACKAGES` permission). Worth porting this pattern rather than
redesigning it. **One gap to fix when porting it**: the old code fetches `sha256` but never
verifies the download against it — a corrupted/tampered APK could get installed silently;
add the verification this time. **One thing not present to build fresh**: there's no
upload-side tooling in the old repo — getting a new build + `latest.json` into the bucket
was a manual step there, and would need at least a small script here too.

```
lib/
  main.dart
  app.dart                          # MaterialApp.router + Material 3 theme
  bootstrap/supabase_bootstrap.dart
  core/                             # app-wide, shared by every module
    data/supabase_client_provider.dart
    auth/
      models/app_session.dart       # profile + roles + module access (dart_mappable)
      repositories/{auth,roles}_repository.dart
      providers/{auth_state,session}_provider.dart
      pages/{sign_in,unauthorized,loading}_page.dart
    employees/                      # moved here from modules/attendance/ this session —
                                     # core.employees/employee_events/employee_ledger_entries
                                     # are app-wide at the DB level (future module 2 needs
                                     # them too), so the Dart side matches from day one
                                     # instead of a later move + import rewrite
      models/                       # employee, employee_event, employee_ledger_entry,
                                     # event_types metadata (icon_name/color_hex) — status_types
                                     # is attendance-schema, its model lives in modules/attendance
                                     # instead, see below
      repositories/
      providers/
      pages/{employee_list,employee_edit,employee_detail}_page.dart (+ widgets/)
    router/app_router.dart          # merges each module's routes.dart, gates by module access;
                                     # includes core/employees' routes directly, ungated by any
                                     # module (managing employees isn't attendance-specific)
    theme/app_theme.dart
    widgets/                        # shared async-state/empty-state widgets, status_metadata.dart,
                                     # adaptive_nav_scaffold.dart (see below)
  modules/
    attendance/
      models/                       # attendance_day, attendance_status, shift_defaults
      repositories/                 # one per model above
      providers/
      pages/
        calendar/calendar_page.dart
        attendance_day/attendance_day_page.dart (+ widgets/)
        reports/report_page.dart (+ widgets/)
      routes.dart
    settings/
      pages/settings_page.dart      # + admin_console/ subpages, see Screens
      routes.dart
```

**Module boundary rule**: modules depend on `core/`, never on each other. Each module
exposes one `routes.dart`; `core/router/app_router.dart` merges them and gates each
`StatefulShellBranch` on `session.hasModuleAccess('<module_id>')`. Adding module 2 later
means adding `lib/modules/<name>/` and one line in `app_router.dart`. `core/employees`'
routes are the one exception to the gating rule — included directly, not behind a specific
module's access check, since employee management is a core capability every module may
need, not attendance-specific content (doesn't change v1 behavior, since only admin/
superadmin exist and RLS already grants them full access regardless).

**Navigation shell — adaptive, one destination per module, decided this session.**
Bottom `NavigationBar` on compact width (<600dp, phones), `NavigationRail` on medium/
expanded width (≥600dp, tablets/desktop/web) — Material 3's standard breakpoints.
`flutter_adaptive_scaffold` (the package that would normally provide this) was officially
discontinued by Google in April 2025; rather than depend on a community fork of uncertain
longevity for what's genuinely a small amount of logic, hand-roll a thin
`core/widgets/adaptive_nav_scaffold.dart` choosing between the two stock (non-deprecated)
Material widgets based on width.

**Destinations = one per accessible module, plus core sections** (`Employees`,
`Settings`) — never one per screen. A module's own subpages (attendance's `Reports`,
`Attendance-for-day`) are nested routes reached by in-page navigation *within* that
module's `StatefulShellBranch`, not additional top-level nav items — this is what keeps
the nav from growing unboundedly as a module gains screens. Confirmed concretely for the
planned roadmap: adding the **challan** module later means one new folder
(`lib/modules/challan/`), one new router line, and exactly **one** new nav item
("Challans") — its own subpages (list/detail/new/search, and **buyers**, which are
challan-specific, not shared with any other module — nothing else needs buyer data the
way multiple modules need employee data) all nest inside that one branch. Full nav
destination list across the whole known roadmap (attendance + challan + asset, per the
Context section above) is **Calendar, Challans, Assets, Employees, Settings — five**,
right at Material's practical ceiling for a clean bottom nav bar before needing an
overflow pattern, but this is a closed, known roadmap (not an open-ended growing app), so
five is plausibly the permanent final count, not a scaling problem to solve now.

**The nav only mirrors RBAC for UX — it is never the actual enforcement.** Destinations
are computed from `AppSession` (role + `module_access`): a module's branch renders only if
`session.hasModuleAccess('<module_id>')`; `Employees` only if `session.isAdminOrAbove`.
This exists so a user isn't shown things they can't use, nothing more — the real boundary
is RLS (already designed above), which rejects unauthorized reads/writes regardless of
what any client renders.

**Extensible status/event values (Dart side)**: don't wrap `first_half_status`/
`second_half_status`/`event_type` in `dart_mappable` `enum`s — those throw on an
unrecognized string, which is the exact "painful to extend" trap the DB design just
avoided. Model them as plain `String`s.

Display metadata (label/icon/color) for these now lives in `attendance.status_types`/
`core.event_types` themselves (fetched once per session, cached via a Riverpod provider —
e.g. `statusTypesProvider`/`eventTypesProvider`), so Dart doesn't hardcode a
status-to-metadata map at all. What Dart *does* still need is a small fixed lookup from the
DB's `icon_name` string to an actual `IconData` constant — Flutter can't render an
arbitrary icon from a string, so `icon_name` values are drawn from a known, curated set,
with a graceful fallback for anything outside it:

```dart
const _iconByName = <String, IconData>{
  'check': Icons.check,
  'close': Icons.close,
  'event_busy': Icons.event_busy,
  'beach_access': Icons.beach_access,
  'weekend': Icons.weekend,
  // extend as new icon needs come up; an unrecognized name falls through below
};

IconData iconFor(String? iconName) => _iconByName[iconName] ?? Icons.help_outline;

Color colorFor(String? colorHex) => colorHex == null
    ? Colors.grey
    : Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));
```

A brand-new `status_types`/`event_types` row (say `leave_sick`, orange, a beach icon) shows
up correctly the moment it's inserted via SQL — no app release — **as long as its
`icon_name` is already in `_iconByName`**; a genuinely new icon name still needs a one-line
Dart addition, but the status/event *type itself* never does.

`entry_type` needs no such lookup — it has no metadata, so the UI renders it as plain text
straight from `select distinct entry_type from core.employee_ledger_entries`.

## Screens (v1)

- **Sign-in** — redesigned this session (the old app was a bare button on a blank page):
  centered card (max-width ~400-480px on wide/desktop windows, not stretched edge-to-edge),
  app icon/wordmark + short tagline, one prominent `FilledButton.icon` "Continue with
  Google" with a proper G mark, using Material 3's seed-color-derived scheme for the
  background/surface treatment rather than custom art.
- **Calendar** (renamed from "Home/calendar" this session) — month view, day cells show
  computed summary (week-off greyed, holiday-colored, mixed-status badge), plus a small
  gap-warning marker (via `attendance.recent_gaps`) on any of the **last 7 days** that
  still has an active, unmarked employee — nothing older is ever flagged, so pre-existing
  history isn't a wall of nags; tap a day → attendance-for-day. This is attendance
  module's nav destination (see Flutter app structure above).
- **Attendance-for-day** — works on any date reached via the calendar (past, today, or
  future), with a bulk action bar ("Mark all present," "Mark day as company holiday," both
  behind a confirm dialog since they overwrite) above a per-employee list: quick
  full-day tap-to-present, expandable first-half/second-half split, and an advanced section
  for time-in/time-out + note.
- **Employee list** — searchable, color swatch, derived status badge, FAB to add.
- **Employee create/edit** — name, color picker (port `ColorListTile` pattern from the old
  app), optional salary, notes; creating an employee also inserts an initial `joined` event.
- **Employee detail/timeline** — derived status chip header, one ordered list from
  `core.employee_timeline` (events + ledger entries merged), "Add event" and "Add payment"
  dialogs (the latter: amount, date, type, note).
- **Reports** — date range + employee filter; status-count summary cards via
  `effective_range_status` (present/absent/leave/holiday/week-off, plus an explicit
  **"X days unmarked"** count — shown regardless of how old the range is, since you asked
  for this range on purpose), late/early/overtime drill-down via `derived_flags`. **Open
  product question, not blocking build**: how a first-half-present/second-half-absent
  mixed day should roll up in the summary counts — worth a quick call with your dad once
  this screen exists, not before. **PDF/CSV export** (confirmed this session as a likely
  near-future need, not blocking v1 — a business tracking payroll-adjacent data will
  plausibly need to hand a report to an accountant or keep an exportable record):
  `effective_range_status`/`derived_flags` already return plain structured data rather
  than anything tangled up with widget rendering, so adding an export button later is
  additive, not a rework.
- **Settings** — theme toggle, sign out, plus an **admin console** section (added this
  session — replaces most of the manual-SQL config workflow with in-app screens for
  superadmin/admin, per your stated preference to avoid opening Supabase yourself for
  routine config):
  - **Signup allow-list manager** (superadmin) — add/remove `core.allowed_signup_emails`
    rows.
  - **Roles manager** (superadmin) — grant/revoke `admin`/`superadmin` per user.
  - **Module access manager** (admin-or-above) — grant an employee login access to a
    module.
  - **Shift-defaults manager** (admin-or-above) — view history, add a new effective-from
    row (start/end time, week-off days) instead of a raw SQL insert; past days are
    unaffected, per the `shift_defaults` design above.
  - **Attendance status-types manager** (admin-or-above, fully self-service — no
    structural risk unlike event types) — add/edit a status's label/icon (from the curated
    `_iconByName` set)/color.
  - **Event-types manager** (superadmin for anything `active`/`inactive`-tagged, since
    that's the structural "changes what active means" decision from req. 7; purely
    descriptive types stay self-service via the existing inline "Add event" dialog, so this
    screen is mainly for icon/color edits and adding a new status-affecting type).
  - **View logs** (admin-or-above) — `talker_flutter`'s `TalkerScreen`, so your dad can
    show you what actually happened on his device when something breaks, without you
    needing a debugger attached.

  **One unavoidable exception, inherent to the bootstrap problem**: the very first
  superadmin grant and the first two allow-listed emails (you + your dad) can never happen
  through this console, since no superadmin is logged in yet to use it — that one step
  stays manual SQL exactly as described in the RLS/Bootstrap section above. Everything
  after that bootstrap moment can go through these screens instead.

## Build order

**Rewritten this session** to reflect everything decided above (allow-list bootstrap
order, `core/employees` location, the four functions' final shape + indexes, and the
admin-console screens interleaved into the phase that builds their underlying feature,
rather than bolted on as one big phase at the end):

1. **Foundation** — Supabase project + Google OAuth provider; `core`/`attendance` schema +
   RLS + helper functions + the `employee_events(employee_id, event_date)` index + `STABLE`
   markings, in `supabase/migrations/`; `core.allowed_signup_emails` +
   `check_allowed_signup` trigger; manual bootstrap **in order** (allow-list insert → you +
   dad sign in → role grants); `core/auth` skeleton and router redirect logic; the adaptive
   nav shell (`core/widgets/adaptive_nav_scaffold.dart`) wrapping the authenticated route
   tree; redesigned sign-in screen; `talker` + `core/errors/` exception translation set up
   here so every later phase's repositories use it from day one, not retrofitted. *Verify*:
   sign-in attempt from a non-allow-listed email
   is rejected; sign in on `-d chrome` and `-d linux` for allow-listed accounts;
   `core.profiles` auto-populates; router bounces an unrecognized/no-role user to
   "unauthorized"; nav shell switches bottom-bar ↔ rail correctly at the 600dp breakpoint.
2. **Employee core** — models/repositories/providers for `Employee`/`EmployeeEvent` in
   `core/employees/` (not `modules/attendance/` — moved this session); list/edit/detail
   pages (timeline = events only for now); **event-types manager** admin screen
   (superadmin: active/inactive-tagged types + icon/color edits on any type). *Verify*:
   manual CRUD; confirm a non-admin test account can't write via a direct
   `.rpc()`/`.from()` call.
3. **Attendance marking** — `AttendanceDay`/`ShiftDefaults` models, `attendance.status_types`
   table + seed, `effective_range_status`/`recent_gaps` functions, bulk-action repository
   methods, attendance-for-day page, wire Calendar to real data; **shift-defaults manager**
   and **status-types manager** admin screens (admin-or-above, fully self-service for
   status types per this session's design). *Verify*: explicit marking on a configured
   week-off day overrides the default; an untouched non-week-off day shows "unmarked"; the
   midnight-crossing overtime case computes correctly; a status type added via its manager
   screen appears in the marking dropdown without an app restart.
4. **Finance ledger** — `EmployeeLedgerEntry` model/repo, "Add payment" dialog
   (dropdown-from-`select distinct entry_type` + "add new," no lookup table), switch
   employee detail to `core.employee_timeline`. *Verify*: payments and events interleave
   correctly by date.
5. **Reports** — `derived_flags` function, summary cards + late/early/overtime drill-down.
   *Verify*: hand-calculate a mixed test week and compare against the report output;
   insert a new `shift_defaults` row effective today and confirm past days' flags are
   unchanged while today-onward days use the new rule (the Friday/Monday scenario); a
   fully time-less "present" day produces no drill-down row, a partial entry's assumed
   side never triggers a flag.
6. **RBAC console** — signup allow-list manager and roles manager (superadmin),
   module-access manager (admin-or-above). *Verify*: granting/revoking through these
   screens has the same effect as the equivalent manual SQL would; a revoked role/allow-list
   entry actually blocks the corresponding action (RLS/trigger enforced, not just hidden
   in the UI).
7. **Settings & polish** — theme, sign-out, empty/error states, an actual UI polish pass
   (researched Material 3 patterns, accessibility, clean widget decomposition — see
   separate note on UI quality bar), cross-platform pass (Android/Web/Linux desktop).

## Data migration (deferred — decide once the app is actually built, not now)

Real historical data from `crs_attendance` (old Firebase app) needs importing — confirmed
this session, and the reason `shift_defaults.effective_from` must predate the oldest
imported record rather than being a "launch date" (see `attendance.shift_defaults` above).
Investigated the actual old Firestore schema this session (not a guess): `employees` (`id`,
`name`, `color` int — ARGB, matches the new schema's format directly, `salary` int,
`disabled` bool, `createdAt` UTC ISO8601 string); `attendance` (one doc per employee per
day, `status` enum `present`/`absent`/`halfDay`/`holiday`, `employeeId`, `date` UTC
ISO8601 string, `timeIn`/`timeOut` as `"HH:mm"` strings, `remarks`); `admins` (doc ID =
Firebase uid, no fields — existence-only check, nothing structural to migrate since new
Supabase Auth UIDs won't match old Firebase UIDs anyway — this one migrates by knowledge,
not data: it's just you + your dad).

Four real decisions the actual migration script needs, deliberately **not** decided now:
1. **Likely off-by-one-day bug in old dates** — `date` was stored via
   `.toUtc().toIso8601String()`; if built from local (IST) midnight, the UTC string can
   represent the *previous* calendar day. Must verify against the real Firestore export
   and convert back to IST before extracting the date — never trust the raw UTC date
   substring.
2. **No transition date for `disabled: bool`** — tells you current state, never when
   someone left. Needs either inferring a left-date from an employee's last attendance
   record, or a manual one-time correction pass with your dad.
3. **`createdAt` may understate real join date** — it's "when the doc was created," not
   necessarily "when they actually joined," for anyone who predates the old app.
4. **`halfDay` has no half-granularity data** — one flag, doesn't say which half was
   worked; mapping it into the new first-half/second-half model is a lossy guess unless
   `timeIn`/`timeOut` happen to disambiguate it.

## Verification

- **Unit tests** (`flutter test`): `dart_mappable` round-trips for each model against
  realistic Postgres string shapes (esp. `time`/`date` parsing); `iconFor`/`colorFor`
  fallback on an unrecognized `icon_name`/`null color_hex` (see `status_metadata.dart`);
  router redirect logic extracted as a pure function of session state so it's testable
  without a live `GoRouter`.
- **Widget tests**: first-half/second-half split control and bulk-action confirm flow, with
  `ProviderScope` overrides using fake repositories (no real Supabase client in tests).
- **Manual smoke tests** per phase on `flutter run -d chrome` and `-d linux`, periodically
  on an Android device/emulator.
- **RLS checks**: for each new table, in the Supabase SQL editor simulate a non-admin
  (`set local role authenticated; set local request.jwt.claims = '{"sub":"<test-uid>"}';`)
  and confirm writes are rejected; keep one real non-admin Google test account signed into
  the actual app to confirm the UI handles a `PostgrestException` gracefully rather than
  crashing. Automated pgTAP tests via the Supabase CLI are a reasonable stretch goal later,
  not needed for a two-admin app at this size yet.

## Critical files

- `supabase/migrations/0001_core_and_attendance_schema.sql` — schema + RLS + helper
  functions; everything else depends on this being right.
- `lib/core/auth/providers/session_provider.dart` — drives router redirects and
  module-access gating app-wide.
- `lib/core/router/app_router.dart` — the module-boundary mechanism itself, plus the
  nav-destination list (module access → nav visibility, UX-only, RLS is the real gate).
- `lib/core/widgets/adaptive_nav_scaffold.dart` — the hand-rolled bottom-bar/rail switch
  (see Flutter app structure above; no third-party dependency, since the package that
  would have provided this was discontinued).
- `lib/core/widgets/status_metadata.dart` — the `iconFor`/`colorFor` DB-metadata-lookup
  helpers shared by attendance status (`attendance.status_types`) and employee events
  (`core.event_types`); `entry_type` doesn't use this pattern — see req. 6 discussion
  above.
- `lib/core/employees/repositories/` — moved here from `modules/attendance/` this
  session, since `core.employees`/`employee_events`/`employee_ledger_entries` are
  app-wide at the DB level for the confirmed future challan/asset modules.
- `lib/modules/attendance/repositories/attendance_repository.dart` — bulk actions +
  `effective_range_status`/`recent_gaps`/`derived_flags` RPC calls (each taking an
  optional `p_employee_id`), the trickiest data-access logic in the module.
