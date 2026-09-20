# CRS Ops — Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `core` Supabase schema (auth, roles, employees, RLS), the manual bootstrap runbook, and the Flutter app's authentication/routing/logging/error-handling skeleton — everything every later phase depends on.

**Architecture:** Postgres does the authorization/business-rule work (RLS + security-definer functions + a signup allow-list trigger); Flutter is a thin session-driven shell — a `GoRouter` gated by a single `AppSession` computed from Supabase Auth + `core` tables, wrapped in a hand-rolled adaptive nav shell, with `talker`-based logging and a translated-exception layer used by every repository from day one.

**Tech Stack:** Flutter (Riverpod + `riverpod_generator`, `go_router`, `dart_mappable`), Supabase (Postgres + Auth + PostgREST), `talker`/`talker_flutter`/`talker_riverpod_logger`, `connectivity_plus`, `google_sign_in`.

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (sections: Context, Schema → `core` schema + RLS pattern, Flutter app structure, Screens → Sign-in, Build order → Phase 1, Verification, Critical files). This plan implements Phase 1 only — attendance-schema tables/functions are Phase 3, and are **not** touched here.

## Global Constraints

- Two schemas exist long-term (`core`, `attendance`); this plan creates **`core` only**. Never create `attendance.*` objects in this plan.
- Every categorical/open-ended value (`event_type` here) is a real lookup table with an FK, never a bare `text` column with no constraint — but only when the app needs attached metadata off it (icon/color, or a classification flag). `core.event_types` needs both here.
- All SQL is versioned in `supabase/migrations/*.sql` via the Supabase CLI — never hand-pasted only into the hosted SQL editor.
- Three `security definer` functions (`core.is_superadmin()`, `core.is_admin_or_above()`, `core.has_module_access(p_module)`) are the only functions allowed to bypass RLS; every other function/view runs with the invoking user's own RLS.
- Views must be created `with (security_invoker = true)` — otherwise RLS is checked against the view owner, not the querying user, silently defeating RLS.
- English only. Online-only (no offline-first caching) — a genuine no-internet state gets its own full-screen treatment, not a generic error.
- Every repository call must end in a successful result or a translated `AppException` — never an unhandled exception or a silently-ignored failure.
- `flutter_adaptive_scaffold` is discontinued (April 2025) — the adaptive nav shell is hand-rolled against stock `NavigationBar`/`NavigationRail`, no third-party nav-shell dependency.

---

## File Structure

**Supabase:**
- `supabase/migrations/<timestamp>_core_schema.sql` — the entire `core` schema, RLS, and functions for this phase (one file, built up across Tasks 3–8).
- `supabase/README.md` — the one-time manual bootstrap runbook.

**Flutter — `core/` (all new files this phase):**
- `lib/bootstrap/supabase_bootstrap.dart` — `Supabase.initialize` wrapper.
- `lib/core/data/supabase_client_provider.dart` — exposes the `SupabaseClient` singleton to Riverpod.
- `lib/core/logging/app_talker.dart` — the global `Talker` instance (file-persisted).
- `lib/core/errors/app_exception.dart` — sealed `AppException` hierarchy.
- `lib/core/errors/exception_translator.dart` — raw exception → `AppException`.
- `lib/core/connectivity/connectivity_provider.dart` — online/offline stream provider.
- `lib/core/widgets/offline_screen.dart` — full-screen "no internet" state.
- `lib/core/widgets/adaptive_nav_scaffold.dart` — bottom-bar/rail switch at 600dp.
- `lib/core/auth/models/app_session.dart` — `AppRole` enum + `AppSession` (`dart_mappable`).
- `lib/core/auth/repositories/auth_repository.dart` — sign-in/out.
- `lib/core/auth/repositories/roles_repository.dart` — role + module-access reads.
- `lib/core/auth/providers/auth_providers.dart` — all `@riverpod` auth/session providers (one file — they're small and tightly coupled).
- `lib/core/auth/pages/sign_in_page.dart`, `unauthorized_page.dart`, `loading_page.dart`.
- `lib/core/router/redirect_logic.dart` — pure redirect function (no `GoRouter` dependency, so it's unit-testable).
- `lib/core/router/app_router.dart` — the actual `GoRouter` + route table.
- `lib/core/theme/app_theme.dart` — Material 3 theme.
- `lib/app.dart` — `MaterialApp.router`.
- `lib/main.dart` — modified: bootstrap + `ProviderScope` + `runApp(App())`.

**Tests:**
- `test/core/router/redirect_logic_test.dart`
- `test/core/errors/exception_translator_test.dart`
- `test/core/auth/models/app_session_test.dart`
- `test/core/widgets/adaptive_nav_scaffold_test.dart`

---

### Task 1: Supabase project setup (manual)

**Files:** none (external configuration + a note file).
- Create: `supabase/README.md` (started here, appended to in Task 9).

**Interfaces:**
- Produces: a running local Supabase dev stack (`supabase start`), and a hosted Supabase project with Google OAuth enabled and `core`/`attendance` exposed via PostgREST — later tasks assume both exist.

- [ ] **Step 1: Install the Supabase CLI and initialize the project**

```bash
brew install supabase/tap/supabase   # or: npm install -g supabase
cd /home/chiggy/Projects/crs_ops
supabase init
```

- [ ] **Step 2: Start the local dev stack**

```bash
supabase start
```

Expected: prints a local `API URL`, `DB URL` (default `postgresql://postgres:postgres@127.0.0.1:54322/postgres`), `anon key`, and `service_role key`. Keep this output — later tasks reference the DB URL for verification queries.

- [ ] **Step 3: Create the hosted Supabase project** (Studio, https://supabase.com/dashboard)

Create a new project in its own organization/project (separate from CRS Manager's project, per the spec). Note its project ref, URL, and anon key.

- [ ] **Step 4: Enable Google as an Auth provider** (hosted project, Studio → Authentication → Providers → Google)

Create a Google OAuth client (Google Cloud Console → APIs & Services → Credentials → OAuth client ID), add the Supabase-provided redirect URL as an authorized redirect URI, paste the client ID/secret into Supabase's Google provider settings, enable it.

- [ ] **Step 5: Expose the `core` and `attendance` schemas via PostgREST** (Studio → Settings → API → *Exposed schemas*)

Add `core` and `attendance` to the exposed schema list (both now, even though `attendance` is empty until Phase 3) — otherwise every `.from()`/`.rpc()` call in later phases 404s.

- [ ] **Step 6: Start the bootstrap runbook file**

```markdown
# CRS Ops — Supabase bootstrap runbook

One-time manual steps. Not an app feature — see Phase 1 plan Task 1 and Task 9.

## Project setup
- Hosted project ref: <fill in after Task 1 Step 3>
- Google OAuth provider: enabled per Task 1 Step 4
- Exposed schemas: `core`, `attendance` (Task 1 Step 5)
```

- [ ] **Step 7: Commit**

```bash
git add supabase/README.md supabase/config.toml
git commit -m "chore: initialize Supabase project and enable Google OAuth"
```

---

### Task 2: Flutter dependencies

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: every package name referenced by later tasks (`supabase_flutter`, `flutter_riverpod`, `riverpod_annotation`, `dart_mappable`, `go_router`, `google_sign_in`, `talker`, `talker_flutter`, `talker_riverpod_logger`, `connectivity_plus`, `path_provider`).

- [ ] **Step 1: Add runtime dependencies**

```bash
flutter pub add supabase_flutter flutter_riverpod riverpod_annotation dart_mappable go_router google_sign_in talker talker_flutter talker_riverpod_logger connectivity_plus path_provider
```

- [ ] **Step 2: Add dev/codegen dependencies**

```bash
flutter pub add --dev build_runner riverpod_generator dart_mappable_builder
```

- [ ] **Step 3: Verify it resolves**

```bash
flutter pub get
```

Expected: no version-solve errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add Supabase, Riverpod, dart_mappable, go_router, talker, connectivity_plus"
```

---

### Task 3: Core schema — signup allow-list + profiles

**Files:**
- Create: `supabase/migrations/<timestamp>_core_schema.sql` (created here, appended to by Tasks 4–8)

**Interfaces:**
- Produces: `core.allowed_signup_emails(email, note, added_by, added_at)`, `core.check_allowed_signup()`, `core.profiles(id, email, created_at)`, `core.handle_new_user()`. Every later task's RLS/repository code assumes these exact table/column names.

- [ ] **Step 1: Create the migration file**

```bash
supabase migration new core_schema
```

Note the generated filename (`supabase/migrations/<timestamp>_core_schema.sql`) — every remaining SQL task appends to this same file.

- [ ] **Step 2: Write the schema, allow-list table, and its trigger**

```sql
-- supabase/migrations/<timestamp>_core_schema.sql

create schema if not exists core;

create table core.allowed_signup_emails (
  email text primary key,
  note text,
  added_by uuid references auth.users(id),
  added_at timestamptz not null default now()
);

create or replace function core.check_allowed_signup()
returns trigger
language plpgsql
security definer
set search_path = core, public
as $$
begin
  if not exists (
    select 1 from core.allowed_signup_emails
    where lower(email) = lower(new.email)
  ) then
    raise exception 'Sign-up not permitted for this email address.';
  end if;
  return new;
end;
$$;

create trigger enforce_allowed_signup
  before insert on auth.users
  for each row
  execute function core.check_allowed_signup();

create table core.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  created_at timestamptz not null default now()
);

create or replace function core.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = core, public
as $$
begin
  insert into core.profiles (id, email) values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function core.handle_new_user();

alter table core.allowed_signup_emails enable row level security;
```

(RLS policies for `allowed_signup_emails` are added in Task 4, once `core.is_superadmin()` exists — a policy can't reference a function that doesn't exist yet.)

- [ ] **Step 3: Apply the migration locally**

```bash
supabase db reset
```

Expected: applies cleanly, no errors.

- [ ] **Step 4: Verify the allow-list trigger rejects an unlisted email**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c \
  "insert into auth.users (id, email) values (gen_random_uuid(), 'nobody@example.com');"
```

Expected: **FAILS** with `Sign-up not permitted for this email address.`

- [ ] **Step 5: Verify an allow-listed email is accepted and populates `core.profiles`**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.allowed_signup_emails (email, note) values ('test@example.com', 'test');
insert into auth.users (id, email) values (gen_random_uuid(), 'test@example.com');
select email from core.profiles where email = 'test@example.com';
SQL
```

Expected: the final `select` returns one row (`test@example.com`).

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): allowed_signup_emails allow-list + profiles auto-populate trigger"
```

---

### Task 4: Core schema — roles, user_roles, RLS security-definer functions

**Files:**
- Modify: `supabase/migrations/<timestamp>_core_schema.sql`

**Interfaces:**
- Produces: `core.roles(id)` seeded `superadmin`/`admin`/`employee`; `core.user_roles(user_id, role_id, granted_by, granted_at)`; `core.is_superadmin()`, `core.is_admin_or_above()` — both `language sql stable security definer`, callable from any RLS policy without recursion.

- [ ] **Step 1: Append roles + user_roles + the two role-checking functions**

```sql
create table core.roles (
  id text primary key
);

insert into core.roles (id) values ('superadmin'), ('admin'), ('employee');

create table core.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id text not null references core.roles(id),
  granted_by uuid references auth.users(id),
  granted_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create or replace function core.is_superadmin()
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select exists (
    select 1 from core.user_roles
    where user_id = auth.uid() and role_id = 'superadmin'
  );
$$;

create or replace function core.is_admin_or_above()
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select exists (
    select 1 from core.user_roles
    where user_id = auth.uid() and role_id in ('superadmin', 'admin')
  );
$$;

alter table core.roles enable row level security;
create policy roles_select_authenticated on core.roles
  for select using (auth.role() = 'authenticated');

alter table core.user_roles enable row level security;
create policy user_roles_select on core.user_roles
  for select using (user_id = auth.uid() or core.is_admin_or_above());
create policy user_roles_write on core.user_roles
  for all using (core.is_superadmin()) with check (core.is_superadmin());

-- now that core.is_superadmin() exists, finish allowed_signup_emails' RLS from Task 3
create policy allowed_signup_emails_select on core.allowed_signup_emails
  for select using (core.is_superadmin());
create policy allowed_signup_emails_write on core.allowed_signup_emails
  for all using (core.is_superadmin()) with check (core.is_superadmin());

alter table core.profiles enable row level security;
create policy profiles_select_own_or_admin on core.profiles
  for select using (id = auth.uid() or core.is_admin_or_above());
```

- [ ] **Step 2: Apply and verify the functions return false with no role granted**

```bash
supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c \
  "select core.is_superadmin(), core.is_admin_or_above();"
```

Expected: both `f` (no `auth.uid()` in a raw `psql` session, so both correctly evaluate false).

- [ ] **Step 3: Verify a granted role is honored**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.allowed_signup_emails (email) values ('admin-test@example.com');
insert into auth.users (id, email) values ('11111111-1111-1111-1111-111111111111', 'admin-test@example.com');
insert into core.user_roles (user_id, role_id) values ('11111111-1111-1111-1111-111111111111', 'admin');
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111"}';
select core.is_admin_or_above(), core.is_superadmin();
SQL
```

Expected: `t, f`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): roles, user_roles, is_superadmin/is_admin_or_above RLS functions"
```

---

### Task 5: Core schema — modules, module_access, has_module_access

**Files:**
- Modify: `supabase/migrations/<timestamp>_core_schema.sql`

**Interfaces:**
- Produces: `core.modules(id, name, description)` seeded with `attendance`; `core.module_access(user_id, module_id, granted_by, granted_at)`; `core.has_module_access(p_module text)`.

- [ ] **Step 1: Append modules + module_access + the access function**

```sql
create table core.modules (
  id text primary key,
  name text not null,
  description text
);

insert into core.modules (id, name, description)
  values ('attendance', 'Attendance', 'Employee attendance tracking');

create table core.module_access (
  user_id uuid not null references auth.users(id) on delete cascade,
  module_id text not null references core.modules(id),
  granted_by uuid references auth.users(id),
  granted_at timestamptz not null default now(),
  primary key (user_id, module_id)
);

create or replace function core.has_module_access(p_module text)
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select core.is_admin_or_above() or exists (
    select 1 from core.module_access
    where user_id = auth.uid() and module_id = p_module
  );
$$;

alter table core.modules enable row level security;
create policy modules_select_authenticated on core.modules
  for select using (auth.role() = 'authenticated');

alter table core.module_access enable row level security;
create policy module_access_select on core.module_access
  for select using (user_id = auth.uid() or core.is_admin_or_above());
create policy module_access_write on core.module_access
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());
```

- [ ] **Step 2: Apply and verify admin-or-above bypasses `module_access` entirely**

```bash
supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.allowed_signup_emails (email) values ('admin-test@example.com');
insert into auth.users (id, email) values ('11111111-1111-1111-1111-111111111111', 'admin-test@example.com');
insert into core.user_roles (user_id, role_id) values ('11111111-1111-1111-1111-111111111111', 'admin');
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111"}';
select core.has_module_access('attendance');
SQL
```

Expected: `t` (admin, no explicit `module_access` row needed).

- [ ] **Step 3: Verify a non-admin with no `module_access` row is denied**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.allowed_signup_emails (email) values ('emp-test@example.com');
insert into auth.users (id, email) values ('22222222-2222-2222-2222-222222222222', 'emp-test@example.com');
insert into core.user_roles (user_id, role_id) values ('22222222-2222-2222-2222-222222222222', 'employee');
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222"}';
select core.has_module_access('attendance');
SQL
```

Expected: `f`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): modules, module_access, has_module_access RLS function"
```

---

### Task 6: Core schema — employees, event_types, employee_events, employee_status_as_of

**Files:**
- Modify: `supabase/migrations/<timestamp>_core_schema.sql`

**Interfaces:**
- Produces: `core.employees(id, user_id, name, color, salary, notes, created_at)`; `core.event_types(id, status_effect, icon_name, color_hex, description)` seeded `joined`/`rehired`/`left`; `core.employee_events(id, employee_id, event_type, event_date, note, created_by, created_at)` with index on `(employee_id, event_date)`; `core.employee_current_status` view; `core.employee_status_as_of(p_employee_id uuid, p_date date) returns text`.

- [ ] **Step 1: Append employees, event_types (seeded), employee_events + index**

```sql
create table core.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  name text not null,
  color integer not null,
  salary numeric,
  notes text,
  created_at timestamptz not null default now()
);

create table core.event_types (
  id text primary key,
  status_effect text check (status_effect in ('active', 'inactive')),
  icon_name text,
  color_hex text,
  description text
);

insert into core.event_types (id, status_effect, icon_name, color_hex, description) values
  ('joined', 'active', 'check', '#4CAF50', 'Employee joined'),
  ('rehired', 'active', 'check', '#4CAF50', 'Employee rehired'),
  ('left', 'inactive', 'close', '#F44336', 'Employee left');

create table core.employee_events (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references core.employees(id) on delete cascade,
  event_type text not null references core.event_types(id),
  event_date date not null,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index employee_events_employee_id_event_date_idx
  on core.employee_events (employee_id, event_date);

create view core.employee_current_status
with (security_invoker = true)
as
select distinct on (ev.employee_id)
  ev.employee_id,
  et.status_effect as status
from core.employee_events ev
join core.event_types et on et.id = ev.event_type
where et.status_effect is not null
order by ev.employee_id, ev.event_date desc, ev.created_at desc;

alter table core.employees enable row level security;
create policy employees_select on core.employees
  for select using (core.is_admin_or_above() or user_id = auth.uid());
create policy employees_write on core.employees
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());

alter table core.event_types enable row level security;
create policy event_types_select on core.event_types
  for select using (auth.role() = 'authenticated');
create policy event_types_insert on core.event_types
  for insert with check (core.is_admin_or_above());
create policy event_types_update on core.event_types
  for update using (core.is_admin_or_above()) with check (core.is_admin_or_above());

alter table core.employee_events enable row level security;
create policy employee_events_select on core.employee_events
  for select using (
    core.is_admin_or_above()
    or exists (select 1 from core.employees e where e.id = employee_id and e.user_id = auth.uid())
  );
create policy employee_events_write on core.employee_events
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());
```

- [ ] **Step 2: Write the `employee_status_as_of` verification query FIRST (it will fail — the function doesn't exist yet)**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.employees (id, name, color) values
  ('33333333-3333-3333-3333-333333333333', 'Ramesh', 4283215696);
insert into core.employee_events (employee_id, event_type, event_date) values
  ('33333333-3333-3333-3333-333333333333', 'joined', '2024-01-10'),
  ('33333333-3333-3333-3333-333333333333', 'left', '2024-03-05'),
  ('33333333-3333-3333-3333-333333333333', 'rehired', '2024-07-01');
select
  core.employee_status_as_of('33333333-3333-3333-3333-333333333333', '2024-02-01') as mid_first_stint,
  core.employee_status_as_of('33333333-3333-3333-3333-333333333333', '2024-03-05') as left_own_date,
  core.employee_status_as_of('33333333-3333-3333-3333-333333333333', '2024-03-06') as day_after_left,
  core.employee_status_as_of('33333333-3333-3333-3333-333333333333', '2024-05-15') as gap,
  core.employee_status_as_of('33333333-3333-3333-3333-333333333333', '2024-07-01') as rehired_own_date;
SQL
```

Run: Expected **FAIL** — `function core.employee_status_as_of(uuid, date) does not exist`.

- [ ] **Step 3: Implement the function**

This is the trickiest logic in the schema — inclusive intervals where `left`'s own date is still active, and only the day after is inactive. Append:

```sql
create or replace function core.employee_status_as_of(p_employee_id uuid, p_date date)
returns text
language sql
stable
as $$
  select case
    when exists (
      select 1
      from core.employee_events ev
      join core.event_types et on et.id = ev.event_type
      where ev.employee_id = p_employee_id
        and et.status_effect = 'active'
        and ev.event_date <= p_date
        and not exists (
          select 1
          from core.employee_events ev2
          join core.event_types et2 on et2.id = ev2.event_type
          where ev2.employee_id = p_employee_id
            and et2.status_effect = 'inactive'
            and ev2.event_date > ev.event_date
            and ev2.event_date < p_date
        )
    ) then 'active'
    else 'inactive'
  end;
$$;
```

- [ ] **Step 4: Re-run Step 2's query — it should now pass with the correct boundary semantics**

```bash
supabase db reset
```

then re-run the exact `psql` block from Step 2.

Expected: `mid_first_stint=active, left_own_date=active, day_after_left=inactive, gap=inactive, rehired_own_date=active`. If `left_own_date` or `rehired_own_date` come back `inactive`, the boundary logic is wrong — re-check the `<` vs `<=` in the inner `not exists` (it must be `ev2.event_date < p_date`, not `<=`, or `left`'s own date incorrectly closes itself out).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): employees, event_types, employee_events, employee_status_as_of"
```

---

### Task 7: Core schema — employee_ledger_entries, employee_timeline

**Files:**
- Modify: `supabase/migrations/<timestamp>_core_schema.sql`

**Interfaces:**
- Produces: `core.employee_ledger_entries(id, employee_id, entry_date, amount, entry_type, note, created_by, created_at)`; `core.employee_timeline` view (`employee_id, entry_date, kind, label, note`).

- [ ] **Step 1: Append the ledger table and the timeline view**

```sql
create table core.employee_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references core.employees(id) on delete cascade,
  entry_date date not null,
  amount numeric not null,
  entry_type text not null,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table core.employee_ledger_entries enable row level security;
create policy employee_ledger_entries_select on core.employee_ledger_entries
  for select using (
    core.is_admin_or_above()
    or exists (select 1 from core.employees e where e.id = employee_id and e.user_id = auth.uid())
  );
create policy employee_ledger_entries_write on core.employee_ledger_entries
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());

create view core.employee_timeline
with (security_invoker = true)
as
select employee_id, event_date as entry_date, 'event'::text as kind, event_type as label, note
from core.employee_events
union all
select employee_id, entry_date, 'ledger'::text as kind, entry_type as label, note
from core.employee_ledger_entries
order by entry_date desc;
```

- [ ] **Step 2: Apply and verify events + ledger entries interleave by date**

```bash
supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into core.employees (id, name, color) values
  ('44444444-4444-4444-4444-444444444444', 'Suresh', 4278238420);
insert into core.employee_events (employee_id, event_type, event_date) values
  ('44444444-4444-4444-4444-444444444444', 'joined', '2024-01-01');
insert into core.employee_ledger_entries (employee_id, entry_date, amount, entry_type) values
  ('44444444-4444-4444-4444-444444444444', '2024-02-01', 5000, 'advance');
select entry_date, kind, label from core.employee_timeline
where employee_id = '44444444-4444-4444-4444-444444444444'
order by entry_date;
SQL
```

Expected: two rows, `2024-01-01 | event | joined` then `2024-02-01 | ledger | advance`.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/
git commit -m "feat(db): employee_ledger_entries, employee_timeline view"
```

---

### Task 8: RLS smoke test as a non-admin

**Files:** none (verification only — this is the Verification section's "RLS checks" item for Phase 1).

**Interfaces:** none produced; consumes every table/function from Tasks 3–7.

- [ ] **Step 1: Confirm a plain `employee`-role user cannot write to `core.employees`**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222"}';
insert into core.employees (name, color) values ('Should Fail', 0);
SQL
```

Expected: **FAILS** with a row-level security policy violation (that user has role `employee`, seeded in Task 5's Step 3, no admin/superadmin).

- [ ] **Step 2: Confirm the same user cannot write to `core.user_roles`**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222"}';
insert into core.user_roles (user_id, role_id) values ('22222222-2222-2222-2222-222222222222', 'superadmin');
SQL
```

Expected: **FAILS** — this is the direct fix for the old app's self-escalation bug; even attempting to self-grant `superadmin` must be rejected.

- [ ] **Step 3: No commit** — this task only verifies existing migrations; nothing changes.

---

### Task 9: Bootstrap runbook — finish and execute

**Files:**
- Modify: `supabase/README.md`

**Interfaces:** none produced; this is the manual, one-time, real-world execution of the bootstrap.

- [ ] **Step 1: Finish the runbook file**

```markdown
## Bootstrap (one-time, manual — run against the HOSTED project, in this exact order)

1. In the Supabase SQL editor, before either of you has ever signed in:

   \`\`\`sql
   insert into core.allowed_signup_emails (email, note) values
     ('<your-email>', 'you'),
     ('<dads-email>', 'dad');
   \`\`\`

2. You and your dad each sign in once via the app (now permitted by the allow-list).

3. Still as you, in the SQL editor, grant roles:

   \`\`\`sql
   insert into core.user_roles (user_id, role_id, granted_by)
     select id, 'superadmin', id from auth.users where email = '<your-email>';
   insert into core.user_roles (user_id, role_id, granted_by)
     select u.id, 'admin', (select id from auth.users where email = '<your-email>')
     from auth.users u where u.email = '<dads-email>';
   \`\`\`

This cannot be done from the app itself — no superadmin is logged in yet to use an
in-app console. A "manage roles"/"manage allow-list" screen exists from Phase 6 onward
for every grant *after* this one-time step.
```

- [ ] **Step 2: Execute it against the hosted project** — this genuinely cannot happen until Task 16 (sign-in) and Task 1's hosted-project Google OAuth setup both work end-to-end, so mark this step as "run once Task 19 is done" and revisit it then. Note this explicitly in the file so it isn't forgotten:

```markdown
**Status:** not yet executed — requires the sign-in screen (Task 19) to exist first, so
you and your dad have something to sign in with. Revisit after Task 19.
```

- [ ] **Step 3: Commit**

```bash
git add supabase/README.md
git commit -m "docs: finish bootstrap runbook"
```

---

### Task 10: Logging — `talker` setup with file persistence

**Files:**
- Create: `lib/core/logging/app_talker.dart`

**Interfaces:**
- Produces: a top-level `final talker = TalkerFlutter.init(...)` instance (importable as `appTalker`), configured to persist to a local file.

- [ ] **Step 1: Write the talker setup**

```dart
// lib/core/logging/app_talker.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

late final Talker appTalker;

Future<void> initAppTalker() async {
  final dir = await getApplicationSupportDirectory();
  final logFile = File('${dir.path}/crs_ops.log');

  appTalker = TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: true,
    ),
  );

  appTalker.stream.listen((event) {
    logFile.writeAsStringSync(
      '${DateTime.now().toIso8601String()} ${event.title}: ${event.message}\n',
      mode: FileMode.append,
    );
  });
}
```

- [ ] **Step 2: Call it from `main.dart` before `runApp`** (full `main.dart` wiring happens in Task 21 — for now just confirm it compiles):

```bash
dart analyze lib/core/logging/app_talker.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/logging/app_talker.dart
git commit -m "feat: talker logging with file persistence"
```

---

### Task 11: `core/errors/` — `AppException` + translator

**Files:**
- Create: `lib/core/errors/app_exception.dart`
- Create: `lib/core/errors/exception_translator.dart`
- Test: `test/core/errors/exception_translator_test.dart`

**Interfaces:**
- Produces: `sealed class AppException` with subtypes `NetworkException`, `AuthFailureException`, `DataException`, `UnknownException` (each has a `String message`); `AppException translateException(Object error)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/errors/exception_translator_test.dart
import 'dart:io';

import 'package:crs_ops/core/errors/app_exception.dart';
import 'package:crs_ops/core/errors/exception_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('translateException', () {
    test('SocketException becomes NetworkException', () {
      final result = translateException(const SocketException('failed'));
      expect(result, isA<NetworkException>());
    });

    test('AuthException becomes AuthFailureException with the original message', () {
      final result = translateException(AuthException('invalid credentials'));
      expect(result, isA<AuthFailureException>());
      expect(result.message, 'invalid credentials');
    });

    test('PostgrestException becomes DataException with the original message', () {
      final result = translateException(
        PostgrestException(message: 'row-level security violation'),
      );
      expect(result, isA<DataException>());
      expect(result.message, 'row-level security violation');
    });

    test('an already-translated AppException passes through unchanged', () {
      const original = NetworkException();
      expect(translateException(original), same(original));
    });

    test('anything else becomes a generic UnknownException', () {
      final result = translateException(Exception('boom'));
      expect(result, isA<UnknownException>());
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/errors/exception_translator_test.dart
```

Expected: FAIL — `app_exception.dart`/`exception_translator.dart` don't exist yet.

- [ ] **Step 3: Write `AppException`**

```dart
// lib/core/errors/app_exception.dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException()
      : super('No internet connection. Check your connection and try again.');
}

final class AuthFailureException extends AppException {
  const AuthFailureException(super.message);
}

final class DataException extends AppException {
  const DataException(super.message);
}

final class UnknownException extends AppException {
  const UnknownException() : super('Something went wrong. Please try again.');
}
```

- [ ] **Step 4: Write the translator**

```dart
// lib/core/errors/exception_translator.dart
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

AppException translateException(Object error) {
  if (error is AppException) return error;
  if (error is SocketException) return const NetworkException();
  if (error is AuthException) return AuthFailureException(error.message);
  if (error is PostgrestException) return DataException(error.message);
  return const UnknownException();
}
```

- [ ] **Step 5: Run the tests again**

```bash
flutter test test/core/errors/exception_translator_test.dart
```

Expected: PASS, 5/5.

- [ ] **Step 6: Commit**

```bash
git add lib/core/errors/ test/core/errors/
git commit -m "feat: AppException hierarchy and exception translator"
```

---

### Task 12: Connectivity — offline detection + full-screen state

**Files:**
- Create: `lib/core/connectivity/connectivity_provider.dart`
- Create: `lib/core/widgets/offline_screen.dart`

**Interfaces:**
- Produces: `@riverpod Stream<bool> isOnline(Ref ref)` → `isOnlineProvider` (emits `true`/`false`); `class OfflineScreen extends StatelessWidget` (takes an `onRetry` callback).

- [ ] **Step 1: Write the connectivity provider**

```dart
// lib/core/connectivity/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<bool> isOnline(Ref ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none),
      );
}
```

- [ ] **Step 2: Write the offline screen**

```dart
// lib/core/widgets/offline_screen.dart
import 'package:flutter/material.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No internet connection', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Generate the riverpod code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/connectivity/ lib/core/widgets/offline_screen.dart
```

Expected: `connectivity_provider.g.dart` generated, no analyzer errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/connectivity/ lib/core/widgets/offline_screen.dart
git commit -m "feat: connectivity detection and offline full-screen state"
```

---

### Task 13: `AppSession` model

**Files:**
- Create: `lib/core/auth/models/app_session.dart`
- Test: `test/core/auth/models/app_session_test.dart`

**Interfaces:**
- Produces: `enum AppRole { superadmin, admin, employee }`; `class AppSession` with fields `String userId`, `String email`, `AppRole? role`, `Set<String> moduleAccess`, and getters `bool get isSuperadmin`, `bool get isAdminOrAbove`, `bool hasModuleAccess(String moduleId)`. Every later phase's router/nav code depends on these exact names.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/auth/models/app_session_test.dart
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSession', () {
    test('isAdminOrAbove is true for admin and superadmin, false otherwise', () {
      const admin = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      const superadmin = AppSession(userId: 'u2', email: 'b@x.com', role: AppRole.superadmin, moduleAccess: {});
      const employee = AppSession(userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {});
      const noRole = AppSession(userId: 'u4', email: 'd@x.com', role: null, moduleAccess: {});

      expect(admin.isAdminOrAbove, isTrue);
      expect(superadmin.isAdminOrAbove, isTrue);
      expect(employee.isAdminOrAbove, isFalse);
      expect(noRole.isAdminOrAbove, isFalse);
    });

    test('admin-or-above has module access regardless of moduleAccess set', () {
      const admin = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      expect(admin.hasModuleAccess('attendance'), isTrue);
    });

    test('employee has module access only if explicitly granted', () {
      const withAccess = AppSession(
        userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {'attendance'},
      );
      const withoutAccess = AppSession(userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {});

      expect(withAccess.hasModuleAccess('attendance'), isTrue);
      expect(withoutAccess.hasModuleAccess('attendance'), isFalse);
    });

    test('round-trips through JSON', () {
      const session = AppSession(
        userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {'attendance'},
      );
      final json = session.toMap();
      final decoded = AppSessionMapper.fromMap(json);
      expect(decoded, session);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/auth/models/app_session_test.dart
```

Expected: FAIL — `app_session.dart` doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/auth/models/app_session.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'app_session.mapper.dart';

@MappableEnum()
enum AppRole { superadmin, admin, employee }

@MappableClass()
class AppSession with AppSessionMappable {
  const AppSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.moduleAccess,
  });

  final String userId;
  final String email;
  final AppRole? role;
  final Set<String> moduleAccess;

  bool get isSuperadmin => role == AppRole.superadmin;
  bool get isAdminOrAbove => role == AppRole.superadmin || role == AppRole.admin;

  bool hasModuleAccess(String moduleId) => isAdminOrAbove || moduleAccess.contains(moduleId);
}
```

- [ ] **Step 4: Generate mapper code and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/auth/models/app_session_test.dart
```

Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/models/ test/core/auth/models/
git commit -m "feat: AppSession model with role/module-access helpers"
```

---

### Task 14: `AuthRepository` and `RolesRepository`

**Files:**
- Create: `lib/core/data/supabase_client_provider.dart`
- Create: `lib/core/auth/repositories/auth_repository.dart`
- Create: `lib/core/auth/repositories/roles_repository.dart`

**Interfaces:**
- Consumes: `AppRole` from Task 13; `translateException` from Task 11.
- Produces: `class AuthRepository` with `Stream<AuthState> get authStateChanges`, `User? get currentUser`, `Future<void> signInWithGoogle()`, `Future<void> signOut()`. `class RolesRepository` with `Future<AppRole?> fetchRole(String userId)`, `Future<Set<String>> fetchModuleAccess(String userId)`.

- [ ] **Step 1: Write the Supabase client provider**

```dart
// lib/core/data/supabase_client_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
```

- [ ] **Step 2: Write `AuthRepository`**

```dart
// lib/core/auth/repositories/auth_repository.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../../errors/exception_translator.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb || Platform.isLinux) {
        await _client.auth.signInWithOAuth(OAuthProvider.google);
      } else if (Platform.isAndroid) {
        await _signInWithGoogleNative();
      } else {
        throw const AuthFailureException('Google sign-in is not supported on this platform yet.');
      }
    } catch (error) {
      throw translateException(error);
    }
  }

  Future<void> _signInWithGoogleNative() async {
    // NOTE: requires the `google_sign_in` package's platform setup (OAuth client IDs
    // in Android's google-services.json) — see Task 19 Step 1's spike.
    throw UnimplementedError(
      'Wire up google_sign_in ID-token flow here in Task 19 once OAuth client IDs exist.',
    );
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

*(The native Android path is intentionally a documented `UnimplementedError` here, not a silent stub — Task 19 replaces its body once the Google Cloud OAuth client ID exists, which Task 1 didn't create. Every other method is fully real.)*

- [ ] **Step 3: Write `RolesRepository`**

```dart
// lib/core/auth/repositories/roles_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/app_session.dart';

class RolesRepository {
  RolesRepository(this._client);
  final SupabaseClient _client;

  Future<AppRole?> fetchRole(String userId) async {
    try {
      final rows = await _client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', userId);
      if (rows.isEmpty) return null;
      // superadmin > admin > employee if somehow more than one row exists
      final roleIds = rows.map((r) => r['role_id'] as String).toSet();
      if (roleIds.contains('superadmin')) return AppRole.superadmin;
      if (roleIds.contains('admin')) return AppRole.admin;
      return AppRole.employee;
    } catch (error) {
      throw translateException(error);
    }
  }

  Future<Set<String>> fetchModuleAccess(String userId) async {
    try {
      final rows = await _client
          .from('module_access')
          .select('module_id')
          .eq('user_id', userId);
      return rows.map((r) => r['module_id'] as String).toSet();
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 4: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/data/ lib/core/auth/repositories/
```

Expected: no errors (the `UnimplementedError` is intentional, not an analyzer error).

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/ lib/core/auth/repositories/
git commit -m "feat: AuthRepository and RolesRepository over Supabase"
```

---

### Task 15: Auth/session providers

**Files:**
- Create: `lib/core/auth/providers/auth_providers.dart`

**Interfaces:**
- Consumes: `supabaseClientProvider` (Task 14), `AuthRepository`/`RolesRepository` (Task 14), `AppSession`/`AppRole` (Task 13).
- Produces: `authRepositoryProvider`, `rolesRepositoryProvider`, `authStateChangesProvider` (`Stream<AuthState>`), `sessionProvider` (`AsyncValue<AppSession?>` — `null` means signed out). **Every later phase reads session state via `ref.watch(sessionProvider)`.**

- [ ] **Step 1: Write the providers**

```dart
// lib/core/auth/providers/auth_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_client_provider.dart';
import '../models/app_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/roles_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
RolesRepository rolesRepository(Ref ref) => RolesRepository(ref.watch(supabaseClientProvider));

@riverpod
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

@riverpod
Future<AppSession?> session(Ref ref) async {
  final authState = await ref.watch(authStateChangesProvider.future);
  final user = authState.session?.user;
  if (user == null) return null;

  final rolesRepo = ref.watch(rolesRepositoryProvider);
  final role = await rolesRepo.fetchRole(user.id);
  final moduleAccess = await rolesRepo.fetchModuleAccess(user.id);

  return AppSession(
    userId: user.id,
    email: user.email ?? '',
    role: role,
    moduleAccess: moduleAccess,
  );
}
```

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/auth/providers/
```

Expected: no errors. This can't be meaningfully unit-tested without a live/mocked Supabase client — that coverage comes from Task 16's redirect-logic tests (which take a plain `AppSession?`, not a live provider) and Task 22's manual end-to-end pass.

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/providers/
git commit -m "feat: authStateChanges and session Riverpod providers"
```

---

### Task 16: Redirect logic (pure function)

**Files:**
- Create: `lib/core/router/redirect_logic.dart`
- Test: `test/core/router/redirect_logic_test.dart`

**Interfaces:**
- Consumes: `AppSession`/`AppRole` (Task 13).
- Produces: `String? computeRedirect({required AsyncValue<AppSession?> sessionValue, required String currentLocation})`. Returns `null` (no redirect needed) or a path (`'/sign-in'`, `'/unauthorized'`, `'/loading'`). Task 17's router calls this directly.

- [ ] **Step 1: Write the failing tests**

```dart
// test/core/router/redirect_logic_test.dart
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/router/redirect_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRedirect', () {
    test('loading session redirects to /loading from any other route', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/',
      );
      expect(result, '/loading');
    });

    test('loading session does not redirect if already on /loading', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/loading',
      );
      expect(result, isNull);
    });

    test('signed out (null session) redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/',
      );
      expect(result, '/sign-in');
    });

    test('signed out already on /sign-in does not redirect', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/sign-in',
      );
      expect(result, isNull);
    });

    test('signed in with no role redirects to /unauthorized', () {
      const session = AppSession(userId: 'u1', email: 'a@x.com', role: null, moduleAccess: {});
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/',
      );
      expect(result, '/unauthorized');
    });

    test('signed in with a role on /sign-in redirects to /', () {
      const session = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/sign-in',
      );
      expect(result, '/');
    });

    test('signed in with a role on an app route does not redirect', () {
      const session = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/',
      );
      expect(result, isNull);
    });

    test('error session redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: AsyncError('boom', StackTrace.empty),
        currentLocation: '/',
      );
      expect(result, '/sign-in');
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/router/redirect_logic_test.dart
```

Expected: FAIL — `redirect_logic.dart` doesn't exist.

- [ ] **Step 3: Implement it**

```dart
// lib/core/router/redirect_logic.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/models/app_session.dart';

const signInPath = '/sign-in';
const unauthorizedPath = '/unauthorized';
const loadingPath = '/loading';

String? computeRedirect({
  required AsyncValue<AppSession?> sessionValue,
  required String currentLocation,
}) {
  if (sessionValue.isLoading) {
    return currentLocation == loadingPath ? null : loadingPath;
  }

  if (sessionValue.hasError) {
    return currentLocation == signInPath ? null : signInPath;
  }

  final session = sessionValue.value;

  if (session == null) {
    return currentLocation == signInPath ? null : signInPath;
  }

  if (session.role == null) {
    return currentLocation == unauthorizedPath ? null : unauthorizedPath;
  }

  if (currentLocation == signInPath ||
      currentLocation == unauthorizedPath ||
      currentLocation == loadingPath) {
    return '/';
  }

  return null;
}
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/core/router/redirect_logic_test.dart
```

Expected: PASS, 8/8.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/redirect_logic.dart test/core/router/
git commit -m "feat: pure redirect logic, tested without a live GoRouter"
```

---

### Task 17: Adaptive nav scaffold

**Files:**
- Create: `lib/core/widgets/adaptive_nav_scaffold.dart`
- Test: `test/core/widgets/adaptive_nav_scaffold_test.dart`

**Interfaces:**
- Produces: `class AdaptiveNavScaffold extends StatelessWidget` — constructor `({required List<NavigationDestination> destinations, required int selectedIndex, required ValueChanged<int> onDestinationSelected, required Widget child})`; `static const double compactBreakpoint = 600`. Later phases pass their module-derived destination list into this exact constructor.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/core/widgets/adaptive_nav_scaffold_test.dart
import 'package:crs_ops/core/widgets/adaptive_nav_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestable(Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: AdaptiveNavScaffold(
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.people), label: 'Employees'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const Text('body'),
        ),
      ),
    );
  }

  testWidgets('shows a bottom NavigationBar below the compact breakpoint', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(400, 800)));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows a NavigationRail at/above the compact breakpoint', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(800, 600)));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/widgets/adaptive_nav_scaffold_test.dart
```

Expected: FAIL — the widget doesn't exist.

- [ ] **Step 3: Implement it**

```dart
// lib/core/widgets/adaptive_nav_scaffold.dart
import 'package:flutter/material.dart';

class AdaptiveNavScaffold extends StatelessWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  static const double compactBreakpoint = 600;

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < compactBreakpoint;

    if (isCompact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map((d) => NavigationRailDestination(icon: d.icon, label: Text(d.label)))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/core/widgets/adaptive_nav_scaffold_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/adaptive_nav_scaffold.dart test/core/widgets/
git commit -m "feat: hand-rolled adaptive nav shell (bottom bar / rail at 600dp)"
```

---

### Task 18: Theme

**Files:**
- Create: `lib/core/theme/app_theme.dart`

**Interfaces:**
- Produces: `ThemeData buildAppTheme({required Brightness brightness})`.

- [ ] **Step 1: Write the theme**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5),
      brightness: brightness,
    ),
  );
}
```

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/core/theme/app_theme.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: Material 3 seed-color theme"
```

---

### Task 19: Sign-in, unauthorized, loading pages

**Files:**
- Create: `lib/core/auth/pages/sign_in_page.dart`
- Create: `lib/core/auth/pages/unauthorized_page.dart`
- Create: `lib/core/auth/pages/loading_page.dart`
- Modify: `lib/core/auth/repositories/auth_repository.dart` (replace the `UnimplementedError` from Task 14)

**Interfaces:**
- Consumes: `authRepositoryProvider` (Task 15), `AppException` (Task 11).
- Produces: `SignInPage`, `UnauthorizedPage`, `LoadingPage` widgets — Task 20's router routes to these by name.

- [ ] **Step 1: Spike the native Google sign-in ID-token flow on Android**

Add the Android OAuth client ID from Task 1 Step 4 to `android/app/google-services.json` (download it from the Google Cloud Console credentials page for the Android client). Confirm `google_sign_in`'s `GoogleSignIn().signIn()` returns a non-null `GoogleSignInAuthentication.idToken` when run with `flutter run -d <android-device>` against a throwaway test button — do this **before** wiring the full sign-in screen around it, since a wrong SHA-1 fingerprint/package name in the OAuth client silently returns `idToken: null` and is much easier to debug in isolation.

- [ ] **Step 2: Replace the `UnimplementedError` in `AuthRepository`**

```dart
// lib/core/auth/repositories/auth_repository.dart — replace _signInWithGoogleNative's body
Future<void> _signInWithGoogleNative() async {
  final googleSignIn = GoogleSignIn(scopes: ['email']);
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw const AuthFailureException('Sign-in cancelled.');
  }
  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  if (idToken == null) {
    throw const AuthFailureException('Google sign-in did not return an ID token.');
  }
  await _client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: googleAuth.accessToken,
  );
}
```

Add the import: `import 'package:google_sign_in/google_sign_in.dart';`

- [ ] **Step 3: Write the sign-in page**

```dart
// lib/core/auth/pages/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_exception.dart';
import '../providers/auth_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('CRS Ops', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Attendance, made simple.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

*(`Icons.g_mobiledata` is a placeholder Material icon standing in for a proper Google "G" logo asset — replace with the official multi-color Google "G" SVG during the Phase 7 UI polish pass, per the plan's UI-quality-bar note; functionally the button works today.)*

- [ ] **Step 4: Write the unauthorized and loading pages**

```dart
// lib/core/auth/pages/unauthorized_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class UnauthorizedPage extends ConsumerWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('No access yet'),
            const SizedBox(height: 8),
            const Text('Ask an admin to grant you a role.'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/core/auth/pages/loading_page.dart
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
```

- [ ] **Step 5: Verify it compiles**

```bash
dart analyze lib/core/auth/pages/ lib/core/auth/repositories/
```

Expected: no errors.

- [ ] **Step 6: Execute the bootstrap runbook (Task 9) now that sign-in works**

Follow `supabase/README.md`'s three steps against the hosted project. Update its "Status" line to "executed on \<date\>".

- [ ] **Step 7: Commit**

```bash
git add lib/core/auth/pages/ lib/core/auth/repositories/ supabase/README.md
git commit -m "feat: sign-in, unauthorized, and loading pages; execute bootstrap"
```

---

### Task 20: Router wiring

**Files:**
- Create: `lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: `computeRedirect`/path constants (Task 16), `sessionProvider` (Task 15), `SignInPage`/`UnauthorizedPage`/`LoadingPage` (Task 19), `AdaptiveNavScaffold` (Task 17).
- Produces: `appRouterProvider` (`GoRouter`). Later phases add their own `GoRoute`s to this file's route list and their own nav destination to the placeholder shell.

- [ ] **Step 1: Write the router**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/pages/loading_page.dart';
import '../auth/pages/sign_in_page.dart';
import '../auth/pages/unauthorized_page.dart';
import '../auth/providers/auth_providers.dart';
import '../widgets/adaptive_nav_scaffold.dart';
import 'redirect_logic.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: loadingPath,
    redirect: (context, state) {
      final sessionValue = ref.read(sessionProvider);
      return computeRedirect(sessionValue: sessionValue, currentLocation: state.matchedLocation);
    },
    refreshListenable: GoRouterRefreshStream(ref.watch(sessionProvider.notifier).stream),
    routes: [
      GoRoute(path: loadingPath, builder: (context, state) => const LoadingPage()),
      GoRoute(path: signInPath, builder: (context, state) => const SignInPage()),
      GoRoute(path: unauthorizedPath, builder: (context, state) => const UnauthorizedPage()),
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHomeShell(),
      ),
    ],
  );
}

/// Real module branches (Calendar, Employees, Settings) replace this in Phases 2-3.
/// This proves the adaptive nav shell + sign-out flow end to end for Phase 1.
class _PlaceholderHomeShell extends ConsumerWidget {
  const _PlaceholderHomeShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    return AdaptiveNavScaffold(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${session?.email ?? ''}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bridges a Riverpod stream to GoRouter's Listenable-based refresh API.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

Add the missing imports: `import 'dart:async';`, `import 'package:flutter_riverpod/flutter_riverpod.dart';`.

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/router/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat: GoRouter wired to session state via redirect logic"
```

---

### Task 21: App shell wiring (`main.dart`, `app.dart`, bootstrap)

**Files:**
- Create: `lib/bootstrap/supabase_bootstrap.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `appRouterProvider` (Task 20), `buildAppTheme` (Task 18), `initAppTalker`/`appTalker` (Task 10), `isOnlineProvider`/`OfflineScreen` (Task 12).
- Produces: a runnable app.

- [ ] **Step 1: Write the bootstrap**

```dart
// lib/bootstrap/supabase_bootstrap.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
```

- [ ] **Step 2: Write `app.dart`, including the offline full-screen wrapper**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/connectivity/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final router = ref.watch(appRouterProvider);

    if (!isOnline) {
      return MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light),
        home: OfflineScreen(onRetry: () => ref.invalidate(isOnlineProvider)),
      );
    }

    return MaterialApp.router(
      routerConfig: router,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
    );
  }
}
```

- [ ] **Step 3: Rewrite `main.dart`**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/supabase_bootstrap.dart';
import 'core/logging/app_talker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAppTalker();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 4: Run on two platforms**

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
flutter run -d linux --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Expected: app launches to the loading page, then the sign-in page (no session yet).

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/app.dart lib/bootstrap/
git commit -m "feat: wire bootstrap, router, theme, and offline state into main.dart"
```

---

### Task 22: End-to-end manual verification

**Files:** none — this is the phase's full Verification pass.

**Interfaces:** none produced; exercises everything from Tasks 1–21.

- [ ] **Step 1: Sign-in rejected for a non-allow-listed email**

On `-d chrome`, attempt Google sign-in with an email not in `core.allowed_signup_emails`. Expected: sign-in fails; the `SignInPage`'s `SnackBar` shows a message (not a raw exception/crash).

- [ ] **Step 2: Sign-in works for allow-listed accounts on two platforms**

Sign in with your own (allow-listed) email on `-d chrome` and `-d linux`. Expected: reaches the placeholder home shell showing "Signed in as \<your-email\>".

- [ ] **Step 3: `core.profiles` auto-populated**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "select email from core.profiles;"
```

Expected: your email is present (run against whichever DB you actually signed in against — hosted, if Task 19's bootstrap ran against hosted).

- [ ] **Step 4: No-role user bounced to unauthorized**

Grant yourself no role yet (fresh allow-listed account, no `core.user_roles` row), sign in. Expected: redirected to `/unauthorized`, not the home shell.

- [ ] **Step 5: Nav shell breakpoint**

Resize the Chrome window across 600dp. Expected: switches between `NavigationBar` (bottom) and `NavigationRail` (side) live, matching Task 17's widget test.

- [ ] **Step 6: RLS re-confirmed against the hosted project**

Re-run Task 8's two `psql` blocks against the **hosted** project's connection string (not local), substituting a real non-admin test account's UID. Expected: same rejections as local.

- [ ] **Step 7: No commit** — this is a verification pass; if anything fails, fix it in the task that owns the broken piece and re-run this task from Step 1.

---

## Self-Review

**Spec coverage:** every `core` schema object, RLS function, and RLS policy from plan.md's `core` schema section is in Tasks 3–8; the signup-allow-list gap and bootstrap-ordering fix are in Tasks 3 and 9; the `employee_events` index and `STABLE` markings are in Tasks 4–6; Riverpod/`dart_mappable`/`go_router` architecture, the adaptive nav shell, `talker` w/ file persistence, `core/errors/`, offline handling, and the redesigned sign-in screen are in Tasks 10–21; the Phase 1 Verify bullet from plan.md's Build order is Task 22.

**Placeholder scan:** the only non-final code is `AuthRepository._signInWithGoogleNative`'s `UnimplementedError` between Tasks 14 and 19 — intentional and resolved within this same plan (Task 19 Step 2), not left dangling; the Google "G" icon is a real, working icon standing in for brand artwork, called out explicitly rather than silently left generic.

**Type/name consistency:** `AppSession`/`AppRole` (Task 13) are used with identical field names in Tasks 15, 16, 19, 20. `sessionProvider`, `authRepositoryProvider`, `rolesRepositoryProvider`, `authStateChangesProvider` (Task 15) are referenced by those exact generated names in Tasks 16, 19, 20. `computeRedirect`/`signInPath`/`unauthorizedPath`/`loadingPath` (Task 16) match their usage in Task 20. `AdaptiveNavScaffold`'s constructor (Task 17) matches its usage in Task 20. `translateException`/`AppException` subtypes (Task 11) match their usage in Tasks 14 and 19.

---

**Plan complete and saved to `docs/superpowers/plans/2026-09-20-phase1-foundation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
