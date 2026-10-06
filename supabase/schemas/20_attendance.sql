-- Attendance: each employee's day (two halves, times in and out), the shift
-- rules in force, and the functions the calendar, day page and reports read.

create schema if not exists attendance;

-- Row-level security decides which rows; these grants are the baseline it
-- narrows. By default signed-in users can read every table created here and
-- call every function; writing a table is granted next to its write policy.
grant usage on schema attendance to authenticated;
alter default privileges in schema attendance grant select on tables to authenticated;
alter default privileges in schema attendance grant execute on functions to authenticated;

-- ── Tables ─────────────────────────────────────────────────────────────────

-- Shift hours and week-offs, from a date on. Every lookup takes the row with
-- the latest effective_from on or before the day in question. Append-only: a
-- change adds a row, never edits one (there's no update or delete policy).
-- A migration seeds the first row at 2000-01-01, so imported history is covered.
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

-- Present, absent, leave, … (seeded by a migration; admins can add more).
create table attendance.status_types (
  id text primary key,
  label text not null,
  icon_name text,
  color_hex text,
  description text
);

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

-- ── Functions ──────────────────────────────────────────────────────────────
-- Security invoker (the default), so the tables' row-level security applies.
-- search_path is pinned so names can't resolve through a caller's path. That
-- stops Postgres inlining them; measured cost ~5ms -> ~9ms a month. Accepted.

-- Every day each employee was employed in [p_start, p_end], with what was
-- marked that day (if anything) and whether it's a week-off.
--
-- Same status rule as core.employee_status_as_of: active on day d if some
-- 'active' event is on or before d and no 'inactive' event falls strictly
-- between that event and d, i.e. a stint runs from its active event through
-- the next inactive event's date, inclusive (someone who leaves on d is still
-- active on d). Worked out per stint rather than per employee per day, which
-- took ~350 ms a month before.
create function attendance.effective_range_status(
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
set search_path = ''
as $$
  with stints as (
    -- One row per 'active' event: when the stint starts, and the date of the
    -- first 'inactive' event after it (null = still active).
    select
      ev.employee_id,
      ev.event_date as active_from,
      (
        select min(ev2.event_date)
        from core.employee_events ev2
        join core.event_types et2 on et2.id = ev2.event_type
        where ev2.employee_id = ev.employee_id
          and et2.status_effect = 'inactive'
          and ev2.event_date > ev.event_date
      ) as active_until
    from core.employee_events ev
    join core.event_types et on et.id = ev.event_type
    where et.status_effect = 'active'
      and ev.event_date <= p_end
      and (p_employee_id is null or ev.employee_id = p_employee_id)
  ),
  days as (
    -- The week-off rule in force on each day: one lookup per day, not per
    -- employee per day.
    select gs.d::date as d, sd.week_off_days
    from generate_series(p_start, p_end, '1 day'::interval) as gs(d)
    cross join lateral (
      select w.week_off_days
      from attendance.shift_defaults w
      where w.effective_from <= gs.d::date
      order by w.effective_from desc
      limit 1
    ) sd
  ),
  active_days as (
    select distinct e.id as employee_id, days.d, days.week_off_days
    from core.employees e
    join stints s on s.employee_id = e.id
    join days
      on days.d >= s.active_from
     and (s.active_until is null or days.d <= s.active_until)
    where (p_employee_id is null or e.id = p_employee_id)
  )
  select
    a.employee_id,
    a.d,
    ad.first_half_status,
    ad.second_half_status,
    (ad.id is not null),
    (extract(isodow from a.d)::smallint = any(a.week_off_days)),
    ad.time_in,
    ad.time_out,
    ad.note
  from active_days a
  left join attendance.attendance_days ad
    on ad.employee_id = a.employee_id
   and ad.date = a.d
   and ad.date between p_start and p_end;
$$;

-- Working days in the last p_window_days (not today) that nobody marked.
create function attendance.recent_gaps(p_window_days integer default 7)
returns table (employee_id uuid, date date)
language sql
stable
set search_path = ''
as $$
  select r.employee_id, r.date
  from attendance.effective_range_status(
    ((now() at time zone 'Asia/Kolkata')::date - p_window_days),
    ((now() at time zone 'Asia/Kolkata')::date - 1)
  ) r
  where not r.is_explicit and not r.is_week_off;
$$;

-- Minutes worked, late, early and overtime for days with a time entered.
create function attendance.derived_flags(
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
set search_path = ''
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
        then effective_time_out::interval + interval '24 hours'
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

-- ── Row-level security ─────────────────────────────────────────────────────
-- Reading needs the attendance module; staff see only their own days. Writing
-- is admin-only (admins have every module). Helpers are wrapped as (select …)
-- so they're worked out once per query, not per row.

alter table attendance.shift_defaults enable row level security;
create policy shift_defaults_select on attendance.shift_defaults
  for select using ((select core.has_module_access('attendance')));
create policy shift_defaults_insert on attendance.shift_defaults
  for insert with check (core.is_admin_or_above());
grant insert on attendance.shift_defaults to authenticated;

alter table attendance.status_types enable row level security;
create policy status_types_select on attendance.status_types
  for select using ((select core.has_module_access('attendance')));
create policy status_types_insert on attendance.status_types
  for insert with check (core.is_admin_or_above());
create policy status_types_update on attendance.status_types
  for update using (core.is_admin_or_above()) with check (core.is_admin_or_above());
grant insert, update on attendance.status_types to authenticated;

alter table attendance.attendance_days enable row level security;
create policy attendance_days_select on attendance.attendance_days
  for select using (
    (select core.has_module_access('attendance'))
    and (
      (select core.is_admin_or_above())
      or exists (
        select 1 from core.employees e
        where e.id = employee_id and e.user_id = (select auth.uid())
      )
    )
  );
create policy attendance_days_write on attendance.attendance_days
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));
grant insert, update, delete on attendance.attendance_days to authenticated;
