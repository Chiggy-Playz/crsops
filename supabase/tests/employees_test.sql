-- Employees: core.create_employee and who can see whom.

create function tests.test_create_employee()
returns setof text
language plpgsql
as $$
declare
  admin_id uuid := tests.create_user('admin');
  staff_id uuid := tests.create_user('employee', '{attendance}');
  created core.employees;
begin
  perform tests.act_as(admin_id);
  created := core.create_employee('ZZ New Hire', 0, 15000, null, '2099-02-01');
  return next is(created.name, 'ZZ New Hire', 'an admin can add an employee');
  return next results_eq(
    format($sql$ select event_type, event_date, created_by from core.employee_events where employee_id = %L $sql$,
      created.id),
    format($sql$ values ('joined', '2099-02-01'::date, %L::uuid) $sql$, admin_id),
    'with a joined event, in the same step');

  perform tests.act_as(staff_id);
  return next throws_ok(
    $sql$ select core.create_employee('ZZ Sneaky', 0, null, null, '2099-02-01') $sql$,
    '42501', null, 'staff can''t add employees');
end;
$$;

create function tests.test_employee_visibility()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee', '{attendance}');
  own_id uuid;
  changed_rows bigint;
begin
  insert into core.employees (name, color, user_id) values ('ZZ Me', 0, staff_id) returning id into own_id;
  insert into core.employees (name, color) values ('ZZ Someone Else', 0);

  perform tests.act_as(staff_id);
  return next is((select array_agg(id) from core.employees), array[own_id],
    'staff see only their own employee record');
  -- Row-level security makes the update match no rows rather than fail.
  update core.employees set salary = 1 where id = own_id;
  get diagnostics changed_rows = row_count;
  return next is(changed_rows, 0::bigint, 'and can''t change it');
end;
$$;
