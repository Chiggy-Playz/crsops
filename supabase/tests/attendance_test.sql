-- Attendance: the day-by-day status functions and who can read and write.
--
-- Most tests use dates in 2099 with their own shift row, so real shifts and
-- real attendance can't change the results.

-- An employee who joined on 5 Jan 2099, left on 10 Jan and was rehired on
-- 20 Jan, under a 10:00–18:00 shift with Saturday and Sunday off.
create function tests.employee_with_stints()
returns uuid
language plpgsql
as $$
declare
  new_id uuid;
begin
  insert into attendance.shift_defaults (effective_from, default_start, default_end, week_off_days)
  values ('2099-01-01', '10:00', '18:00', '{6,7}');
  insert into core.employees (name, color) values ('ZZ Test Employee', 0) returning id into new_id;
  insert into core.employee_events (employee_id, event_type, event_date) values
    (new_id, 'joined', '2099-01-05'),
    (new_id, 'left', '2099-01-10'),
    (new_id, 'rehired', '2099-01-20');
  return new_id;
end;
$$;

create function tests.test_effective_range_status()
returns setof text
language plpgsql
as $$
declare
  employee uuid := tests.employee_with_stints();
begin
  insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status, note)
  values (employee, '2099-01-06', 'present', 'absent', 'half day');

  return next is(
    (select count(*)::int from attendance.effective_range_status('2099-01-01', '2099-01-31', employee)),
    6 + 12, 'one row per day employed: 5–10 Jan (the leaving day counts) and 20–31 Jan');
  return next ok(
    not exists (select 1 from attendance.effective_range_status('2099-01-01', '2099-01-31', employee)
                where date < '2099-01-05' or date between '2099-01-11' and '2099-01-19'),
    'no rows before joining or between stints');
  return next ok(
    (select bool_and(is_week_off = (extract(isodow from date) in (6, 7)))
     from attendance.effective_range_status('2099-01-01', '2099-01-31', employee)),
    'week-offs follow the shift in force');
  return next results_eq(
    format($sql$ select date, first_half_status, second_half_status, note
                 from attendance.effective_range_status('2099-01-01', '2099-01-31', %L)
                 where is_explicit $sql$, employee),
    $sql$ values ('2099-01-06'::date, 'present', 'absent', 'half day') $sql$,
    'only the marked day is explicit, with what was marked');
  return next is(
    (select count(*)::int from attendance.effective_range_status('2099-01-06', '2099-01-07', employee)),
    2, 'the range limits the days');
end;
$$;

create function tests.test_employee_status_as_of()
returns setof text
language plpgsql
as $$
declare
  employee uuid := tests.employee_with_stints();
begin
  return next is(core.employee_status_as_of(employee, '2099-01-04'), 'inactive', 'before joining');
  return next is(core.employee_status_as_of(employee, '2099-01-05'), 'active', 'on the joining day');
  return next is(core.employee_status_as_of(employee, '2099-01-10'), 'active',
    'on the leaving day, matching effective_range_status');
  return next is(core.employee_status_as_of(employee, '2099-01-11'), 'inactive', 'after leaving');
  return next is(core.employee_status_as_of(employee, '2099-01-20'), 'active', 'after rehiring');
end;
$$;

create function tests.test_derived_flags()
returns setof text
language plpgsql
as $$
declare
  employee uuid := tests.employee_with_stints();
begin
  insert into attendance.attendance_days (employee_id, date, time_in, time_out) values
    (employee, '2099-01-07', '10:00', '18:00'),
    (employee, '2099-01-08', '10:30', '17:00'),
    (employee, '2099-01-09', null, '20:00'),
    (employee, '2099-01-20', '22:00', '02:00');
  insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status)
  values (employee, '2099-01-21', 'present', 'present');

  return next results_eq(
    format($sql$ select date, worked_minutes, is_late, is_early, overtime_minutes
                 from attendance.derived_flags('2099-01-01', '2099-01-31', %L) order by date $sql$, employee),
    $sql$ values
      ('2099-01-07'::date, 480, false, false, 0),
      ('2099-01-08'::date, 390, true, true, 0),
      ('2099-01-09'::date, 600, false, false, 120),
      ('2099-01-20'::date, 240, true, false, 0) $sql$,
    'on time; late and early; missing time-in uses the shift start, overtime; overnight shift isn''t early');
end;
$$;

create function tests.test_recent_gaps()
returns setof text
language plpgsql
as $$
declare
  employee uuid;
  today date := (now() at time zone 'Asia/Kolkata')::date;
begin
  insert into core.employees (name, color) values ('ZZ Gaps', 0) returning id into employee;
  insert into core.employee_events (employee_id, event_type, event_date)
  values (employee, 'joined', today - 30);
  insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status)
  values (employee, today - 3, 'present', 'present');

  return next ok(
    exists (select 1 from attendance.recent_gaps() where employee_id = employee),
    'unmarked working days in the last week are gaps');
  return next ok(
    not exists (select 1 from attendance.recent_gaps() where employee_id = employee and date = today - 3),
    'a marked day isn''t a gap');
  return next ok(
    not exists (select 1 from attendance.recent_gaps() g
                join attendance.effective_range_status(today - 7, today - 1, employee) r
                  on r.employee_id = g.employee_id and r.date = g.date
                where g.employee_id = employee and r.is_week_off),
    'a week-off isn''t a gap');
  return next ok(
    not exists (select 1 from attendance.recent_gaps() where employee_id = employee
                and (date >= today or date < today - 7)),
    'only the last 7 days, not today');
end;
$$;

create function tests.test_attendance_access()
returns setof text
language plpgsql
as $$
declare
  employee uuid := tests.employee_with_stints();
  other_employee uuid;
  admin_id uuid := tests.create_user('admin');
  staff_id uuid := tests.create_user('employee', '{attendance}');
  outsider_id uuid := tests.create_user('employee');
begin
  insert into core.employees (name, color) values ('ZZ Other', 0) returning id into other_employee;
  update core.employees set user_id = staff_id where id = employee;
  update core.employees set user_id = outsider_id where id = other_employee;
  insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status) values
    (employee, '2099-01-06', 'present', 'present'),
    (other_employee, '2099-01-06', 'present', 'present');

  perform tests.act_as(staff_id);
  return next is(
    (select array_agg(employee_id) from attendance.attendance_days where date = '2099-01-06'),
    array[employee], 'staff with attendance access see only their own days');
  return next throws_ok(
    format($sql$ insert into attendance.attendance_days (employee_id, date) values (%L, '2099-01-07') $sql$, employee),
    '42501', null, 'and can''t mark attendance, even their own');

  perform tests.act_as(outsider_id);
  return next is((select count(*)::int from attendance.attendance_days where date = '2099-01-06'), 0,
    'without attendance access, not even their own days');

  perform tests.act_as(admin_id);
  return next is((select count(*)::int from attendance.attendance_days where date = '2099-01-06'), 2,
    'an admin sees everyone');
  return next lives_ok(
    format($sql$ insert into attendance.attendance_days (employee_id, date, first_half_status) values (%L, '2099-01-07', 'present') $sql$, employee),
    'and can mark attendance');
  return next throws_ok(
    $sql$ update attendance.shift_defaults set default_start = '09:00' where effective_from = '2099-01-01' $sql$,
    '42501', null, 'shift rows can''t be edited, only added (even by an admin)');
end;
$$;
