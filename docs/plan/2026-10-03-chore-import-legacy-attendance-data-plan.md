---
title: Import legacy crs_attendance data into Supabase
type: chore
date: 2026-10-03
---

## Import legacy crs_attendance data into Supabase - Standard

## Overview

Build a reusable Dart tool, `tool/generate_legacy_import.dart`, that reads a Firestore
export of the old `crs_attendance` app (shape: `admins`/`employees`/`attendance` top-level
maps — see `~/Downloads/backup.json`) and generates one reviewable, transaction-wrapped
`.sql` file that imports it into the live `core`/`attendance` schema. The tool is run twice,
at minimum: once now as a test against the (currently un-bootstrapped, empty) hosted
project, and again in ~1-2 weeks at real cutover against a fresh export containing
whatever the old app has accumulated by then. Nothing executes against the hosted database
automatically — the generated SQL is reviewed by hand, then pasted into Studio's SQL editor
or run via `supabase db execute`.

This is a one-time-per-cutover data task, not a schema change — no new migration file, no
app code paths. The `admins` top-level key is explicitly out of scope (the user is handling
allow-list/role bootstrap separately).

## Problem Statement / Motivation

The old app's Firestore data has no equivalent of the new schema's richer model (append-only
status events, two-schema split, derived flags) — it's flat `employees`/`attendance`
documents with a single `disabled` boolean and no join/leave history. Real inspection of the
actual export (not assumptions) surfaced four concrete, confirmed data problems that
`plan.md`'s original design left open:

1. **Every single `attendance.date` field is off by one day.** All 1950 records end in
   exactly `T18:30:00.000Z` — local IST midnight stored as UTC. Confirmed zero exceptions;
   adding 5:30 recovers the correct date, cross-verified against the doc key's own
   `D-M-YYYY` prefix with zero mismatches.
2. **`employees.createdAt` is not a usable join date.** Confirmed wrong for all 16
   employees — every one's `createdAt` postdates their first real attendance record, in
   some cases by months. The first corrected attendance date is the reliable join date.
3. **No left-date exists for the 11 of 16 employees with `disabled:true`.** Their last
   attendance record stands in for "last working day."
4. **18 of 1950 `halfDay` records (0.9%) have no `timeIn`/`timeOut`/`remarks`** — confirmed
   none of the 1950 records have any time-of-day data at all — so which half was actually
   worked is unrecoverable. User decision: default both to `first=present, second=absent`,
   flagged inline so they're easy to find and correct later via the app.

## Proposed Solution

A single Dart script, invoked as:

```
dart run tool/generate_legacy_import.dart <path-to-backup.json> [output.sql]
```

reads the export and writes one self-contained SQL file (default path
`supabase/legacy_imports/<timestamp>.sql`, gitignored — see Technical Considerations) shaped
like:

```sql
begin;

-- Refuses to run against a non-empty table, so a second accidental run (or a stale
-- test-run's leftovers) can never silently double-insert. Deliberate wipe is the static
-- undo script below, run first and on purpose when re-importing fresh data at cutover.
do $$
begin
  if exists (select 1 from core.employees) then
    raise exception 'core.employees is not empty — run supabase/legacy_imports/undo.sql first if you intend to re-import.';
  end if;
end $$;

-- Dart generates one v4 UUID per employee and embeds it as a literal everywhere that
-- employee is referenced below — no temp table or join needed (simplification from plan
-- review: a mapping table bought nothing here that a literal doesn't already give).
-- salary 0 -> null (user decision: 0 means "never recorded", not a real ₹0 salary)
insert into core.employees (id, name, color, salary) values
  ('<generated-uuid-1>', 'Employee Name', 4294198070, null), -- was firestore id <firestore-id-1>
  ...;

-- joined = first corrected attendance date (createdAt confirmed unreliable); left = last
-- corrected attendance date, only for disabled:true employees. created_at is set
-- explicitly per row (not left to default now()) for two reasons: it's more honest for
-- backdated historical data, and it breaks the same-day-joined-and-left tie in
-- core.employee_current_status deterministically toward "left wins" — correct, since
-- that view answers "status as of today," and a same-day joined+left employee is
-- genuinely inactive today.
insert into core.employee_events (employee_id, event_type, event_date, note, created_at) values
  ('<generated-uuid-1>', 'joined', '2026-04-09', 'Imported from legacy app (first attendance record)', '2026-04-09T00:00:00Z'),
  ('<generated-uuid-1>', 'left',   '2026-09-08', 'Imported from legacy app (last attendance record; disabled=true)', '2026-09-08T00:00:01Z'),
  ...;

-- 1950 rows, 1:1 except the 18 flagged halfDay rows (first=present, second=absent, no
-- data exists to say otherwise — see Problem Statement #4).
insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status) values
  ('<generated-uuid-1>', '2026-04-09', 'present', 'present'),
  ('<generated-uuid-2>', '2026-06-30', 'present', 'absent'), -- halfDay, no time data to disambiguate, verify manually
  ...;

-- Self-describing verification, computed from the SAME input file so it always matches
-- whatever export was fed in — not hardcoded to today's 16/1950. Aborts the whole
-- transaction (rolling back everything above) if any count is off.
do $$
declare emp_count int; evt_count int; att_count int;
begin
  select count(*) into emp_count from core.employees;
  select count(*) into evt_count from core.employee_events where event_type in ('joined','left');
  select count(*) into att_count from attendance.attendance_days;
  if emp_count <> 16 or evt_count <> 27 or att_count <> 1950 then
    raise exception 'count mismatch: employees=%, events=%, attendance_days=% (expected 16/27/1950)',
      emp_count, evt_count, att_count;
  end if;
end $$;

commit;
```

A **static** companion file, `supabase/legacy_imports/undo.sql` (committed once, not
regenerated per run — simplification from plan review: these three tables hold only this
import's data today, so a scoped per-run delete list is unneeded ceremony):

```sql
truncate core.employees, core.employee_events, attendance.attendance_days cascade;
```

Run deliberately, by hand, only when intentionally re-importing — never automatically. If
real app usage (not just imported history) ever starts writing to these tables before a
future re-import, this blunt truncate stops being safe and needs revisiting then — not a
problem to solve now.

Script responsibilities (all pure data transformation, no network/DB access):

1. Parse `backup.json`; for each `attendance` record, correct the date (`+5:30`, assert it
   matches the doc key's `D-M-YYYY` prefix — abort generation if any record disagrees).
2. Per employee: compute first/last corrected attendance date; derive `joined` (always) and
   `left` (only if `disabled: true`) events from them; generate one v4 UUID per employee
   (hand-rolled from `dart:math`'s `Random.secure()` — no new pubspec dependency for one
   script).
3. Map `salary: 0 -> NULL`; trim and SQL-escape every employee name (`'` → `''`) defensively
   — today's export has no quotes/backslashes, but the cutover export might.
4. Map status 1:1 (`present`/`absent`/`holiday` unchanged; `halfDay` → `(present, absent)`
   with an inline SQL comment flag) into `attendance_days`.
5. Emit the transaction above; print a short list of the flagged `halfDay` rows (employee
   name + date) to stdout so they're easy to spot-check afterward.
6. Refuse to generate (exit non-zero, no file written) if any employee has zero attendance
   records — there's nothing to derive a join date from, and silently skipping them would
   lose an employee without saying so.

**Tests** (`test/tool/generate_legacy_import_test.dart`) — this script has zero DB/network
access, so its date-correction, join/left-date derivation, salary-null mapping, and
name-escaping logic are plain functions, cheap and valuable to pin down directly rather than
trust by inspection alone, given these are exactly the four bugs real data already caught
once:

- IST date correction matches a record's doc-key date for known fixtures.
- Join date = first attendance date, not `createdAt`, for a fixture employee.
- `disabled:false` employee gets no `left` event; `disabled:true` gets one dated at their
  last attendance date.
- `salary: 0` maps to `null`; a real salary passes through unchanged.
- A name with a trailing space and an embedded `'` comes out trimmed and escaped.

This is bounded, structural coverage for a new unit — not a test per historical bug fix.

## Technical Considerations

- **Generated SQL files contain real names/salaries — never commit them.** Add
  `supabase/legacy_imports/` to `.gitignore` (the directory itself can stay, or be created
  on demand by the script).
- **Architecture impact**: none — no schema change, no app code touched. `tool/` is a
  dev-only script directory, excluded from `flutter analyze`'s app-facing lint set the same
  way `build/`/platform folders already are (confirm it doesn't trip `dart analyze .`; add it
  to `analysis_options.yaml`'s `exclude` list if it does).
- **Idempotency / re-run safety**: the empty-table guard converts "ran twice by accident"
  into a loud, pre-commit SQL exception instead of silent duplicate data — this is the
  concrete fix for gap #1 from the flow-analysis pass (confirmed: duplicate employees would
  get fresh ids, so the `unique(employee_id, date)` constraint wouldn't catch a second run).
- **`created_by` stays `NULL`** on every imported `employee_events`/`attendance_days` row —
  both columns are nullable; attributing 1950 historical rows to a real admin's `user_id`
  would fabricate authorship nobody actually had (confirmed via the flow-analysis pass).
- **Tie-break correctness**: `core.employee_current_status` (already live) resolves ties via
  `order by event_date desc, created_at desc`. Because the whole import runs in one
  transaction, a naive `default now()` would give every row an identical `created_at`,
  making a same-day joined-and-left employee's current status undefined. Not hit by today's
  data (verified: no disabled employee has joined==left), but the cutover export could
  include a genuine one-day hire — so `created_at` is set explicitly per row (join date, left
  date + 1 second) rather than left to the default, closing the gap structurally instead of
  relying on today's data being lucky.
- **No security/RLS impact**: the generated SQL runs with the credentials pasted into
  Studio's SQL editor (effectively superuser), bypassing RLS entirely by design — this is
  the same trust model the existing schema migrations already use.
- **Document the manual step, not the data**: `supabase/README.md` already tracks one-time
  manual hosted-project actions (allow-list seed, role grants) as a runbook. Add a short
  section there — how to run the tool, where the static undo lives, a checklist line for
  "ran the legacy data import" — so this action has the same paper trail as the rest of
  bootstrap, without committing any PII-bearing SQL (per plan review: a redacted migration
  stub with no row data would be ceremony for its own sake; the README entry is the
  project's existing pattern for exactly this kind of manual step).

## Success Criteria

```success-criteria
GOAL: A reusable, re-runnable Dart tool exists that turns a Firestore crs_attendance export into a reviewable, self-verifying SQL import, and today's test run against it succeeds end to end.

SUCCESS CRITERIA:
- tool/generate_legacy_import.dart parses ~/Downloads/backup.json without error and writes one self-contained .sql file | verify: dart run tool/generate_legacy_import.dart ~/Downloads/backup.json /tmp/test_import.sql
- Generated script is valid Dart, analysis-clean | verify: dart analyze tool/generate_legacy_import.dart && dart format --output=none --set-exit-if-changed tool/generate_legacy_import.dart
- Pure transform logic (date correction, join/left derivation, salary-null mapping, name escaping) is unit-tested | verify: flutter test test/tool/generate_legacy_import_test.dart
- Generated SQL refuses to run twice without an explicit undo first | verify: manual 1. Run the generated .sql against the hosted project once via Studio's SQL editor. 2. Re-run the same file. 3. Confirm the second run raises the "core.employees is not empty" exception and makes no changes (transaction aborts). 4. Confirm supabase/legacy_imports/undo.sql, run deliberately, clears all three tables and allows a clean re-run.
- supabase/README.md documents how to run the import and the static undo | verify: manual confirm the README has a section naming tool/generate_legacy_import.dart, supabase/legacy_imports/undo.sql, and a checklist line for this run
- Row counts after import match the source file exactly: 16 employees, 27 employee_events (16 joined + 11 left), 1950 attendance_days | verify: manual run the verification block already embedded in the generated SQL (it raises and rolls back on mismatch, so a clean commit is itself the proof) — additionally spot-check `select count(*) from core.employees` etc. in Studio
- core.employee_current_status's active/inactive split matches the 16 employees' disabled flags 1:1 | verify: manual run `select e.name, s.status from core.employees e join core.employee_current_status s on s.employee_id = e.id order by e.name;` in Studio and compare against the 11 disabled / 5 active split from backup.json
- The 18 flagged halfDay rows are identifiable for manual review | verify: manual confirm the script's stdout list has exactly 18 entries, cross-checked against `grep -c "halfDay, no time data" <generated>.sql`
- Employee names needing trim/escaping are handled | verify: dart run tool/generate_legacy_import.dart ~/Downloads/backup.json /tmp/test_import.sql && grep -c "Pranjal Delivery ref apna website advertisement'" /tmp/test_import.sql (expect 0 — trimmed, no trailing space inside the quoted literal)

NON-GOALS:
- Importing or validating the `admins` top-level key (allow-list/role bootstrap is being handled separately by the user).
- Recovering multi-cycle rehire history — the old `disabled` boolean only supports one join→left interval per employee; this is a documented, accepted lossy limitation, not a bug to fix here.
- Any time-in/time-out or late/early/overtime backfill — the source data has zero time-of-day fields across all 1950 records, so derived_flags simply produces no rows for imported history, which is correct, not a gap.
- Automatic execution against the hosted database from the script — every run against the real project is a manual, reviewed, human-triggered action.

VERIFICATION COMMAND: dart run tool/generate_legacy_import.dart ~/Downloads/backup.json /tmp/test_import.sql && dart analyze tool/generate_legacy_import.dart && dart format --output=none --set-exit-if-changed tool/generate_legacy_import.dart && flutter test test/tool/generate_legacy_import_test.dart
```

## Success Metrics

- Today's test run completes with all automated `verify:` commands passing and the manual
  Studio checks confirmed by the user.
- At real cutover (next 1-2 weeks), the same tool runs again against a fresh export with
  zero code changes required — only a fresh `backup.json` path and (if reusing the same
  project) an explicit undo-then-reimport cycle.

## Dependencies & Risks

- **Hosted project only** — there's no local Supabase stack in this repo; every run targets
  the real hosted project (bootstrap not yet executed, so today's test run is the first real
  data to land in `core`/`attendance`). Low risk today (empty tables, nothing to lose), but
  the cutover run is a real production action — the static `undo.sql` and the empty-table
  guard are the safety net, not optional extras.
- **Source data could change shape** between now and cutover (old app is presumably still
  live and being used) — e.g. a new status value, a record with real `timeIn`/`timeOut` for
  the first time. The script should fail loudly (not silently skip or guess) on an
  unrecognized `status` value or an employee with zero attendance records, per the explicit
  abort behavior above.
- **This plan does not cover** re-running the allow-list/role bootstrap (`supabase/README.md`)
  or the Google OAuth provider setup — both are prerequisites for anyone actually signing in
  to see this imported data, and are explicitly the user's own separate task.

## References & Research

- Old schema investigation: `plan.md`'s "Data migration (deferred)" section — the four open
  decisions it listed are the ones this plan resolves with real data.
- Target schema: `supabase/migrations/20260919223302_core_schema.sql` (`core.employees`,
  `core.event_types`, `core.employee_events`, `core.employee_current_status`),
  `supabase/migrations/20260919223550_fix_employee_color_range_and_event_types_rls.sql`
  (confirms `color` is `bigint`, not `integer`), `supabase/migrations/20260920003110_attendance_schema.sql`
  (`attendance.status_types`, `attendance.attendance_days`, `shift_defaults` sentinel row).
- Bootstrap runbook (separate, user-owned task, but gets a new section for this tool):
  `supabase/README.md`.
- Plan review (2026-10-03): simplicity, VGV, and scope-splitting passes all ran against
  this plan before build. Scope: single file, no split needed. Simplicity: dropped the
  temp-table/join in favor of Dart-generated literal UUIDs, and shrank the undo file to a
  static truncate. VGV: added the README runbook entry and unit tests for the pure
  transform logic (both folded in above).
- Data facts cited throughout were confirmed by direct inspection of
  `~/Downloads/backup.json` in this session (16 employees, 1950 attendance records, 2
  admins, zero timeIn/timeOut/remarks anywhere, zero duplicate (employeeId, date) pairs,
  zero unescaped quotes in names, zero same-day joined==left collisions today).
