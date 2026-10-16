-- A day now has one status instead of a first and second half. Half days, which
-- used to be present in one half and absent in the other, become a status of
-- their own: half_day.
--
-- Anything else that differs between the halves can't be turned into one status
-- without guessing, so the migration stops (and changes nothing) if it finds
-- any. On prod, 18 days were present/absent when this was written.

insert into attendance.status_types (id, label, icon_name, color_hex)
values ('half_day', 'Half Day', 'contrast', '#009688');

alter table attendance.attendance_days
  add column status text references attendance.status_types(id);

do $$
declare
  odd_days integer;
begin
  select count(*) into odd_days
  from attendance.attendance_days
  where first_half_status is distinct from second_half_status
    and not (first_half_status = 'present' and second_half_status = 'absent')
    and not (first_half_status = 'absent' and second_half_status = 'present');
  if odd_days > 0 then
    raise exception '% days have halves that do not map to one status', odd_days;
  end if;
end;
$$;

update attendance.attendance_days
set status = case
  when first_half_status = second_half_status then first_half_status
  else 'half_day'
end;

alter table attendance.attendance_days alter column status set not null;
alter table attendance.attendance_days
  drop column first_half_status,
  drop column second_half_status;

-- Every status can apply to a whole day now, so there is nothing to split.
alter table attendance.status_types drop column splittable;

-- The columns this function returns changed, so it has to be dropped and
-- created again.
drop function attendance.effective_range_status(date, date, uuid);

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
  status text,
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
    ad.status,
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

-- Minutes worked, late, early and overtime for days with a time entered.
-- A half day is never "early": leaving at lunchtime is what a half day is.
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
set search_path = ''
as $$
  with base as (
    select
      ad.employee_id,
      ad.date,
      ad.time_in,
      ad.time_out,
      ad.status,
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
    -- true for an overnight shift (it ends well past default_end the next day)
    -- or a half day.
    (time_out is not null and not is_overnight and status <> 'half_day'
      and effective_time_out < default_end) as is_early,
    greatest(
      0,
      (extract(epoch from worked_interval) / 60)::integer
        - (extract(epoch from (default_end - default_start)) / 60)::integer
    ) as overtime_minutes
  from computed;
$$;
