-- core: employees and their history (joining, leaving, payments). Shared by
-- every module; attendance reads it.

create table core.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  name text not null,
  -- A Flutter Color.value: opaque colours like 0xFF4CAF50 overflow a 32-bit integer.
  color bigint not null,
  -- Whole rupees. (Payments in employee_ledger_entries can have paise.)
  salary integer,
  notes text,
  created_at timestamptz not null default now()
);

-- What can happen to an employee. Rows with a status_effect ('joined',
-- 'rehired', 'left') are seeded by a migration and drive who is active.
create table core.event_types (
  id text primary key,
  status_effect text check (status_effect in ('active', 'inactive')),
  icon_name text,
  color_hex text,
  description text
);

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

-- ── Views ──────────────────────────────────────────────────────────────────

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

-- Events and payments in one list. amount is null for events.
create view core.employee_timeline
with (security_invoker = true)
as
select id, employee_id, event_date as entry_date, 'event'::text as kind, event_type as label, note, null::numeric as amount
from core.employee_events
union all
select id, employee_id, entry_date, 'ledger'::text as kind, entry_type as label, note, amount
from core.employee_ledger_entries
order by entry_date desc;

-- ── Functions ──────────────────────────────────────────────────────────────

-- Active on a day if some 'active' event is on or before it and no 'inactive'
-- event falls strictly between that event and the day: someone who leaves on
-- a day is still active on it. attendance.effective_range_status keeps the
-- same rule.
create function core.employee_status_as_of(p_employee_id uuid, p_date date)
returns text
language sql
stable
set search_path = ''
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

-- Adds an employee and their "joined" event in one step, so a failure can't
-- leave an employee with no history. Runs as the signed-in user: the tables'
-- row-level security decides whether they may.
create function core.create_employee(
  p_name text,
  p_color integer,
  p_salary integer,
  p_notes text,
  p_joined_on date
)
returns core.employees
language plpgsql
-- Runs as the signed-in user, so the existing RLS policies on employees and
-- employee_events still decide whether they're allowed to do this.
security invoker
set search_path = ''
as $$
declare
  new_employee core.employees;
begin
  insert into core.employees (name, color, salary, notes)
  values (p_name, p_color, p_salary, p_notes)
  returning * into new_employee;

  insert into core.employee_events (employee_id, event_type, event_date, created_by)
  values (new_employee.id, 'joined', p_joined_on, auth.uid());

  return new_employee;
end;
$$;

revoke execute on function core.create_employee(text, integer, integer, text, date) from public, anon;
grant execute on function core.create_employee(text, integer, integer, text, date) to authenticated;

-- ── Row-level security ─────────────────────────────────────────────────────
-- Helpers are wrapped as (select …) so Postgres works them out once per query,
-- not once per row (Supabase's RLS performance advice).

alter table core.employees enable row level security;
create policy employees_select on core.employees
  for select using (
    (select core.is_admin_or_above()) or user_id = (select auth.uid())
  );
create policy employees_write on core.employees
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));
grant insert, update, delete on core.employees to authenticated;

-- Structural types (with a status_effect) are superadmin-only; admins may add
-- descriptive ones.
alter table core.event_types enable row level security;
create policy event_types_select on core.event_types
  for select using ((select auth.role()) = 'authenticated');
create policy event_types_insert on core.event_types
  for insert with check (
    core.is_superadmin() or (core.is_admin_or_above() and status_effect is null)
  );
create policy event_types_update on core.event_types
  for update using (core.is_superadmin()) with check (core.is_superadmin());
grant insert, update on core.event_types to authenticated;

alter table core.employee_events enable row level security;
create policy employee_events_select on core.employee_events
  for select using (
    (select core.is_admin_or_above())
    or exists (
      select 1 from core.employees e
      where e.id = employee_id and e.user_id = (select auth.uid())
    )
  );
create policy employee_events_write on core.employee_events
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));
grant insert, update, delete on core.employee_events to authenticated;

alter table core.employee_ledger_entries enable row level security;
create policy employee_ledger_entries_select on core.employee_ledger_entries
  for select using (
    core.is_admin_or_above()
    or exists (select 1 from core.employees e where e.id = employee_id and e.user_id = auth.uid())
  );
create policy employee_ledger_entries_write on core.employee_ledger_entries
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());
grant insert, update, delete on core.employee_ledger_entries to authenticated;
