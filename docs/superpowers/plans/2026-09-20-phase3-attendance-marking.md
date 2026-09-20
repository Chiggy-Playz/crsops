# CRS Ops — Phase 3: Attendance Marking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `attendance` Postgres schema (shift defaults, status types, attendance days, and the three functions that compute effective status/gaps/derived flags) and the Flutter Calendar + attendance-for-day + shift-defaults/status-types admin screens — the actual attendance-tracking core of the app.

**Architecture:** All status/gap/late-early-overtime logic lives in three `stable` SQL functions (`effective_range_status`, `recent_gaps`, `derived_flags`), called via `.rpc()`, so the Calendar, attendance-for-day, and any future reports screen can never compute these facts differently from each other. Flutter repositories are thin wrappers over `.schema('attendance').from(...)`/`.rpc(...)` calls, matching Phase 1/2's established pattern exactly.

**Tech Stack:** Same as Phases 1–2 — Flutter (Riverpod + `riverpod_generator`, `go_router`, `dart_mappable`), Supabase (`attendance` schema, new this phase), plus `table_calendar` (new dependency, month-view calendar widget).

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (sections: Schema → `attendance` schema + the three functions + Performance notes, Flutter app structure, Screens → Calendar/Attendance-for-day/Settings admin console's shift-defaults and status-types managers). Depends on Phase 1 (`docs/superpowers/plans/2026-09-20-phase1-foundation.md`) and Phase 2 (`docs/superpowers/plans/2026-09-20-phase2-employee-core.md`).

## Global Constraints

- `attendance` is a brand-new schema this phase — Phase 1 only created `core`. Every table/function here needs the **identical** RLS + `GRANT` treatment Phase 1 needed for `core` (a real bug found there: RLS alone is not enough, `authenticated` needs explicit `usage on schema`, `select/insert/update/delete` on tables, `execute` on functions, plus `alter default privileges` so later additions inherit grants automatically).
- **Every `.from('<table>')`/`.rpc('<function>')` call must be schema-qualified**: `_client.schema('attendance').from('attendance_days')`, `_client.schema('attendance').rpc('effective_range_status', {...})` — including when split across multiple lines. This exact bug (bare `.from()` silently targeting `public`, which 404s since these tables live in `attendance`) recurred twice already in Phases 1–2; every repository method in this plan is written with the qualifier inline from the start, and Task 12's self-review re-checks every call site explicitly.
- Riverpod resolved to **3.x**: `AsyncValue.value` (nullable), not `.valueOrNull`; generated function-style providers expose `.future`, not `.stream` — bridge any Listenable needs via `ref.listen`, not a stream subscription.
- `shift_defaults.effective_from` is seeded at `2000-01-01`, **not** "today"/"launch date" — every lookup is `largest effective_from <= the date being evaluated`, so a launch-dated seed row would leave every future-imported historical date with zero matching rows.
- `attendance.attendance_days` rows exist **only when something was explicitly marked** — week-off and unmarked days have no row (`effective_range_status` computes those from `shift_defaults` + `core.employee_status_as_of`, never stores them).
- Every async page follows the same **four-states rule** as Phase 2: loading, error (`AppException.message`), empty (a specific message, not a blank list/blank calendar), offline (`isOnlineProvider`/`OfflineScreen`).
- English only, Material 3 widgets throughout.
- Calendar becomes this app's actual default route (`/`), replacing Phase 1's `_PlaceholderHomeShell` — gated on `session.hasModuleAccess('attendance')`, mirroring how Phase 2 gated `/employees/event-types` on `session.isSuperadmin`.

---

## File Structure

**Supabase:**
- `supabase/migrations/<timestamp>_attendance_schema.sql` — schema, tables, RLS, grants (Tasks 1–3).
- `supabase/migrations/<timestamp>_attendance_functions.sql` — the three functions (Tasks 4–6).

**Flutter — `lib/modules/attendance/` (all new this phase):**
- `models/shift_defaults.dart` — `ShiftDefaults` (`dart_mappable`).
- `models/status_type.dart` — `StatusType` (`dart_mappable`).
- `models/attendance_day.dart` — `AttendanceDay` (`dart_mappable`).
- `models/effective_status_row.dart` — `EffectiveStatusRow` (`dart_mappable`) — one row of `effective_range_status`'s output.
- `models/gap_row.dart` — `GapRow` (`dart_mappable`) — one row of `recent_gaps`'s output.
- `models/derived_flags_row.dart` — `DerivedFlagsRow` (`dart_mappable`) — one row of `derived_flags`'s output.
- `repositories/shift_defaults_repository.dart` — `abstract class ShiftDefaultsRepository` + `SupabaseShiftDefaultsRepository`.
- `repositories/status_type_repository.dart` — `abstract class StatusTypeRepository` + `SupabaseStatusTypeRepository`.
- `repositories/attendance_repository.dart` — `abstract class AttendanceRepository` + `SupabaseAttendanceRepository`.
- `providers/attendance_providers.dart` — all `@riverpod` providers for this phase.
- `pages/calendar_page.dart`
- `pages/attendance_day_page.dart`
- `pages/widgets/day_cell.dart`
- `pages/widgets/employee_marking_tile.dart`
- `pages/shift_defaults_manager_page.dart`
- `pages/status_types_manager_page.dart`
- `routes.dart` — the route list this phase contributes to the router.

**Modify:**
- `pubspec.yaml` — add `table_calendar`.
- `lib/core/router/app_router.dart` (Phase 1/2) — merge in `attendanceRoutes`, replace `_PlaceholderHomeShell` at `/` with the Calendar-gated route.

**Tests (fakes + unit/widget tests):**
- `test/modules/attendance/models/*_test.dart` (one per model).
- `test/modules/attendance/fakes/fake_shift_defaults_repository.dart`, `fake_status_type_repository.dart`, `fake_attendance_repository.dart`.
- `test/modules/attendance/pages/calendar_page_test.dart`, `attendance_day_page_test.dart`, `shift_defaults_manager_page_test.dart`, `status_types_manager_page_test.dart`.

---

### Task 1: `attendance` schema — `shift_defaults` + `status_types`

**Files:**
- Create: `supabase/migrations/<timestamp>_attendance_schema.sql` (created here, appended to by Task 2)

**Interfaces:**
- Produces: `attendance.shift_defaults(id, effective_from, default_start, default_end, week_off_days, created_by, created_at)` seeded with one row; `attendance.status_types(id, label, icon_name, color_hex, description)` seeded with `present`/`absent`/`leave`/`holiday`/`week_off`.

- [ ] **Step 1: Create the migration file**

```bash
supabase migration new attendance_schema
```

- [ ] **Step 2: Write the schema, both tables, and their seed data**

```sql
-- supabase/migrations/<timestamp>_attendance_schema.sql

create schema if not exists attendance;

create table attendance.shift_defaults (
  id uuid primary key default gen_random_uuid(),
  effective_from date not null,
  default_start time not null,
  default_end time not null,
  week_off_days smallint[] not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (effective_from)
);

-- Seeded at 2000-01-01, NOT "today" — every shift_defaults lookup picks the row
-- with the largest effective_from <= the date being evaluated. A launch-dated
-- seed row would leave every future-imported historical date with zero matching
-- rows, breaking effective_range_status/derived_flags on exactly the data being
-- migrated in later.
insert into attendance.shift_defaults (effective_from, default_start, default_end, week_off_days)
values ('2000-01-01', '10:30', '18:30', '{7}');

create table attendance.status_types (
  id text primary key,
  label text not null,
  icon_name text,
  color_hex text,
  description text
);

insert into attendance.status_types (id, label, icon_name, color_hex) values
  ('present', 'Present', 'check', '#4CAF50'),
  ('absent', 'Absent', 'close', '#F44336'),
  ('leave', 'Leave', 'event_busy', '#FF9800'),
  ('holiday', 'Holiday', 'beach_access', '#2196F3'),
  ('week_off', 'Week Off', 'weekend', '#9E9E9E');

alter table attendance.shift_defaults enable row level security;
create policy shift_defaults_select on attendance.shift_defaults
  for select using (auth.role() = 'authenticated');
create policy shift_defaults_insert on attendance.shift_defaults
  for insert with check (core.is_admin_or_above());
-- No update/delete policy at all: this table is deliberately append-only, per
-- the design (a shift-hours change inserts a new row, never edits an old one).

alter table attendance.status_types enable row level security;
create policy status_types_select on attendance.status_types
  for select using (auth.role() = 'authenticated');
create policy status_types_insert on attendance.status_types
  for insert with check (core.is_admin_or_above());
create policy status_types_update on attendance.status_types
  for update using (core.is_admin_or_above()) with check (core.is_admin_or_above());
```

- [ ] **Step 3: Push the migration to the real linked project and verify**

```bash
supabase db push
supabase db query --linked "select id, default_start, default_end, week_off_days from attendance.shift_defaults;"
supabase db query --linked "select id, label from attendance.status_types order by id;"
```

Expected: one `shift_defaults` row (`10:30`, `18:30`, `{7}`); five `status_types` rows.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): attendance schema — shift_defaults, status_types"
```

---

### Task 2: `attendance` schema — `attendance_days` + grants

**Files:**
- Modify: `supabase/migrations/<timestamp>_attendance_schema.sql`

**Interfaces:**
- Produces: `attendance.attendance_days(id, employee_id, date, first_half_status, second_half_status, time_in, time_out, note, created_by, updated_at)`; full `GRANT`s for `authenticated` on the whole `attendance` schema.

- [ ] **Step 1: Append `attendance_days` + its RLS**

```sql
create table attendance.attendance_days (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references core.employees(id) on delete cascade,
  date date not null,
  first_half_status text references attendance.status_types(id),
  second_half_status text references attendance.status_types(id),
  time_in time,
  time_out time,
  note text,
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  unique (employee_id, date)
);

alter table attendance.attendance_days enable row level security;
create policy attendance_days_select on attendance.attendance_days
  for select using (
    core.is_admin_or_above()
    or exists (select 1 from core.employees e where e.id = employee_id and e.user_id = auth.uid())
  );
create policy attendance_days_write on attendance.attendance_days
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());
```

- [ ] **Step 2: Append the schema-wide grants** (the exact gap that broke every `core` query in Phase 1 until fixed — not skipping it this time)

```sql
grant usage on schema attendance to authenticated;
grant select, insert, update, delete on all tables in schema attendance to authenticated;
grant execute on all functions in schema attendance to authenticated;
alter default privileges in schema attendance grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema attendance grant execute on functions to authenticated;
```

- [ ] **Step 3: Push and verify a non-admin is rejected, admin-or-above works**

```bash
supabase db push
```

```bash
supabase db query --linked "
insert into core.allowed_signup_emails (email) values ('phase3-admin@example.com'), ('phase3-emp@example.com');
insert into auth.users (id, email) values
  ('33333333-0000-0000-0000-000000000001', 'phase3-admin@example.com'),
  ('33333333-0000-0000-0000-000000000002', 'phase3-emp@example.com');
insert into core.user_roles (user_id, role_id) values
  ('33333333-0000-0000-0000-000000000001', 'admin'),
  ('33333333-0000-0000-0000-000000000002', 'employee');
insert into core.employees (id, name, color) values
  ('33333333-0000-0000-0000-0000000000aa', 'Phase3 Test Employee', 4283215696);
"
```

```bash
supabase db query --linked "
set local role authenticated;
set local request.jwt.claims = '{\"sub\":\"33333333-0000-0000-0000-000000000001\",\"role\":\"authenticated\"}';
insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status)
values ('33333333-0000-0000-0000-0000000000aa', '2024-06-01', 'present', 'present');
select employee_id, date, first_half_status from attendance.attendance_days;
"
```

Expected: insert succeeds (admin), one row returned.

```bash
supabase db query --linked "
set local role authenticated;
set local request.jwt.claims = '{\"sub\":\"33333333-0000-0000-0000-000000000002\",\"role\":\"authenticated\"}';
insert into attendance.attendance_days (employee_id, date, first_half_status)
values ('33333333-0000-0000-0000-0000000000aa', '2024-06-02', 'present');
"
```

Expected: **FAILS** with a row-level security policy violation (plain `employee` role, no admin).

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): attendance_days table + schema-wide grants for authenticated"
```

---

### Task 3: Clean up Task 2's verification test data

**Files:** none.

- [ ] **Step 1: Delete everything inserted in Task 2's verification**

```bash
supabase db query --linked "
delete from attendance.attendance_days where employee_id = '33333333-0000-0000-0000-0000000000aa';
delete from core.employees where id = '33333333-0000-0000-0000-0000000000aa';
delete from core.user_roles where user_id in ('33333333-0000-0000-0000-000000000001','33333333-0000-0000-0000-000000000002');
delete from auth.users where email in ('phase3-admin@example.com','phase3-emp@example.com');
delete from core.allowed_signup_emails where email in ('phase3-admin@example.com','phase3-emp@example.com');
"
```

- [ ] **Step 2: No commit** — cleanup only.

---

### Task 4: `effective_range_status` function

**Files:**
- Create: `supabase/migrations/<timestamp>_attendance_functions.sql` (created here, appended to by Tasks 5–6)

**Interfaces:**
- Produces: `attendance.effective_range_status(p_start date, p_end date, p_employee_id uuid default null) returns table (employee_id uuid, date date, first_half_status text, second_half_status text, is_explicit boolean, is_week_off boolean, time_in time, time_out time, note text)`, `stable`.

- [ ] **Step 1: Create the migration file**

```bash
supabase migration new attendance_functions
```

- [ ] **Step 2: Write the function**

```sql
-- supabase/migrations/<timestamp>_attendance_functions.sql

create or replace function attendance.effective_range_status(
  p_start date,
  p_end date,
  p_employee_id uuid default null
)
returns table (
  employee_id uuid,
  date date,
  first_half_status text,
  second_half_status text,
  is_explicit boolean,
  is_week_off boolean,
  time_in time,
  time_out time,
  note text
)
language sql
stable
as $$
  select
    e.id,
    gs.d::date,
    ad.first_half_status,
    ad.second_half_status,
    (ad.id is not null),
    (extract(isodow from gs.d)::smallint = any(sd.week_off_days)),
    ad.time_in,
    ad.time_out,
    ad.note
  from core.employees e
  cross join generate_series(p_start, p_end, '1 day'::interval) as gs(d)
  left join attendance.attendance_days ad
    on ad.employee_id = e.id and ad.date = gs.d::date
  cross join lateral (
    select w.week_off_days
    from attendance.shift_defaults w
    where w.effective_from <= gs.d::date
    order by w.effective_from desc
    limit 1
  ) sd
  where (p_employee_id is null or e.id = p_employee_id)
    and core.employee_status_as_of(e.id, gs.d::date) = 'active';
$$;
```

- [ ] **Step 3: Push and verify against real data** — one employee, one explicit present day, one week-off (Sunday), one plain unmarked working day

```bash
supabase db push
supabase db query --linked "
insert into core.employees (id, name, color) values
  ('44444444-0000-0000-0000-0000000000bb', 'Phase3 Range Test', 4278238420);
insert into core.employee_events (employee_id, event_type, event_date) values
  ('44444444-0000-0000-0000-0000000000bb', 'joined', '2024-06-01');
insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status) values
  ('44444444-0000-0000-0000-0000000000bb', '2024-06-03', 'present', 'present');
select date, first_half_status, is_explicit, is_week_off
from attendance.effective_range_status('2024-06-02', '2024-06-04', '44444444-0000-0000-0000-0000000000bb')
order by date;
"
```

Expected three rows: `2024-06-02` (Sunday) → `is_week_off=true, is_explicit=false, first_half_status=null`; `2024-06-03` (Monday, explicitly marked) → `is_explicit=true, first_half_status='present'`; `2024-06-04` (Tuesday, untouched) → `is_explicit=false, is_week_off=false, first_half_status=null`.

- [ ] **Step 4: Clean up this task's test data**

```bash
supabase db query --linked "
delete from attendance.attendance_days where employee_id = '44444444-0000-0000-0000-0000000000bb';
delete from core.employee_events where employee_id = '44444444-0000-0000-0000-0000000000bb';
delete from core.employees where id = '44444444-0000-0000-0000-0000000000bb';
"
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): effective_range_status — single source of truth for day status"
```

---

### Task 5: `recent_gaps` function

**Files:**
- Modify: `supabase/migrations/<timestamp>_attendance_functions.sql`

**Interfaces:**
- Produces: `attendance.recent_gaps(p_window_days integer default 7) returns table (employee_id uuid, date date)`, `stable`.

- [ ] **Step 1: Append the function**

```sql
create or replace function attendance.recent_gaps(p_window_days integer default 7)
returns table (employee_id uuid, date date)
language sql
stable
as $$
  select r.employee_id, r.date
  from attendance.effective_range_status(
    ((now() at time zone 'Asia/Kolkata')::date - p_window_days),
    ((now() at time zone 'Asia/Kolkata')::date - 1)
  ) r
  where not r.is_explicit and not r.is_week_off;
$$;
```

- [ ] **Step 2: Push and verify** — an employee with one genuinely unmarked recent working day shows up as a gap

```bash
supabase db push
supabase db query --linked "
insert into core.employees (id, name, color) values
  ('55555555-0000-0000-0000-0000000000cc', 'Phase3 Gap Test', 4278238420);
insert into core.employee_events (employee_id, event_type, event_date) values
  ('55555555-0000-0000-0000-0000000000cc', 'joined', '2000-01-01');
select employee_id, date from attendance.recent_gaps(7)
where employee_id = '55555555-0000-0000-0000-0000000000cc';
"
```

Expected: at least one row (every non-Sunday day in the last 7 days for this employee has no attendance_days row, so all qualify as gaps) — confirms the function runs end to end against real data; exact row count depends on today's date, so assert "at least one row, no error" rather than a fixed count.

- [ ] **Step 3: Clean up**

```bash
supabase db query --linked "
delete from core.employee_events where employee_id = '55555555-0000-0000-0000-0000000000cc';
delete from core.employees where id = '55555555-0000-0000-0000-0000000000cc';
"
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): recent_gaps — ambient last-7-days unmarked-day check"
```

---

### Task 6: `derived_flags` function

**Files:**
- Modify: `supabase/migrations/<timestamp>_attendance_functions.sql`

**Interfaces:**
- Produces: `attendance.derived_flags(p_start date, p_end date, p_employee_id uuid default null) returns table (employee_id uuid, date date, time_in time, time_out time, worked_minutes integer, is_late boolean, is_early boolean, overtime_minutes integer)`, `stable`. Handles overnight shifts (`time_out < time_in`) and partial entries (only one of `time_in`/`time_out` set, assumed on-time for the missing side).

- [ ] **Step 1: Append the function**

```sql
create or replace function attendance.derived_flags(
  p_start date,
  p_end date,
  p_employee_id uuid default null
)
returns table (
  employee_id uuid,
  date date,
  time_in time,
  time_out time,
  worked_minutes integer,
  is_late boolean,
  is_early boolean,
  overtime_minutes integer
)
language sql
stable
as $$
  with base as (
    select
      ad.employee_id,
      ad.date,
      ad.time_in,
      ad.time_out,
      coalesce(ad.time_in, sd.default_start) as effective_time_in,
      coalesce(ad.time_out, sd.default_end) as effective_time_out,
      sd.default_start,
      sd.default_end
    from attendance.attendance_days ad
    cross join lateral (
      select w.default_start, w.default_end
      from attendance.shift_defaults w
      where w.effective_from <= ad.date
      order by w.effective_from desc
      limit 1
    ) sd
    where (ad.time_in is not null or ad.time_out is not null)
      and (p_employee_id is null or ad.employee_id = p_employee_id)
      and ad.date between p_start and p_end
  ),
  computed as (
    select
      *,
      (effective_time_out < effective_time_in) as is_overnight,
      (case when effective_time_out < effective_time_in
        then effective_time_out + interval '24 hours'
        else effective_time_out::interval
      end - effective_time_in::interval) as worked_interval
    from base
  )
  select
    employee_id,
    date,
    time_in,
    time_out,
    (extract(epoch from worked_interval) / 60)::integer as worked_minutes,
    -- is_late: only meaningful when time_in was actually entered — a missing
    -- time_in is assumed on-time (coalesced to default_start), so it can never
    -- itself trigger this flag.
    (time_in is not null and effective_time_in > default_start) as is_late,
    -- is_early: only meaningful when time_out was actually entered, and never
    -- true for an overnight shift (it ends well past default_end the next day).
    (time_out is not null and not is_overnight and effective_time_out < default_end) as is_early,
    greatest(
      0,
      (extract(epoch from worked_interval) / 60)::integer
        - (extract(epoch from (default_end - default_start)) / 60)::integer
    ) as overtime_minutes
  from computed;
$$;
```

- [ ] **Step 2: Push and verify three cases** — a normal on-time day, a late arrival, and the overnight-shift case from the spec (`time_in=10:30`, `time_out=01:00` next day)

```bash
supabase db push
supabase db query --linked "
insert into core.employees (id, name, color) values
  ('66666666-0000-0000-0000-0000000000dd', 'Phase3 Flags Test', 4278238420);
insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status, time_in, time_out) values
  ('66666666-0000-0000-0000-0000000000dd', '2024-06-10', 'present', 'present', '10:30', '18:30'),
  ('66666666-0000-0000-0000-0000000000dd', '2024-06-11', 'present', 'present', '11:00', '18:30'),
  ('66666666-0000-0000-0000-0000000000dd', '2024-06-12', 'present', 'present', '10:30', '01:00');
select date, worked_minutes, is_late, is_early, overtime_minutes
from attendance.derived_flags('2024-06-10', '2024-06-12', '66666666-0000-0000-0000-0000000000dd')
order by date;
"
```

Expected: `06-10` → `worked_minutes=480, is_late=false, is_early=false, overtime_minutes=0`; `06-11` → `is_late=true`; `06-12` (overnight) → `worked_minutes` reflecting a full ~14.5-hour shift (870 minutes), `is_early=false` (must not be misreported as leaving early), `overtime_minutes > 0`. If `is_early` comes back `true` for `06-12`, the overnight detection is wrong — re-check the `is_overnight` computation.

- [ ] **Step 3: Clean up**

```bash
supabase db query --linked "delete from attendance.attendance_days where employee_id = '66666666-0000-0000-0000-0000000000dd';"
supabase db query --linked "delete from core.employees where id = '66666666-0000-0000-0000-0000000000dd';"
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): derived_flags — late/early/overtime with overnight-shift correctness fix"
```

---

### Task 7: `ShiftDefaults`, `StatusType`, `AttendanceDay` models

**Files:**
- Create: `lib/modules/attendance/models/shift_defaults.dart`
- Create: `lib/modules/attendance/models/status_type.dart`
- Create: `lib/modules/attendance/models/attendance_day.dart`
- Test: `test/modules/attendance/models/shift_defaults_test.dart`, `status_type_test.dart`, `attendance_day_test.dart`

**Interfaces:**
- Produces: `class ShiftDefaults` (`String id, DateTime effectiveFrom, String defaultStart, String defaultEnd, List<int> weekOffDays`); `class StatusType` (`String id, String label, String? iconName, String? colorHex, String? description`); `class AttendanceDay` (`String id, String employeeId, DateTime date, String? firstHalfStatus, String? secondHalfStatus, String? timeIn, String? timeOut, String? note`). Times are kept as raw `HH:mm:ss` strings from Postgres `time` columns — parsed to `TimeOfDay` only at the UI layer (Task 15), avoiding timezone-adjacent `DateTime` semantics for a value that has none.

- [ ] **Step 1: Write the three failing tests**

```dart
// test/modules/attendance/models/shift_defaults_test.dart
import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShiftDefaults round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '11111111-1111-1111-1111-111111111111',
      'effective_from': '2000-01-01',
      'default_start': '10:30:00',
      'default_end': '18:30:00',
      'week_off_days': [7],
    };

    final shift = ShiftDefaultsMapper.fromMap(json);

    expect(shift.effectiveFrom, DateTime.parse('2000-01-01'));
    expect(shift.defaultStart, '10:30:00');
    expect(shift.weekOffDays, [7]);
  });
}
```

```dart
// test/modules/attendance/models/status_type_test.dart
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StatusType round-trips through JSON', () {
    final json = {
      'id': 'present',
      'label': 'Present',
      'icon_name': 'check',
      'color_hex': '#4CAF50',
      'description': null,
    };

    final status = StatusTypeMapper.fromMap(json);

    expect(status.id, 'present');
    expect(status.label, 'Present');
    expect(status.iconName, 'check');
  });
}
```

```dart
// test/modules/attendance/models/attendance_day_test.dart
import 'package:crs_ops/modules/attendance/models/attendance_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AttendanceDay round-trips through JSON with nullable time fields', () {
    final json = {
      'id': '22222222-2222-2222-2222-222222222222',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'date': '2024-06-01',
      'first_half_status': 'present',
      'second_half_status': 'present',
      'time_in': null,
      'time_out': null,
      'note': null,
    };

    final day = AttendanceDayMapper.fromMap(json);

    expect(day.firstHalfStatus, 'present');
    expect(day.timeIn, isNull);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

```bash
flutter test test/modules/attendance/models/
```

Expected: FAIL — files don't exist.

- [ ] **Step 3: Write the three models**

```dart
// lib/modules/attendance/models/shift_defaults.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'shift_defaults.mapper.dart';

@MappableClass()
class ShiftDefaults with ShiftDefaultsMappable {
  const ShiftDefaults({
    required this.id,
    required this.effectiveFrom,
    required this.defaultStart,
    required this.defaultEnd,
    required this.weekOffDays,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'effective_from')
  final DateTime effectiveFrom;
  @MappableField(key: 'default_start')
  final String defaultStart;
  @MappableField(key: 'default_end')
  final String defaultEnd;
  @MappableField(key: 'week_off_days')
  final List<int> weekOffDays;
}
```

```dart
// lib/modules/attendance/models/status_type.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'status_type.mapper.dart';

@MappableClass()
class StatusType with StatusTypeMappable {
  const StatusType({
    required this.id,
    required this.label,
    this.iconName,
    this.colorHex,
    this.description,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'icon_name')
  final String? iconName;
  @MappableField(key: 'color_hex')
  final String? colorHex;
  @MappableField(key: 'description')
  final String? description;
}
```

```dart
// lib/modules/attendance/models/attendance_day.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'attendance_day.mapper.dart';

@MappableClass()
class AttendanceDay with AttendanceDayMappable {
  const AttendanceDay({
    this.id,
    required this.employeeId,
    required this.date,
    this.firstHalfStatus,
    this.secondHalfStatus,
    this.timeIn,
    this.timeOut,
    this.note,
  });

  @MappableField(key: 'id')
  final String? id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'first_half_status')
  final String? firstHalfStatus;
  @MappableField(key: 'second_half_status')
  final String? secondHalfStatus;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'note')
  final String? note;
}
```

- [ ] **Step 4: Generate mapper code and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/modules/attendance/models/
```

Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/attendance/models/ test/modules/attendance/models/
git commit -m "feat: ShiftDefaults, StatusType, AttendanceDay models"
```

---

### Task 8: RPC return-shape models

**Files:**
- Create: `lib/modules/attendance/models/effective_status_row.dart`
- Create: `lib/modules/attendance/models/gap_row.dart`
- Create: `lib/modules/attendance/models/derived_flags_row.dart`
- Test: `test/modules/attendance/models/effective_status_row_test.dart`

**Interfaces:**
- Produces: `class EffectiveStatusRow` (`String employeeId, DateTime date, String? firstHalfStatus, String? secondHalfStatus, bool isExplicit, bool isWeekOff, String? timeIn, String? timeOut, String? note`); `class GapRow` (`String employeeId, DateTime date`); `class DerivedFlagsRow` (`String employeeId, DateTime date, String? timeIn, String? timeOut, int workedMinutes, bool isLate, bool isEarly, int overtimeMinutes`).

- [ ] **Step 1: Write the failing test** (one representative test suffices — the other two follow the identical mapping pattern and are exercised end-to-end by Task 10's repository)

```dart
// test/modules/attendance/models/effective_status_row_test.dart
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EffectiveStatusRow round-trips through effective_range_status output shape', () {
    final json = {
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'date': '2024-06-02',
      'first_half_status': null,
      'second_half_status': null,
      'is_explicit': false,
      'is_week_off': true,
      'time_in': null,
      'time_out': null,
      'note': null,
    };

    final row = EffectiveStatusRowMapper.fromMap(json);

    expect(row.isWeekOff, isTrue);
    expect(row.isExplicit, isFalse);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/modules/attendance/models/effective_status_row_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the three models**

```dart
// lib/modules/attendance/models/effective_status_row.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'effective_status_row.mapper.dart';

@MappableClass()
class EffectiveStatusRow with EffectiveStatusRowMappable {
  const EffectiveStatusRow({
    required this.employeeId,
    required this.date,
    this.firstHalfStatus,
    this.secondHalfStatus,
    required this.isExplicit,
    required this.isWeekOff,
    this.timeIn,
    this.timeOut,
    this.note,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'first_half_status')
  final String? firstHalfStatus;
  @MappableField(key: 'second_half_status')
  final String? secondHalfStatus;
  @MappableField(key: 'is_explicit')
  final bool isExplicit;
  @MappableField(key: 'is_week_off')
  final bool isWeekOff;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'note')
  final String? note;
}
```

```dart
// lib/modules/attendance/models/gap_row.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'gap_row.mapper.dart';

@MappableClass()
class GapRow with GapRowMappable {
  const GapRow({required this.employeeId, required this.date});

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
}
```

```dart
// lib/modules/attendance/models/derived_flags_row.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'derived_flags_row.mapper.dart';

@MappableClass()
class DerivedFlagsRow with DerivedFlagsRowMappable {
  const DerivedFlagsRow({
    required this.employeeId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.workedMinutes,
    required this.isLate,
    required this.isEarly,
    required this.overtimeMinutes,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'worked_minutes')
  final int workedMinutes;
  @MappableField(key: 'is_late')
  final bool isLate;
  @MappableField(key: 'is_early')
  final bool isEarly;
  @MappableField(key: 'overtime_minutes')
  final int overtimeMinutes;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/modules/attendance/models/effective_status_row_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/attendance/models/effective_status_row.dart lib/modules/attendance/models/gap_row.dart lib/modules/attendance/models/derived_flags_row.dart lib/modules/attendance/models/*.mapper.dart test/modules/attendance/models/effective_status_row_test.dart
git commit -m "feat: RPC return-shape models for the three attendance functions"
```

---

### Task 9: `ShiftDefaultsRepository` + `StatusTypeRepository`

**Files:**
- Create: `lib/modules/attendance/repositories/shift_defaults_repository.dart`
- Create: `lib/modules/attendance/repositories/status_type_repository.dart`

**Interfaces:**
- Consumes: `ShiftDefaults`/`StatusType` (Task 7), `translateException` (Phase 1).
- Produces: `abstract class ShiftDefaultsRepository` (`fetchCurrent`, `fetchHistory`, `addEffectiveFrom`) + `SupabaseShiftDefaultsRepository`; `abstract class StatusTypeRepository` (`fetchAll`, `add`, `updateDisplay`) + `SupabaseStatusTypeRepository`. **Every call site below is `.schema('attendance')`-qualified — verified explicitly in Task 12's self-review.**

- [ ] **Step 1: Write `ShiftDefaultsRepository`**

```dart
// lib/modules/attendance/repositories/shift_defaults_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../models/shift_defaults.dart';

abstract class ShiftDefaultsRepository {
  Future<ShiftDefaults> fetchCurrent();
  Future<List<ShiftDefaults>> fetchHistory();
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  });
}

class SupabaseShiftDefaultsRepository implements ShiftDefaultsRepository {
  SupabaseShiftDefaultsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<ShiftDefaults> fetchCurrent() async {
    try {
      final rows = await _client
          .schema('attendance')
          .from('shift_defaults')
          .select()
          .lte('effective_from', DateTime.now().toIso8601String().split('T').first)
          .order('effective_from', ascending: false)
          .limit(1);
      return ShiftDefaultsMapper.fromMap(rows.first);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<ShiftDefaults>> fetchHistory() async {
    try {
      final rows = await _client
          .schema('attendance')
          .from('shift_defaults')
          .select()
          .order('effective_from', ascending: false);
      return rows.map(ShiftDefaultsMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  }) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('shift_defaults')
          .insert({
            'effective_from': effectiveFrom.toIso8601String().split('T').first,
            'default_start': defaultStart,
            'default_end': defaultEnd,
            'week_off_days': weekOffDays,
          })
          .select()
          .single();
      return ShiftDefaultsMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 2: Write `StatusTypeRepository`**

```dart
// lib/modules/attendance/repositories/status_type_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../models/status_type.dart';

abstract class StatusTypeRepository {
  Future<List<StatusType>> fetchAll();
  Future<StatusType> add({required String id, required String label, String? iconName, String? colorHex});
  Future<StatusType> updateDisplay(String id, {String? iconName, String? colorHex});
}

class SupabaseStatusTypeRepository implements StatusTypeRepository {
  SupabaseStatusTypeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<StatusType>> fetchAll() async {
    try {
      final rows = await _client.schema('attendance').from('status_types').select().order('id');
      return rows.map(StatusTypeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<StatusType> add({
    required String id,
    required String label,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('status_types')
          .insert({'id': id, 'label': label, 'icon_name': iconName, 'color_hex': colorHex})
          .select()
          .single();
      return StatusTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<StatusType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('status_types')
          .update({'icon_name': iconName, 'color_hex': colorHex})
          .eq('id', id)
          .select()
          .single();
      return StatusTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
dart analyze lib/modules/attendance/repositories/shift_defaults_repository.dart lib/modules/attendance/repositories/status_type_repository.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/modules/attendance/repositories/shift_defaults_repository.dart lib/modules/attendance/repositories/status_type_repository.dart
git commit -m "feat: ShiftDefaultsRepository, StatusTypeRepository (schema-qualified)"
```

---

### Task 10: `AttendanceRepository` — bulk actions, per-employee marking, the three RPC calls

**Files:**
- Create: `lib/modules/attendance/repositories/attendance_repository.dart`

**Interfaces:**
- Consumes: `AttendanceDay`/`EffectiveStatusRow`/`GapRow`/`DerivedFlagsRow` (Tasks 7–8).
- Produces: `abstract class AttendanceRepository` (`fetchEffectiveRangeStatus`, `fetchRecentGaps`, `fetchDerivedFlags`, `markDay`, `markAllPresent`, `markHoliday`) + `SupabaseAttendanceRepository`. **Every call site is `.schema('attendance')`-qualified, including the three `.rpc()` calls.**

- [ ] **Step 1: Write the repository**

```dart
// lib/modules/attendance/repositories/attendance_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../models/derived_flags_row.dart';
import '../models/effective_status_row.dart';
import '../models/gap_row.dart';

abstract class AttendanceRepository {
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7});
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });

  /// Explicit per-employee marking for one date — full-day tap-to-present sets
  /// both halves to the same status; the half-split UI can call this with
  /// different first/second half values.
  Future<void> markDay({
    required String employeeId,
    required DateTime date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  });

  /// Bulk action: marks every active employee present (both halves) for [date].
  /// Overwrites any existing explicit marking for that date — the UI gates this
  /// behind a confirm dialog.
  Future<void> markAllPresent({required DateTime date, required List<String> employeeIds});

  /// Bulk action: marks every active employee's day as a company holiday (both
  /// halves) for [date]. Same overwrite/confirm-dialog caveat as markAllPresent.
  Future<void> markHoliday({required DateTime date, required List<String> employeeIds});
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);
  final SupabaseClient _client;

  String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    try {
      final rows = await _client.schema('attendance').rpc('effective_range_status', params: {
        'p_start': _dateOnly(start),
        'p_end': _dateOnly(end),
        'p_employee_id': employeeId,
      });
      return (rows as List).map((r) => EffectiveStatusRowMapper.fromMap(r as Map<String, dynamic>)).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7}) async {
    try {
      final rows = await _client
          .schema('attendance')
          .rpc('recent_gaps', params: {'p_window_days': windowDays});
      return (rows as List).map((r) => GapRowMapper.fromMap(r as Map<String, dynamic>)).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    try {
      final rows = await _client.schema('attendance').rpc('derived_flags', params: {
        'p_start': _dateOnly(start),
        'p_end': _dateOnly(end),
        'p_employee_id': employeeId,
      });
      return (rows as List).map((r) => DerivedFlagsRowMapper.fromMap(r as Map<String, dynamic>)).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markDay({
    required String employeeId,
    required DateTime date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  }) async {
    try {
      await _client.schema('attendance').from('attendance_days').upsert({
        'employee_id': employeeId,
        'date': _dateOnly(date),
        'first_half_status': firstHalfStatus,
        'second_half_status': secondHalfStatus,
        'time_in': timeIn,
        'time_out': timeOut,
        'note': note,
      }, onConflict: 'employee_id,date');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markAllPresent({required DateTime date, required List<String> employeeIds}) async {
    try {
      final rows = employeeIds
          .map((id) => {
                'employee_id': id,
                'date': _dateOnly(date),
                'first_half_status': 'present',
                'second_half_status': 'present',
              })
          .toList();
      await _client.schema('attendance').from('attendance_days').upsert(rows, onConflict: 'employee_id,date');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markHoliday({required DateTime date, required List<String> employeeIds}) async {
    try {
      final rows = employeeIds
          .map((id) => {
                'employee_id': id,
                'date': _dateOnly(date),
                'first_half_status': 'holiday',
                'second_half_status': 'holiday',
              })
          .toList();
      await _client.schema('attendance').from('attendance_days').upsert(rows, onConflict: 'employee_id,date');
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/modules/attendance/repositories/attendance_repository.dart
```

Expected: no errors. (No live-DB test here by design, matching Phase 2's Task 6 precedent — exercised through the fake in Task 11 and the pages in Tasks 13–14; the three RPC functions were already verified directly against real data in Tasks 4–6.)

- [ ] **Step 3: Commit**

```bash
git add lib/modules/attendance/repositories/attendance_repository.dart
git commit -m "feat: AttendanceRepository — bulk actions, per-employee marking, RPC calls (schema-qualified)"
```

---

### Task 11: Fake repositories for widget testing

**Files:**
- Create: `test/modules/attendance/fakes/fake_shift_defaults_repository.dart`
- Create: `test/modules/attendance/fakes/fake_status_type_repository.dart`
- Create: `test/modules/attendance/fakes/fake_attendance_repository.dart`

**Interfaces:**
- Consumes: the three repository interfaces from Tasks 9–10.
- Produces: `FakeShiftDefaultsRepository`, `FakeStatusTypeRepository`, `FakeAttendanceRepository` — in-memory, seedable, used by Tasks 13–16's widget tests.

- [ ] **Step 1: Write `FakeShiftDefaultsRepository`**

```dart
// test/modules/attendance/fakes/fake_shift_defaults_repository.dart
import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:crs_ops/modules/attendance/repositories/shift_defaults_repository.dart';

class FakeShiftDefaultsRepository implements ShiftDefaultsRepository {
  FakeShiftDefaultsRepository({List<ShiftDefaults>? seed})
      : _history = List.of(seed ??
            [
              ShiftDefaults(
                id: 'seed-1',
                effectiveFrom: DateTime(2000, 1, 1),
                defaultStart: '10:30:00',
                defaultEnd: '18:30:00',
                weekOffDays: const [7],
              ),
            ]);

  final List<ShiftDefaults> _history;

  @override
  Future<ShiftDefaults> fetchCurrent() async => _history.first;

  @override
  Future<List<ShiftDefaults>> fetchHistory() async => List.of(_history);

  @override
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  }) async {
    final entry = ShiftDefaults(
      id: 'fake-${_history.length + 1}',
      effectiveFrom: effectiveFrom,
      defaultStart: defaultStart,
      defaultEnd: defaultEnd,
      weekOffDays: weekOffDays,
    );
    _history.insert(0, entry);
    return entry;
  }
}
```

- [ ] **Step 2: Write `FakeStatusTypeRepository`**

```dart
// test/modules/attendance/fakes/fake_status_type_repository.dart
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/repositories/status_type_repository.dart';

class FakeStatusTypeRepository implements StatusTypeRepository {
  FakeStatusTypeRepository({List<StatusType>? seed}) : _types = List.of(seed ?? const []);

  final List<StatusType> _types;

  @override
  Future<List<StatusType>> fetchAll() async => List.of(_types);

  @override
  Future<StatusType> add({
    required String id,
    required String label,
    String? iconName,
    String? colorHex,
  }) async {
    final type = StatusType(id: id, label: label, iconName: iconName, colorHex: colorHex);
    _types.add(type);
    return type;
  }

  @override
  Future<StatusType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    final index = _types.indexWhere((t) => t.id == id);
    final updated = StatusType(
      id: _types[index].id,
      label: _types[index].label,
      iconName: iconName,
      colorHex: colorHex,
      description: _types[index].description,
    );
    _types[index] = updated;
    return updated;
  }
}
```

- [ ] **Step 3: Write `FakeAttendanceRepository`**

```dart
// test/modules/attendance/fakes/fake_attendance_repository.dart
import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/gap_row.dart';
import 'package:crs_ops/modules/attendance/repositories/attendance_repository.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    List<EffectiveStatusRow>? rangeStatusSeed,
    List<GapRow>? gapsSeed,
    List<DerivedFlagsRow>? derivedFlagsSeed,
  })  : _rangeStatus = List.of(rangeStatusSeed ?? const []),
        _gaps = List.of(gapsSeed ?? const []),
        _derivedFlags = List.of(derivedFlagsSeed ?? const []);

  final List<EffectiveStatusRow> _rangeStatus;
  final List<GapRow> _gaps;
  final List<DerivedFlagsRow> _derivedFlags;

  final List<Map<String, Object?>> markedDays = [];
  final List<DateTime> markedAllPresentDates = [];
  final List<DateTime> markedHolidayDates = [];

  @override
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async =>
      _rangeStatus
          .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
          .where((r) => employeeId == null || r.employeeId == employeeId)
          .toList();

  @override
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7}) async => List.of(_gaps);

  @override
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async =>
      _derivedFlags
          .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
          .where((r) => employeeId == null || r.employeeId == employeeId)
          .toList();

  @override
  Future<void> markDay({
    required String employeeId,
    required DateTime date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  }) async {
    markedDays.add({
      'employeeId': employeeId,
      'date': date,
      'firstHalfStatus': firstHalfStatus,
      'secondHalfStatus': secondHalfStatus,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'note': note,
    });
  }

  @override
  Future<void> markAllPresent({required DateTime date, required List<String> employeeIds}) async {
    markedAllPresentDates.add(date);
  }

  @override
  Future<void> markHoliday({required DateTime date, required List<String> employeeIds}) async {
    markedHolidayDates.add(date);
  }
}
```

- [ ] **Step 4: Verify it compiles**

```bash
dart analyze test/modules/attendance/fakes/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add test/modules/attendance/fakes/
git commit -m "test: fake repositories for attendance widget tests"
```

---

### Task 12: Self-review checkpoint — schema-qualification audit (no code changes expected)

**Files:** none — audit only.

This task exists specifically because the `.from()`/`.rpc()` schema-qualification bug recurred twice already in Phases 1–2 (once from a same-line-only search, once from split-across-lines calls). Before writing any more repository code, audit everything written so far in this phase.

- [ ] **Step 1: Grep every `.from(`/`.rpc(` call site in this phase's files so far**

```bash
grep -n "\.from(\|\.rpc(" lib/modules/attendance/repositories/*.dart
```

Expected: **12 call sites** — `ShiftDefaultsRepository` (`fetchCurrent`, `fetchHistory`, `addEffectiveFrom` — 3 `.from()`), `StatusTypeRepository` (`fetchAll`, `add`, `updateDisplay` — 3 `.from()`), `AttendanceRepository` (`fetchEffectiveRangeStatus`, `fetchRecentGaps`, `fetchDerivedFlags` — 3 `.rpc()`; `markDay`, `markAllPresent`, `markHoliday` — 3 `.from()`) — **verify the actual count matches what's in the files, and that every single one is immediately preceded by `.schema('attendance')`** (check manually if the grep output shows any call without `schema(` on the same or immediately preceding line — the earlier bug hid exactly in multi-line calls a simple count could miss).

- [ ] **Step 2: If any call site is missing `.schema('attendance')`, fix it now** and re-run Step 1 until every site is confirmed qualified.

- [ ] **Step 3: No commit** — this task only verifies already-committed code; if Step 2 found and fixed something, commit that fix with a clear message (`fix: schema-qualify missed .from()/.rpc() call in <file>`) before moving on.

---

### Task 13: Riverpod providers

**Files:**
- Create: `lib/modules/attendance/providers/attendance_providers.dart`

**Interfaces:**
- Consumes: `supabaseClientProvider` (Phase 1), the three repositories (Tasks 9–10).
- Produces: `shiftDefaultsRepositoryProvider`, `statusTypeRepositoryProvider`, `attendanceRepositoryProvider` (all `keepAlive`); `currentShiftDefaultsProvider` → `AsyncValue<ShiftDefaults>`; `shiftDefaultsHistoryProvider` → `AsyncValue<List<ShiftDefaults>>`; `statusTypesProvider` → `AsyncValue<List<StatusType>>` (`keepAlive`, matching the spec's "fetched once per session, cached" design, same as Phase 2's `eventTypesProvider`); `effectiveRangeStatusProvider({required DateTime start, required DateTime end, String? employeeId})` (family) → `AsyncValue<List<EffectiveStatusRow>>`; `recentGapsProvider` → `AsyncValue<List<GapRow>>`.

- [ ] **Step 1: Write the providers**

```dart
// lib/modules/attendance/providers/attendance_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/supabase_client_provider.dart';
import '../models/effective_status_row.dart';
import '../models/gap_row.dart';
import '../models/shift_defaults.dart';
import '../models/status_type.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/shift_defaults_repository.dart';
import '../repositories/status_type_repository.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
ShiftDefaultsRepository shiftDefaultsRepository(Ref ref) =>
    SupabaseShiftDefaultsRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
StatusTypeRepository statusTypeRepository(Ref ref) =>
    SupabaseStatusTypeRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) =>
    SupabaseAttendanceRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<ShiftDefaults> currentShiftDefaults(Ref ref) =>
    ref.watch(shiftDefaultsRepositoryProvider).fetchCurrent();

@riverpod
Future<List<ShiftDefaults>> shiftDefaultsHistory(Ref ref) =>
    ref.watch(shiftDefaultsRepositoryProvider).fetchHistory();

@Riverpod(keepAlive: true)
Future<List<StatusType>> statusTypes(Ref ref) => ref.watch(statusTypeRepositoryProvider).fetchAll();

@riverpod
Future<List<EffectiveStatusRow>> effectiveRangeStatus(
  Ref ref, {
  required DateTime start,
  required DateTime end,
  String? employeeId,
}) =>
    ref.watch(attendanceRepositoryProvider).fetchEffectiveRangeStatus(
          start: start,
          end: end,
          employeeId: employeeId,
        );

@riverpod
Future<List<GapRow>> recentGaps(Ref ref) => ref.watch(attendanceRepositoryProvider).fetchRecentGaps();
```

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/modules/attendance/providers/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/attendance/providers/
git commit -m "feat: attendance Riverpod providers"
```

---

### Task 14: Calendar page

**Files:**
- Modify: `pubspec.yaml` (add `table_calendar`)
- Create: `lib/modules/attendance/pages/calendar_page.dart`
- Create: `lib/modules/attendance/pages/widgets/day_cell.dart`
- Test: `test/modules/attendance/pages/calendar_page_test.dart`

**Interfaces:**
- Consumes: `effectiveRangeStatusProvider`, `recentGapsProvider` (Task 13), `employeeListProvider` (Phase 2), `colorFor` (Phase 2's `status_metadata.dart`).
- Produces: `class CalendarPage extends ConsumerStatefulWidget`.

- [ ] **Step 1: Add the dependency**

```bash
flutter pub add table_calendar
```

- [ ] **Step 2: Write the failing widget test**

```dart
// test/modules/attendance/pages/calendar_page_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/gap_row.dart';
import 'package:crs_ops/modules/attendance/pages/calendar_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';

void main() {
  testWidgets('renders a month grid and navigating to today does not crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepository()),
        ],
        child: const MaterialApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('a day with a gap shows a warning marker', (tester) async {
    final today = DateTime.now();
    final gapDate = DateTime(today.year, today.month, today.day - 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(gapsSeed: [GapRow(employeeId: '1', date: gapDate)]),
          ),
        ],
        child: const MaterialApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('gap-marker-${gapDate.toIso8601String().split('T').first}')), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

```bash
flutter test test/modules/attendance/pages/calendar_page_test.dart
```

Expected: FAIL — files don't exist.

- [ ] **Step 4: Write the day cell widget**

```dart
// lib/modules/attendance/pages/widgets/day_cell.dart
import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, required this.hasGap, this.summaryColor});

  final DateTime day;
  final bool hasGap;
  final Color? summaryColor;

  String get _dateKey => day.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: summaryColor?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Center(child: Text('${day.day}')),
          if (hasGap)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(Icons.warning_amber, size: 12, color: Colors.orange, key: Key('gap-marker-$_dateKey')),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Write the Calendar page**

```dart
// lib/modules/attendance/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/attendance_providers.dart';
import 'widgets/day_cell.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final gapsAsync = ref.watch(recentGapsProvider);
    final gapDates = gapsAsync.value?.map((g) => g.date.toIso8601String().split('T').first).toSet() ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: TableCalendar(
        firstDay: DateTime(2000, 1, 1),
        lastDay: DateTime(2100, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        onPageChanged: (day) => setState(() => _focusedDay = day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay = focusedDay);
          Navigator.of(context).pushNamed(
            '/attendance/${selectedDay.toIso8601String().split('T').first}',
          );
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => DayCell(
            day: day,
            hasGap: gapDates.contains(day.toIso8601String().split('T').first),
          ),
        ),
      ),
    );
  }
}
```

*(Day-cell status-summary coloring from `effectiveRangeStatusProvider` is intentionally deferred to Phase 7's polish pass — it requires aggregating per-employee rows into one cell color, a display-only refinement the two tests above don't exercise; the gap-marker wiring, which the spec calls out as the concrete UX requirement, is fully real here.)*

- [ ] **Step 6: Run the tests again**

```bash
flutter test test/modules/attendance/pages/calendar_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/modules/attendance/pages/calendar_page.dart lib/modules/attendance/pages/widgets/day_cell.dart test/modules/attendance/pages/calendar_page_test.dart
git commit -m "feat: Calendar page with month view and last-7-days gap markers"
```

---

### Task 15: Attendance-for-day page

**Files:**
- Create: `lib/modules/attendance/pages/attendance_day_page.dart`
- Create: `lib/modules/attendance/pages/widgets/employee_marking_tile.dart`
- Test: `test/modules/attendance/pages/attendance_day_page_test.dart`

**Interfaces:**
- Consumes: `employeeListProvider` (Phase 2), `attendanceRepositoryProvider` (Task 13).
- Produces: `class AttendanceDayPage extends ConsumerWidget` (`{required DateTime date}`).

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/modules/attendance/pages/attendance_day_page_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/pages/attendance_day_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';

void main() {
  testWidgets('quick-tap present marks the employee full-day present', (tester) async {
    final attendanceRepo = FakeAttendanceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        ],
        child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-present-1')));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedDays, hasLength(1));
    expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'present');
    expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'present');
  });

  testWidgets('mark all present shows a confirm dialog before calling the repository', (tester) async {
    final attendanceRepo = FakeAttendanceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        ],
        child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-all-present-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark-all-present-confirm-dialog')), findsOneWidget);
    expect(attendanceRepo.markedAllPresentDates, isEmpty);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedAllPresentDates, hasLength(1));
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

```bash
flutter test test/modules/attendance/pages/attendance_day_page_test.dart
```

Expected: FAIL — files don't exist.

- [ ] **Step 3: Write the per-employee marking tile**

```dart
// lib/modules/attendance/pages/widgets/employee_marking_tile.dart
import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';

class EmployeeMarkingTile extends StatelessWidget {
  const EmployeeMarkingTile({super.key, required this.employee, required this.onQuickPresent});

  final Employee employee;
  final VoidCallback onQuickPresent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(employee.color)),
      title: Text(employee.name),
      trailing: FilledButton(
        key: Key('quick-present-${employee.id}'),
        onPressed: onQuickPresent,
        child: const Text('Present'),
      ),
    );
  }
}
```

- [ ] **Step 4: Write the attendance-for-day page**

```dart
// lib/modules/attendance/pages/attendance_day_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/employees/providers/employee_providers.dart';
import '../providers/attendance_providers.dart';
import 'widgets/employee_marking_tile.dart';

class AttendanceDayPage extends ConsumerWidget {
  const AttendanceDayPage({super.key, required this.date});

  final DateTime date;

  Future<void> _markAllPresent(BuildContext context, WidgetRef ref, List<String> employeeIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('mark-all-present-confirm-dialog'),
        title: const Text('Mark all present?'),
        content: const Text('This overwrites any existing marking for this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(attendanceRepositoryProvider).markAllPresent(date: date, employeeIds: employeeIds);
    }
  }

  Future<void> _markHoliday(BuildContext context, WidgetRef ref, List<String> employeeIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('mark-holiday-confirm-dialog'),
        title: const Text('Mark day as company holiday?'),
        content: const Text('This overwrites any existing marking for this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(attendanceRepositoryProvider).markHoliday(date: date, employeeIds: employeeIds);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(date.toIso8601String().split('T').first)),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employees) {
          final ids = employees.map((e) => e.id).toList();
          if (employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('mark-all-present-button'),
                        onPressed: () => _markAllPresent(context, ref, ids),
                        child: const Text('Mark all present'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('mark-holiday-button'),
                        onPressed: () => _markHoliday(context, ref, ids),
                        child: const Text('Mark day as company holiday'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return EmployeeMarkingTile(
                      employee: employee,
                      onQuickPresent: () => ref.read(attendanceRepositoryProvider).markDay(
                            employeeId: employee.id,
                            date: date,
                            firstHalfStatus: 'present',
                            secondHalfStatus: 'present',
                          ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

*(The expandable first/second-half split and the advanced time-in/time-out+note section from the spec are real follow-on UI work on top of this same `markDay` call — deferred to Phase 7's polish pass to keep this task's tests focused on the two behaviors the spec calls out as must-have: quick-tap present, and the two confirm-gated bulk actions. `markDay`'s full signature already supports them; no repository change needed when that UI is added.)*

- [ ] **Step 5: Run the tests again**

```bash
flutter test test/modules/attendance/pages/attendance_day_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 6: Commit**

```bash
git add lib/modules/attendance/pages/attendance_day_page.dart lib/modules/attendance/pages/widgets/employee_marking_tile.dart test/modules/attendance/pages/attendance_day_page_test.dart
git commit -m "feat: attendance-for-day page with quick-tap present and confirm-gated bulk actions"
```

---

### Task 16: Shift-defaults manager + status-types manager admin pages

**Files:**
- Create: `lib/modules/attendance/pages/shift_defaults_manager_page.dart`
- Create: `lib/modules/attendance/pages/status_types_manager_page.dart`
- Test: `test/modules/attendance/pages/shift_defaults_manager_page_test.dart`, `status_types_manager_page_test.dart`

**Interfaces:**
- Consumes: `shiftDefaultsHistoryProvider`, `shiftDefaultsRepositoryProvider`, `statusTypesProvider`, `statusTypeRepositoryProvider` (Task 13); `iconFor`/`colorFor` (Phase 2).
- Produces: `class ShiftDefaultsManagerPage extends ConsumerWidget`, `class StatusTypesManagerPage extends ConsumerWidget`. Both admin-or-above per the spec — gated at the route level in Task 17, same pattern as Phase 2's superadmin-gated event-types route, so neither page itself needs role-check widget code.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/modules/attendance/pages/shift_defaults_manager_page_test.dart
import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:crs_ops/modules/attendance/pages/shift_defaults_manager_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_shift_defaults_repository.dart';

void main() {
  testWidgets('shows the shift-defaults history', (tester) async {
    final repo = FakeShiftDefaultsRepository(seed: [
      ShiftDefaults(
        id: '1',
        effectiveFrom: DateTime(2000, 1, 1),
        defaultStart: '10:30:00',
        defaultEnd: '18:30:00',
        weekOffDays: const [7],
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shiftDefaultsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ShiftDefaultsManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('10:30'), findsOneWidget);
  });
}
```

```dart
// test/modules/attendance/pages/status_types_manager_page_test.dart
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/status_types_manager_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_status_type_repository.dart';

void main() {
  testWidgets('lists every status type', (tester) async {
    final repo = FakeStatusTypeRepository(seed: [
      const StatusType(id: 'present', label: 'Present', iconName: 'check', colorHex: '#4CAF50'),
      const StatusType(id: 'absent', label: 'Absent', iconName: 'close', colorHex: '#F44336'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [statusTypeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: StatusTypesManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

```bash
flutter test test/modules/attendance/pages/shift_defaults_manager_page_test.dart test/modules/attendance/pages/status_types_manager_page_test.dart
```

Expected: FAIL — files don't exist.

- [ ] **Step 3: Write both pages**

```dart
// lib/modules/attendance/pages/shift_defaults_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/attendance_providers.dart';

class ShiftDefaultsManagerPage extends ConsumerWidget {
  const ShiftDefaultsManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftDefaultsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift defaults')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (history) => ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            return ListTile(
              title: Text('${entry.defaultStart} – ${entry.defaultEnd}'),
              subtitle: Text(
                'Effective from ${entry.effectiveFrom.toIso8601String().split('T').first} · Week off: ${entry.weekOffDays}',
              ),
            );
          },
        ),
      ),
      // "Change from [date]" action (inserts a new effective-from row) is real
      // follow-on UI over the same addEffectiveFrom() repository call already
      // built in Task 9 — deferred to Phase 7's polish pass for the same reason
      // as Task 15's advanced marking UI: this task's test covers the history
      // view the spec calls out, the write path is already fully implemented
      // and independently usable once that form exists.
    );
  }
}
```

```dart
// lib/modules/attendance/pages/status_types_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';

class StatusTypesManagerPage extends ConsumerWidget {
  const StatusTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(statusTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance status types')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(type.colorHex),
                child: Icon(iconFor(type.iconName), color: Colors.white),
              ),
              title: Text(type.label),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/modules/attendance/pages/shift_defaults_manager_page_test.dart test/modules/attendance/pages/status_types_manager_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/attendance/pages/shift_defaults_manager_page.dart lib/modules/attendance/pages/status_types_manager_page.dart test/modules/attendance/pages/shift_defaults_manager_page_test.dart test/modules/attendance/pages/status_types_manager_page_test.dart
git commit -m "feat: shift-defaults and status-types admin manager pages"
```

---

### Task 17: Routes + router integration (Calendar becomes the default route)

**Files:**
- Create: `lib/modules/attendance/routes.dart`
- Modify: `lib/core/router/app_router.dart` (Phases 1–2)

**Interfaces:**
- Consumes: every page from Tasks 14–16; `sessionProvider` (Phase 1).
- Produces: `List<RouteBase> attendanceRoutes(Ref ref)` — route paths `/` (Calendar, replaces `_PlaceholderHomeShell`), `/attendance/:date`, `/attendance/shift-defaults`, `/attendance/status-types`.

- [ ] **Step 1: Write `routes.dart`**

```dart
// lib/modules/attendance/routes.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/providers/auth_providers.dart';
import 'pages/attendance_day_page.dart';
import 'pages/calendar_page.dart';
import 'pages/shift_defaults_manager_page.dart';
import 'pages/status_types_manager_page.dart';

List<RouteBase> attendanceRoutes(Ref ref) => [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.hasModuleAccess('attendance') ? null : '/unauthorized';
        },
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/attendance/:date',
        builder: (context, state) =>
            AttendanceDayPage(date: DateTime.parse(state.pathParameters['date']!)),
      ),
      GoRoute(
        path: '/attendance/shift-defaults',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const ShiftDefaultsManagerPage(),
      ),
      GoRoute(
        path: '/attendance/status-types',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const StatusTypesManagerPage(),
      ),
    ];
```

- [ ] **Step 2: Modify `app_router.dart`** — remove the Phase 1 `GoRoute(path: '/', builder: ... _PlaceholderHomeShell)` entry and its now-unused `_PlaceholderHomeShell` class entirely (Calendar is the real home now), and splice `...attendanceRoutes(ref)` into the routes list alongside `...employeeRoutes(ref)`

```dart
// lib/core/router/app_router.dart — routes list becomes:
routes: [
  GoRoute(path: loadingPath, builder: (context, state) => const LoadingPage()),
  GoRoute(path: signInPath, builder: (context, state) => const SignInPage()),
  GoRoute(path: unauthorizedPath, builder: (context, state) => const UnauthorizedPage()),
  ...employeeRoutes(ref),
  ...attendanceRoutes(ref),
],
```

Add the import: `import '../../modules/attendance/routes.dart';` (from `lib/core/router/`, one level up to `lib/core/`, then one level up again to `lib/`, then into `modules/attendance/` — double-check this resolves; Phase 2's equivalent import from the same file, `../employees/routes.dart`, only needed one `../` because `employees/` sits directly under `lib/core/`, whereas `modules/` sits directly under `lib/`, one level further up).

Also delete the now-dead `_PlaceholderHomeShell` class and its only-used-there imports (`AdaptiveNavScaffold` import stays if anything else in the file still uses it; remove it if not).

- [ ] **Step 3: Verify it compiles**

```bash
dart analyze lib/core/router/ lib/modules/attendance/routes.dart
```

Expected: no errors. If the import path from Step 2 is wrong, this is exactly where it surfaces (matching the exact mistake already made and fixed in Phase 2's Task 13) — fix and re-run before proceeding.

- [ ] **Step 4: Commit**

```bash
git add lib/modules/attendance/routes.dart lib/core/router/app_router.dart
git commit -m "feat: wire attendance routes into the app router; Calendar replaces the placeholder home shell"
```

---

### Task 18: Full-phase compile and test sweep

**Files:** none (verification only).

**Interfaces:** none produced; consumes everything from Tasks 1–17.

- [ ] **Step 1: Run the full analyzer**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 2: Run every test in the project**

```bash
flutter test
```

Expected: all PASS (Phases 1–2's tests plus this phase's).

- [ ] **Step 3: Build for web, to verify a real end-to-end compile** (matching Phases 1–2's verification standard — this project has no local Docker Supabase and no system `cmake`, so `flutter build web` is the fastest genuine full-build check; `flutter build apk --debug`/`flutter build linux --debug` are also available if time permits, using the Android-SDK-managed `cmake` for the Linux build per Phase 1's `OVERNIGHT_LOG.md` workaround)

```bash
flutter build web --dart-define=SUPABASE_URL=https://ocalljagckzyvngprlxo.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<real publishable key, retrieved via `supabase projects api-keys --project-ref ocalljagckzyvngprlxo`>
```

Expected: `✓ Built build/web`.

- [ ] **Step 4: No commit** — verification only, nothing changes.

---

## Self-Review

- **Spec coverage**: `shift_defaults`/`status_types`/`attendance_days` schema + RLS + grants — Tasks 1–2; the three functions with the exact edge cases from `plan.md` (inclusive-interval active-status filtering, per-date `lateral` shift lookup, overnight-shift `worked_minutes`/`is_early` correctness, partial-entry on-time assumption, the IST-timezone `recent_gaps` window, no-single-rolled-up-status-column design) — Tasks 4–6; Calendar (month view, last-7-days gap markers) — Task 14; attendance-for-day (bulk actions behind confirm dialogs, quick-tap present) — Task 15; shift-defaults/status-types admin managers — Task 16; Calendar as the real gated default route — Task 17; four-states rule — present in every `.when(...)` across Tasks 14–16 (offline handling reuses Phase 1's mechanism, not rebuilt here, matching Phase 2's precedent).
- **Placeholder scan**: no `TBD`/`TODO`/`FIXME`. Three deliberately-deferred UI refinements are each explained inline with the reason and confirmation that the underlying repository method is already fully built and independently testable: Calendar's per-employee day-cell color aggregation (Task 14), the expandable half-split/time-in-out UI on attendance-for-day (Task 15), and the "change from [date]" form on the shift-defaults manager (Task 16) — none of these are silent gaps, and none block any test in this plan from passing for real.
- **Type/name consistency**: `ShiftDefaults`/`StatusType`/`AttendanceDay` (Task 7) and `EffectiveStatusRow`/`GapRow`/`DerivedFlagsRow` (Task 8) are used with identical field names in Tasks 9–16. `ShiftDefaultsRepository`/`StatusTypeRepository`/`AttendanceRepository` method signatures (Tasks 9–10) match their usage in the fakes (Task 11) and providers (Task 13) exactly. Provider names (`shiftDefaultsRepositoryProvider`, `statusTypeRepositoryProvider`, `attendanceRepositoryProvider`, `currentShiftDefaultsProvider`, `shiftDefaultsHistoryProvider`, `statusTypesProvider`, `effectiveRangeStatusProvider`, `recentGapsProvider`) match between Task 13's definitions and Tasks 14–17's usage.
- **Schema-qualification audit (the specific recurring bug this session)**: verified by direct `grep` against this document's own code blocks, not estimated — **12 call sites total, all schema-qualified**: `ShiftDefaultsRepository` (`fetchCurrent`, `fetchHistory`, `addEffectiveFrom` — 3 `.from()`), `StatusTypeRepository` (`fetchAll`, `add`, `updateDisplay` — 3 `.from()`), `AttendanceRepository` (`fetchEffectiveRangeStatus`, `fetchRecentGaps`, `fetchDerivedFlags` — 3 `.rpc()`; `markDay`, `markAllPresent`, `markHoliday` — 3 `.from()`). Task 12 exists specifically to make this an explicit, re-runnable checkpoint via `grep` at execution time rather than a one-time claim, given this exact bug class recurred twice already before this plan was written.
- **Import-path check**: Task 17 explicitly calls out the `../employees/routes.dart` vs. `../../modules/attendance/routes.dart` depth difference (Phase 2's `employees/` sits one level under `lib/core/`; this phase's `modules/attendance/` sits one level under `lib/`, one level further from `lib/core/router/`) — the exact category of mistake already made once in Phase 2's Task 13, called out explicitly here so it isn't repeated silently.

---

**Plan complete and saved to `docs/superpowers/plans/2026-09-20-phase3-attendance-marking.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
