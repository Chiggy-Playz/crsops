-- CRS Ops — core schema (Phase 1)
-- Auth/roles/employees foundation. attendance.* is Phase 3, not touched here.

create schema if not exists core;

-- ── Signup allow-list + profiles (Task 3) ──────────────────────────────────

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

-- ── Roles, user_roles, RLS security-definer functions (Task 4) ─────────────

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

-- ── Modules, module_access, has_module_access (Task 5) ─────────────────────

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

-- ── Employees, event_types, employee_events, employee_status_as_of (Task 6) ─

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

-- ── employee_ledger_entries, employee_timeline (Task 7) ────────────────────

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
