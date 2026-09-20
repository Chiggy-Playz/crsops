-- CRS Ops — attendance functions (Phase 3)

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
