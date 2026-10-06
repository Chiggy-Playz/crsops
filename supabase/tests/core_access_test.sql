-- Who may see and change what in core: roles (staff < admin < superadmin),
-- module grants, and staff seeing only their own rows.
--
-- Row-level security refuses a disallowed insert with an error (42501), but a
-- disallowed update or delete just matches no rows, so those are checked with
-- tests.rows_changed.

create function tests.rows_changed(p_sql text)
returns bigint
language plpgsql
as $$
declare
  changed bigint;
begin
  execute p_sql;
  get diagnostics changed = row_count;
  return changed;
end;
$$;

create function tests.test_changing_roles()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee');
  other_staff_id uuid := tests.create_user('employee');
  roleless_id uuid := tests.create_user();
  admin_id uuid := tests.create_user('admin');
  superadmin_id uuid := tests.create_user('superadmin');
begin
  perform tests.act_as(staff_id);
  return next is((select array_agg(user_id) from core.user_roles), array[staff_id],
    'staff see only their own role');
  return next is(
    tests.rows_changed(format($sql$ update core.user_roles set role_id = 'admin' where user_id = %L $sql$, staff_id)),
    0::bigint, 'staff can''t make themselves admin');
  return next throws_ok(
    format($sql$ insert into core.user_roles (user_id, role_id) values (%L, 'superadmin') $sql$, roleless_id),
    '42501', null, 'or give anyone a role');

  perform tests.act_as(admin_id);
  return next ok(
    (select count(*) from core.user_roles where user_id in (staff_id, other_staff_id, superadmin_id)) = 3,
    'admins see everyone''s role');
  return next is(
    tests.rows_changed(format($sql$ update core.user_roles set role_id = 'superadmin' where user_id = %L $sql$, admin_id)),
    0::bigint, 'admins can''t make themselves superadmin');
  return next is(
    tests.rows_changed(format($sql$ update core.user_roles set role_id = 'admin' where user_id = %L $sql$, staff_id)),
    0::bigint, 'or change anyone''s role');
  return next throws_ok(
    format($sql$ insert into core.user_roles (user_id, role_id) values (%L, 'admin') $sql$, roleless_id),
    '42501', null, 'or give a role to someone without one');
  return next is(
    tests.rows_changed(format($sql$ delete from core.user_roles where user_id = %L $sql$, superadmin_id)),
    0::bigint, 'or take a role away');

  perform tests.act_as(superadmin_id);
  return next is(
    tests.rows_changed(format($sql$ update core.user_roles set role_id = 'admin' where user_id = %L $sql$, staff_id)),
    1::bigint, 'a superadmin can change roles');
  -- The app sets a role with an upsert.
  return next lives_ok(
    format($sql$ insert into core.user_roles (user_id, role_id) values (%L, 'employee')
                 on conflict (user_id) do update set role_id = excluded.role_id $sql$, roleless_id),
    'and give one to someone without');
end;
$$;

create function tests.test_granting_modules()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee', '{attendance}');
  other_staff_id uuid := tests.create_user('employee', '{attendance}');
  admin_id uuid := tests.create_user('admin');
begin
  perform tests.act_as(staff_id);
  return next is((select array_agg(user_id) from core.module_access), array[staff_id],
    'staff see only their own module grants');
  return next throws_ok(
    format($sql$ insert into core.module_access (user_id, module_id) values (%L, 'challans') $sql$, staff_id),
    '42501', null, 'staff can''t grant themselves a module');
  return next is(
    tests.rows_changed(format($sql$ delete from core.module_access where user_id = %L $sql$, other_staff_id)),
    0::bigint, 'or take one away from someone else');

  perform tests.act_as(admin_id);
  return next lives_ok(
    format($sql$ insert into core.module_access (user_id, module_id) values (%L, 'challans') $sql$, staff_id),
    'admins can grant a module');
  return next is(
    tests.rows_changed(format($sql$ delete from core.module_access where user_id = %L and module_id = 'attendance' $sql$, other_staff_id)),
    1::bigint, 'and take one away');

  perform tests.act_as(staff_id);
  return next ok(core.has_module_access('challans'), 'a granted module counts straight away');
  perform tests.act_as(other_staff_id);
  return next ok(not core.has_module_access('attendance'), 'and a removed one stops counting');
end;
$$;

-- What the helpers every policy builds on answer, for each kind of user.
create function tests.test_access_helpers()
returns setof text
language plpgsql
as $$
declare
  roleless_id uuid := tests.create_user();
  staff_id uuid := tests.create_user('employee', '{attendance}');
  admin_id uuid := tests.create_user('admin');
  superadmin_id uuid := tests.create_user('superadmin');
begin
  perform tests.act_as(roleless_id);
  return next ok(not core.is_admin_or_above() and not core.has_module_access('attendance'),
    'a user with no role and no grants is nobody');

  perform tests.act_as(staff_id);
  return next ok(not core.is_admin_or_above(), 'staff aren''t admins');
  return next ok(core.has_module_access('attendance') and not core.has_module_access('challans'),
    'staff have only the modules granted');

  perform tests.act_as(admin_id);
  return next ok(core.is_admin_or_above() and not core.is_superadmin(), 'an admin isn''t a superadmin');
  return next ok(core.has_module_access('attendance') and core.has_module_access('challans'),
    'admins have every module');

  perform tests.act_as(superadmin_id);
  return next ok(core.is_superadmin() and core.is_admin_or_above(), 'a superadmin counts as an admin too');

  perform tests.act_as_owner();
  return next ok(not has_function_privilege('authenticated', 'core.require_module_access(text)', 'execute'),
    'the app can''t call require_module_access directly');
  return next ok(not has_function_privilege('authenticated', 'core.check_allowed_signup(jsonb)', 'execute'),
    'or the sign-up hook');
  return next ok(not has_function_privilege('authenticated', 'core.handle_new_user()', 'execute'),
    'or the new-user trigger');
end;
$$;

create function tests.test_signup_allow_list_access()
returns setof text
language plpgsql
as $$
declare
  admin_id uuid := tests.create_user('admin');
  superadmin_id uuid := tests.create_user('superadmin');
begin
  insert into core.allowed_signup_emails (email) values ('zz-listed@test.invalid');

  perform tests.act_as(admin_id);
  return next is((select count(*)::int from core.allowed_signup_emails where email = 'zz-listed@test.invalid'), 0,
    'admins can''t see the sign-up allow-list');
  return next throws_ok(
    $sql$ insert into core.allowed_signup_emails (email) values ('zz-sneaky@test.invalid') $sql$,
    '42501', null, 'or add to it');
  return next is(
    tests.rows_changed($sql$ delete from core.allowed_signup_emails where email = 'zz-listed@test.invalid' $sql$),
    0::bigint, 'or remove from it');

  perform tests.act_as(superadmin_id);
  return next is((select count(*)::int from core.allowed_signup_emails where email = 'zz-listed@test.invalid'), 1,
    'a superadmin sees it');
  return next lives_ok(
    $sql$ insert into core.allowed_signup_emails (email) values ('zz-new@test.invalid') $sql$,
    'and can add to it');
  return next is(
    tests.rows_changed($sql$ delete from core.allowed_signup_emails where email = 'zz-listed@test.invalid' $sql$),
    1::bigint, 'and remove from it');
end;
$$;

create function tests.test_profiles_access()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee');
  other_staff_id uuid := tests.create_user('employee');
  admin_id uuid := tests.create_user('admin');
begin
  perform tests.act_as(staff_id);
  return next is((select array_agg(id) from core.profiles), array[staff_id],
    'staff see only their own profile');
  return next throws_ok(
    format($sql$ update core.profiles set email = 'zz@test.invalid' where id = %L $sql$, staff_id),
    '42501', null, 'and can''t change it');

  perform tests.act_as(admin_id);
  return next ok((select count(*) from core.profiles where id in (staff_id, other_staff_id)) = 2,
    'admins see everyone''s');
end;
$$;

-- Staff see their own history and payments, never anyone else's, and can't
-- change either.
create function tests.test_employee_history_access()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee', '{attendance}');
  admin_id uuid := tests.create_user('admin');
  own_employee uuid;
  other_employee uuid;
begin
  insert into core.employees (name, color, user_id) values ('ZZ Me', 0, staff_id) returning id into own_employee;
  insert into core.employees (name, color) values ('ZZ Someone Else', 0) returning id into other_employee;
  insert into core.employee_events (employee_id, event_type, event_date) values
    (own_employee, 'joined', '2099-01-01'), (other_employee, 'joined', '2099-01-01');
  insert into core.employee_ledger_entries (employee_id, entry_date, amount, entry_type) values
    (own_employee, '2099-01-31', 1000, 'salary'), (other_employee, '2099-01-31', 2000, 'salary');

  perform tests.act_as(staff_id);
  return next is((select array_agg(distinct employee_id) from core.employee_events), array[own_employee],
    'staff see only their own events');
  return next is((select array_agg(distinct employee_id) from core.employee_ledger_entries), array[own_employee],
    'and their own payments');
  return next is((select array_agg(distinct employee_id) from core.employee_timeline), array[own_employee],
    'and only their own timeline');
  return next throws_ok(
    format($sql$ insert into core.employee_ledger_entries (employee_id, entry_date, amount, entry_type)
                 values (%L, '2099-02-01', 99999, 'bonus') $sql$, own_employee),
    '42501', null, 'staff can''t add a payment, even to themselves');
  return next is(
    tests.rows_changed(format($sql$ update core.employee_ledger_entries set amount = 99999 where employee_id = %L $sql$, own_employee)),
    0::bigint, 'or change one');
  return next throws_ok(
    format($sql$ insert into core.employee_events (employee_id, event_type, event_date) values (%L, 'left', '2099-02-01') $sql$, own_employee),
    '42501', null, 'or add an event');
  return next is(
    tests.rows_changed(format($sql$ delete from core.employee_events where employee_id = %L $sql$, own_employee)),
    0::bigint, 'or delete one');

  perform tests.act_as(admin_id);
  return next ok((select count(distinct employee_id) from core.employee_ledger_entries
                  where employee_id in (own_employee, other_employee)) = 2,
    'admins see everyone''s payments');
  return next lives_ok(
    format($sql$ insert into core.employee_ledger_entries (employee_id, entry_date, amount, entry_type)
                 values (%L, '2099-02-01', 500, 'advance') $sql$, own_employee),
    'and can add them');
end;
$$;

-- Event types that change who is active ('joined', 'left', …) are
-- superadmin-only; admins may add plain ones. Status types are admin-only.
create function tests.test_type_lists_access()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid := tests.create_user('employee', '{attendance}');
  admin_id uuid := tests.create_user('admin');
  superadmin_id uuid := tests.create_user('superadmin');
begin
  perform tests.act_as(staff_id);
  return next throws_ok($sql$ insert into core.event_types (id) values ('zz_staff_type') $sql$,
    '42501', null, 'staff can''t add event types');
  return next throws_ok($sql$ insert into attendance.status_types (id, label) values ('zz_staff', 'ZZ') $sql$,
    '42501', null, 'or status types');

  perform tests.act_as(admin_id);
  return next lives_ok($sql$ insert into core.event_types (id) values ('zz_plain') $sql$,
    'admins can add a plain event type');
  return next throws_ok($sql$ insert into core.event_types (id, status_effect) values ('zz_fired', 'inactive') $sql$,
    '42501', null, 'but not one that changes who is active');
  return next is(tests.rows_changed($sql$ update core.event_types set status_effect = 'inactive' where id = 'zz_plain' $sql$),
    0::bigint, 'or turn a plain one into one');
  return next lives_ok($sql$ insert into attendance.status_types (id, label) values ('zz_admin', 'ZZ') $sql$,
    'admins can add status types');
  return next is(tests.rows_changed($sql$ update attendance.status_types set label = 'ZZ 2' where id = 'zz_admin' $sql$),
    1::bigint, 'and edit them');

  perform tests.act_as(superadmin_id);
  return next lives_ok($sql$ insert into core.event_types (id, status_effect) values ('zz_fired', 'inactive') $sql$,
    'a superadmin can add one that changes who is active');
end;
$$;

create function tests.test_signed_out_sees_nothing_in_core()
returns setof text
language plpgsql
as $$
begin
  perform set_config('role', 'anon', true);
  return next throws_ok($sql$ select count(*) from core.user_roles $sql$, '42501', null,
    'signed-out requests can''t read roles');
  return next throws_ok($sql$ select count(*) from core.employees $sql$, '42501', null,
    'or employees');
  return next throws_ok($sql$ select count(*) from attendance.attendance_days $sql$, '42501', null,
    'or attendance');
  return next throws_ok($sql$ select core.is_admin_or_above() $sql$, '42501', null,
    'or call the access helpers');
end;
$$;
