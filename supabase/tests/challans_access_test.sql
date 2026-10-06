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
    exists (select 1 from challans.handled_by_names where name = 'ramesh'),
    'names typed before are suggested');
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
