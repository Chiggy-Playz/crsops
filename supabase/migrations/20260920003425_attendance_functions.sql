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
