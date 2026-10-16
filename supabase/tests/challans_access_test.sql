-- What people can see and do: views, search, and who's allowed.

create function tests.test_views()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_client_id uuid;
  outward_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select client_id into test_client_id from core.client_addresses where id = test_address_id;
  outward_id := tests.outward(test_address_id, null,
    '[{"description":"A","quantity":2,"unit":"zzunit"},{"description":"B","quantity":3}]');
  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', 'Moved', '07', null);

  return next results_eq(
    format($sql$ select item_count, total_quantity, first_item, address_version, latest_address_version, state_name
                 from challans.challan_overview where id = %L $sql$, outward_id),
    $sql$ values (2, 5, 'A', 1, 2, 'Delhi') $sql$,
    'the overview totals items and knows a newer address exists');
  return next ok(
    exists (select 1 from challans.item_units where unit = 'ZZUNIT'),
    'units typed before are suggested');
  return next ok(
    exists (select 1 from challans.financial_years
            where direction = 'outward' and financial_year = tests.financial_year(tests.today())),
    'years with challans are listed');
  return next ok(
    (select created_by_email like 'test-%@test.invalid' from challans.challan_history
     where challan_id = outward_id and event_type = 'created'),
    'history shows who made each change');
end;
$$;

create function tests.test_search()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  second_address_id uuid;
  clients uuid[];
  outward_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  clients := array[(select client_id from core.client_addresses where id = test_address_id)];
  outward_id := challans.create_challan('outward', tests.today(), test_address_id, 'ramesh', 'DL1C 9', null,
    'fragile', '[{"description":"DELL LAPTOP","serial":"SN1","quantity":1}]');
  perform challans.set_bill_number(outward_id, 'B-77');
  perform tests.inward(test_address_id);

  -- Limited to the test client's challans, so real data can't change the counts.
  return next is((select count(*)::int from challans.search_challans(null, clients, null, null, null)), 2,
    'by client');
  return next is((select count(*)::int from challans.search_challans(null, clients, null, null, 'inward')), 1,
    'by direction');
  return next is((select count(*)::int from challans.search_challans('sn1', clients, null, null, null)), 2,
    'by item serial, ignoring case (the inward one has the same item)');
  return next is((select count(*)::int from challans.search_challans('suresh', clients, null, null, null)), 1,
    'by received-by');
  return next is((select count(*)::int from challans.search_challans('b-77', clients, null, null, null)), 1,
    'by bill number');
  return next is((select count(*)::int from challans.search_challans('fragil', clients, null, null, null)), 1,
    'by part of the notes');
  return next is((select count(*)::int from challans.search_challans('dl1c', clients, null, null, null)), 1,
    'by vehicle');
  return next is((select count(*)::int from challans.search_challans('zz test', clients, null, null, null)), 2,
    'by client name');
  return next ok(
    exists (select 1 from challans.search_challans(
      (select number::text from challans.challans where id = outward_id), clients, null, null, 'outward')
      where id = outward_id),
    'by number');
  return next is((select count(*)::int from challans.search_challans('%', clients, null, null, null)), 0,
    '% is searched for literally');
  return next is((select count(*)::int from challans.search_challans('_', clients, null, null, null)), 0,
    '_ is searched for literally');
  return next is((select count(*)::int from challans.search_challans(null, clients, tests.today() + 1, null, null)), 0,
    'from date');
  return next is((select count(*)::int from challans.search_challans(null, clients, null, tests.today() - 1, null)), 0,
    'to date');

  -- A second site of the same client, with its own challan.
  second_address_id := core.save_client_address(null, clients[1], 'Site 2', 'ZZ TEST CLIENT',
    'Plot 9, Udyog Vihar', '06', null);
  perform tests.outward(second_address_id);
  return next is((select count(*)::int
                  from challans.search_challans(null, null, null, null, null, array[second_address_id])), 1,
    'by one address of a client');
  return next is((select count(*)::int from challans.search_challans(null, clients, null, null, null)), 3,
    'by client: every address');
  return next is((select count(*)::int
                  from challans.search_challans(null, null, null, null, null, array[test_address_id, second_address_id])), 3,
    'by several addresses');
  return next is((select count(*)::int from challans.search_challans('udyog', clients, null, null, null)), 1,
    'by the address text');
end;
$$;

create function tests.test_app_cannot_write_tables()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  version_id uuid;
  outward_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select id into version_id from core.client_address_versions where address_id = test_address_id;
  outward_id := tests.outward(test_address_id);

  return next throws_ok(
    format($sql$ insert into challans.challans (direction, challan_date, number, client_address_version_id, handled_by_name)
                 values ('outward', current_date, 999999, %L, 'x') $sql$, version_id),
    '42501', null, 'challans can''t be inserted directly');
  return next throws_ok(
    format($sql$ update challans.challans set number = 1 where id = %L $sql$, outward_id),
    '42501', null, 'or updated');
  return next throws_ok(
    format($sql$ delete from challans.challans where id = %L $sql$, outward_id),
    '42501', null, 'or deleted');
  return next throws_ok(
    format($sql$ delete from challans.challan_events where challan_id = %L $sql$, outward_id),
    '42501', null, 'history can''t be deleted');
  return next throws_ok(
    $sql$ insert into core.clients (name) values ('ZZ Direct') $sql$,
    '42501', null, 'clients can''t be inserted directly');
  return next throws_ok(
    format($sql$ update core.client_address_versions set address = 'x' where id = %L $sql$, version_id),
    '42501', null, 'address versions can''t be updated directly');
  return next throws_ok(
    $sql$ select challans.lock_number_series('outward', 2026::smallint) $sql$,
    '42501', null, 'internal helpers can''t be called');
end;
$$;

create function tests.test_no_access_sees_and_does_nothing()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  outward_id uuid;
  outsider uuid := tests.create_user(null, '{attendance}');
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  outward_id := tests.outward(test_address_id);

  perform tests.act_as(outsider);
  return next is((select count(*)::int from challans.challans), 0, 'can''t see challans');
  return next is((select count(*)::int from challans.challan_items), 0, 'or items');
  return next is((select count(*)::int from challans.challan_history), 0, 'or history');
  return next is((select count(*)::int from core.clients), 0, 'or clients');
  return next is((select count(*)::int from core.client_address_versions), 0, 'or addresses');
  return next is((select count(*)::int from challans.search_challans(null, null, null, null, null)), 0,
    'search finds nothing');

  return next throws_ok(format('select tests.outward(%L)', test_address_id),
    '42501', 'Not allowed', 'can''t create a challan');
  return next throws_ok(format('select challans.cancel_challan(%L, null, false)', outward_id),
    '42501', 'Not allowed', 'or cancel one');
  return next throws_ok(format('select challans.set_received(%L, null)', outward_id),
    '42501', 'Not allowed', 'or follow one up');
  return next throws_ok($sql$ select core.create_client('ZZ X', null, null, null, 'x', '07', null) $sql$,
    '42501', 'Not allowed', 'or create a client');
end;
$$;

create function tests.test_signed_out_sees_nothing()
returns setof text
language plpgsql
as $$
begin
  perform set_config('role', 'anon', true);
  return next throws_ok($sql$ select count(*) from challans.challans $sql$, '42501', null,
    'signed-out requests can''t read challans');
  return next throws_ok($sql$ select count(*) from core.clients $sql$, '42501', null,
    'or clients');
  return next throws_ok($sql$ select challans.create_challan('outward', null, null, null, null, null, null, null) $sql$,
    '42501', null, 'or call the functions');
end;
$$;

create function tests.test_admin_has_access_without_a_grant()
returns setof text
language plpgsql
as $$
declare
  admin_id uuid := tests.create_user('admin');
begin
  perform tests.act_as(admin_id);
  return next lives_ok($sql$ select tests.new_address() $sql$, 'an admin can use challans without a module grant');
end;
$$;

-- The "Delivered by" choices: active employees (even to a user who can't read
-- employees) and custom handlers; nobody without the module sees any.
create function tests.test_handler_choices()
returns setof text
language plpgsql
as $$
declare
  active_id uuid;
  gone_id uuid;
begin
  insert into core.employees (name, color) values ('ZZ Active Staff', 0) returning id into active_id;
  insert into core.employees (name, color) values ('ZZ Gone Staff', 0) returning id into gone_id;
  insert into core.employee_events (employee_id, event_type, event_date) values
    (active_id, 'joined', '2020-01-01'),
    (gone_id, 'joined', '2020-01-01'),
    (gone_id, 'left', '2021-01-01');

  perform tests.act_as_challans_user();
  return next ok(
    not exists (select 1 from core.employees where id = active_id),
    'this user can''t read employees directly');
  return next ok(
    exists (select 1 from challans.handler_choices
            where kind = 'employee' and id = active_id and name = 'ZZ Active Staff'),
    'an active employee is offered, with their id');
  return next ok(
    not exists (select 1 from challans.handler_choices where name = 'ZZ Gone Staff'),
    'an employee who left is not');

  perform challans.add_custom_handler('  zz porter ');
  return next ok(
    exists (select 1 from challans.handler_choices where kind = 'custom' and name = 'zz porter'),
    'a custom handler is offered once added');
  return next is(
    challans.add_custom_handler('ZZ PORTER'), challans.add_custom_handler('zz porter'),
    'adding the same name again, in any case, returns the same one');
  return next throws_ok(
    $sql$ select challans.add_custom_handler('zz active staff') $sql$, 'P0001', null,
    'an employee can''t be added as a custom handler');
  return next throws_ok(
    $sql$ select challans.add_custom_handler('  ') $sql$, 'P0001', 'Enter a name.',
    'a blank name is refused');

  perform tests.act_as_owner();
  perform tests.act_as(tests.create_user(null, '{}'));
  return next throws_ok(
    'select * from challans.handler_choices', '42501', 'Not allowed',
    'without challans access there are no choices');
  return next throws_ok(
    $sql$ select challans.add_custom_handler('zz nobody') $sql$, '42501', 'Not allowed',
    'and none can be added');
end;
$$;

-- Only a superadmin renames or removes custom handlers, and issued challans
-- keep the name they were made with.
create function tests.test_manage_handlers()
returns setof text
language plpgsql
as $$
declare
  handler_id uuid;
  challan_id uuid;
begin
  insert into core.employees (name, color) values ('ZZ Active Staff', 0);

  perform tests.act_as_challans_user();
  handler_id := challans.add_custom_handler('zz porteer');
  challan_id := challans.create_challan('outward', tests.today(), tests.new_address(),
    'zz porteer', null, null, null, tests.one_item());

  return next throws_ok(
    format($sql$ select challans.rename_custom_handler(%L, 'zz porter') $sql$, handler_id),
    '42501', 'Not allowed', 'a challans user can''t rename a custom handler');
  return next throws_ok(
    format($sql$ select challans.delete_custom_handler(%L) $sql$, handler_id),
    '42501', 'Not allowed', 'or delete one');

  perform tests.act_as_owner();
  perform tests.act_as(tests.create_user('superadmin', '{}'));
  perform challans.rename_custom_handler(handler_id, ' zz porter ');
  return next ok(
    exists (select 1 from challans.handler_choices where id = handler_id and name = 'zz porter'),
    'a superadmin renames it');
  return next is(
    (select handled_by_name from challans.challans where id = challan_id),
    'zz porteer', 'an issued challan keeps the old name');
  return next throws_ok(
    format($sql$ select challans.rename_custom_handler(%L, 'ZZ Active Staff') $sql$, handler_id),
    'P0001', null, 'it can''t take an employee''s name');

  perform challans.delete_custom_handler(handler_id);
  return next ok(
    not exists (select 1 from challans.handler_choices where id = handler_id),
    'and deletes it');
  return next is(
    (select handled_by_name from challans.challans where id = challan_id),
    'zz porteer', 'the challan still has the name');
end;
$$;

-- Picking an employee stores their id and their name; a typed name that is
-- exactly one employee's links too; an unknown name stays plain text.
create function tests.test_handler_employee_link()
returns setof text
language plpgsql
as $$
declare
  staff_id uuid;
  address_id uuid;
  challan_id uuid;
begin
  insert into core.employees (name, color) values ('ZZ Linked Staff', 0) returning id into staff_id;
  insert into core.employee_events (employee_id, event_type, event_date)
  values (staff_id, 'joined', '2020-01-01');

  perform tests.act_as_challans_user();
  address_id := tests.new_address();

  challan_id := challans.create_challan('outward', tests.today(), address_id,
    null, null, null, null, tests.one_item(), staff_id);
  return next results_eq(
    format($sql$ select handled_by_name, handled_by_employee_id from challans.challans where id = %L $sql$, challan_id),
    format($sql$ values ('ZZ Linked Staff', %L::uuid) $sql$, staff_id),
    'a picked employee supplies the name and the link');

  challan_id := challans.create_challan('outward', tests.today(), address_id,
    'zz linked staff', null, null, null, tests.one_item());
  return next is(
    (select handled_by_employee_id from challans.challans where id = challan_id),
    staff_id, 'a typed name matching one employee links to them');

  challan_id := challans.create_challan('outward', tests.today(), address_id,
    'Porter', null, null, null, tests.one_item());
  return next ok(
    (select handled_by_employee_id is null from challans.challans where id = challan_id),
    'any other name stays plain text');

  perform tests.act_as_owner();
  update core.employees set name = 'ZZ Renamed Staff' where id = staff_id;
  perform tests.act_as_challans_user();
  challan_id := challans.create_challan('outward', tests.today(), address_id,
    null, null, null, null, tests.one_item(), staff_id);
  perform challans.update_challan(challan_id, address_id, false,
    null, null, 5, null, tests.one_item(), staff_id);
  return next is(
    (select handled_by_name from challans.challans where id = challan_id),
    'ZZ Renamed Staff', 'a new challan uses the current name');

  perform tests.act_as_owner();
  update core.employees set name = 'ZZ Linked Staff' where id = staff_id;
  perform tests.act_as_challans_user();
  perform challans.update_challan(challan_id, address_id, false,
    null, null, 6, null, tests.one_item(), staff_id);
  return next is(
    (select handled_by_name from challans.challans where id = challan_id),
    'ZZ Renamed Staff', 'editing keeps the name the challan was made with');

  return next throws_ok(
    format($sql$ select challans.create_challan('outward', tests.today(), %L, null, null, null, null, tests.one_item(), gen_random_uuid()) $sql$, address_id),
    'P0001', 'That employee no longer exists.', 'an unknown employee id is refused');
end;
$$;
