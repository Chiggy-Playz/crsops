-- Speed up attendance.effective_range_status (the calendar / day page / reports
-- query). Measured on 2026-10-05 for one 30-day month, 16 employees: ~350 ms
-- in the database, growing as history grows. Three causes, three fixes:
--
-- 1. core.employee_status_as_of(employee, day) ran once per employee × day
--    (480 subqueries for one month). Instead, each employee's active stints are
--    worked out once from their events, and days are matched against them.
-- 2. attendance_days was joined by employee only, then filtered by date —
--    reading every day of history (1,687 rows, 33,721 discarded combinations
--    for one month). Now bounded to [p_start, p_end] so the (employee_id, date)
--    index is used as a range.
-- 3. RLS helper calls (core.is_admin_or_above(), auth.uid(), …) were evaluated
--    per row. Wrapping them as (select …) lets Postgres evaluate each once per
--    query (Supabase's documented RLS performance pattern). Policy meaning is
--    unchanged.
--
-- Same signature, same result rows. Status rule preserved exactly from
-- core.employee_status_as_of: active on day d if some 'active' event is on or
-- before d and no 'inactive' event falls strictly between that event and d —
-- i.e. a stint runs from its active event through the next inactive event's
-- date, inclusive (someone who leaves on d is still active on d).

-- ── 1 + 2: the function ──────────────────────────────────────────────────────

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

-- ── 3: evaluate RLS helpers once per query ───────────────────────────────────
-- Each policy keeps its exact meaning; only the helper calls are wrapped.

drop policy employees_select on core.employees;
create policy employees_select on core.employees
  for select using (
    (select core.is_admin_or_above()) or user_id = (select auth.uid())
  );

drop policy employees_write on core.employees;
create policy employees_write on core.employees
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));

drop policy event_types_select on core.event_types;
create policy event_types_select on core.event_types
  for select using ((select auth.role()) = 'authenticated');

drop policy employee_events_select on core.employee_events;
create policy employee_events_select on core.employee_events
  for select using (
    (select core.is_admin_or_above())
    or exists (
      select 1 from core.employees e
      where e.id = employee_id and e.user_id = (select auth.uid())
    )
  );

drop policy employee_events_write on core.employee_events;
create policy employee_events_write on core.employee_events
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));

drop policy shift_defaults_select on attendance.shift_defaults;
create policy shift_defaults_select on attendance.shift_defaults
  for select using ((select core.has_module_access('attendance')));

drop policy status_types_select on attendance.status_types;
create policy status_types_select on attendance.status_types
  for select using ((select core.has_module_access('attendance')));

drop policy attendance_days_select on attendance.attendance_days;
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

drop policy attendance_days_write on attendance.attendance_days;
create policy attendance_days_write on attendance.attendance_days
  for all using ((select core.is_admin_or_above()))
  with check ((select core.is_admin_or_above()));
