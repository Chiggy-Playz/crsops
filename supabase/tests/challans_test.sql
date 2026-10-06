-- Challans: creating, numbering, editing, follow-ups, cancelling.

create function tests.test_create_outward()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  version_id uuid;
  expected_number int;
  expected_inward int;
  new_id uuid;
  found challans.challans;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select id into version_id from core.client_address_versions where address_id = test_address_id;
  expected_number := coalesce((
    select max(number) from challans.challans
    where direction = 'outward' and financial_year = tests.financial_year(tests.today())
  ), 0) + 1;
  expected_inward := coalesce((
    select max(number) from challans.challans
    where direction = 'inward' and financial_year = tests.financial_year(tests.today())
  ), 0) + 1;

  new_id := challans.create_challan(
    'outward', tests.today(), test_address_id, ' ramesh ', 'dl1c 1234', 50000, ' note ',
    tests.one_item());
  select * into found from challans.challans where id = new_id;

  return next is(found.number, expected_number, 'gets the next number in the year');
  return next is(found.financial_year, tests.financial_year(tests.today()), 'financial year comes from the date');
  return next is(found.handled_by_name, 'ramesh', 'delivered-by is trimmed');
  return next is(found.vehicle_number, 'DL1C 1234', 'vehicle number is upper-cased');
  return next is(found.notes, 'note', 'notes are trimmed');
  return next is(found.client_address_version_id, version_id, 'prints the address''s current version');
  return next is((select unit from challans.challan_items where challan_id = new_id), 'SET',
    'item unit is upper-cased');
  return next is(
    (select count(*)::int from challans.challan_events where challan_id = new_id and event_type = 'created'), 1,
    'a created event is logged');

  new_id := tests.outward(test_address_id);
  return next is((select number from challans.challans where id = new_id),
    expected_number + 1, 'the next one gets the next number');
  new_id := tests.inward(test_address_id);
  return next is((select number from challans.challans where id = new_id),
    expected_inward, 'inward has its own number series');
end;
$$;

create function tests.test_handled_by_links_an_employee()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  driver_id uuid;
  new_id uuid;
begin
  insert into core.employees (name, color) values ('ZZ Unique Driver', 0) returning id into driver_id;
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();

  new_id := challans.create_challan('outward', tests.today(), test_address_id,
    'zz unique driver', null, null, null, tests.one_item());
  return next is((select handled_by_employee_id from challans.challans where id = new_id),
    driver_id, 'a name matching one employee links to them');
  new_id := tests.outward(test_address_id);
  return next is((select handled_by_employee_id from challans.challans where id = new_id),
    null, 'any other name links to nobody');
end;
$$;

create function tests.test_challan_dates()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  yesterday date := tests.today() - 1;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  perform tests.outward(test_address_id);

  return next throws_ok(
    format('select tests.outward(%L, %L)', test_address_id, tests.today() + 1),
    'P0001', 'The challan date can''t be in the future.', 'a future date is refused');
  return next throws_ok(
    format('select tests.inward(%L, %L)', test_address_id, tests.today() + 1),
    'P0001', 'The challan date can''t be in the future.', 'a future inward date is refused');
  return next throws_ok(
    format($sql$ select challans.create_challan('outward', null, %L, 'r', null, null, null, tests.one_item()) $sql$,
      test_address_id),
    'P0001', 'Pick the challan date.', 'a missing date is refused');

  -- On 1 April yesterday is in the previous year's series, so this can't be tested.
  if tests.financial_year(yesterday) = tests.financial_year(tests.today()) then
    return next throws_like(
      format('select tests.outward(%L, %L)', test_address_id, yesterday),
      'The last outward challan of % is dated %, so this one can''t be dated earlier.',
      'outward can''t be dated before the year''s latest outward');
    return next lives_ok(
      format('select tests.inward(%L, %L)', test_address_id, yesterday),
      'inward can be back-dated');
  else
    return next skip('today is the first day of a financial year', 2);
  end if;

  return next lives_ok(
    format('select tests.inward(%L, %L)', test_address_id, tests.today() - 400),
    'inward can be dated in an earlier financial year');
end;
$$;

create function tests.test_create_challan_validation()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();

  return next throws_ok(
    format($sql$ select challans.create_challan('sideways', tests.today(), %L, 'r', null, null, null, tests.one_item()) $sql$,
      test_address_id),
    'P0001', 'Unknown challan direction "sideways".', 'an unknown direction is refused');
  return next throws_ok(
    format($sql$ select challans.create_challan('outward', tests.today(), %L, '  ', null, null, null, tests.one_item()) $sql$,
      test_address_id),
    'P0001', 'Enter who is delivering it.', 'outward needs a delivered-by');
  return next throws_ok(
    format($sql$ select challans.create_challan('inward', tests.today(), %L, '  ', null, null, null, tests.one_item()) $sql$,
      test_address_id),
    'P0001', 'Enter who received it.', 'inward needs a received-by');
  return next throws_ok(
    format($sql$ select challans.create_challan('outward', tests.today(), %L, 'r', null, 0, null, tests.one_item()) $sql$,
      test_address_id),
    'P0001', 'The declared value must be more than zero, or left empty.', 'a zero value is refused');
  return next throws_ok(
    format('select tests.outward(%L, null, %L)', gen_random_uuid(), tests.one_item()),
    'P0001', 'That address no longer exists. It may have been deleted.', 'a missing address is refused');
end;
$$;

create function tests.test_item_validation()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  new_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();

  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '[]'),
    'P0001', 'Add at least one item.', 'no items is refused');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '{}'),
    'P0001', 'Add at least one item.', 'items that aren''t a list are refused');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '[{"description":" ","quantity":1}]'),
    'P0001', 'Item 1: enter a description.', 'a blank description is refused');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id,
      '[{"description":"A","quantity":1},{"description":"B"}]'),
    'P0001', 'Item 2: enter the quantity.', 'a missing quantity is refused, naming the item');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '[{"description":"A","quantity":"2"}]'),
    'P0001', 'Item 1: enter the quantity.', 'a quantity that isn''t a number is refused');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '[{"description":"A","quantity":0}]'),
    'P0001', 'Item 1: the quantity must be a whole number, 1 or more.', 'quantity 0 is refused');
  return next throws_ok(format('select tests.outward(%L, null, %L)', test_address_id, '[{"description":"A","quantity":1.5}]'),
    'P0001', 'Item 1: the quantity must be a whole number, 1 or more.', 'a fractional quantity is refused');

  new_id := tests.outward(test_address_id, null,
    '[{"description":" first ","quantity":1},{"description":"second","additional_description":" x ","serial":"s","quantity":3}]');
  return next results_eq(
    format('select position::int, description, additional_description, quantity from challans.challan_items where challan_id = %L order by position', new_id),
    $sql$ values (1, 'first', null, 1), (2, 'second', 'x', 3) $sql$,
    'items are saved in order, tidied');
end;
$$;

create function tests.test_edit_challan()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_client_id uuid;
  first_version_id uuid;
  test_challan_id uuid;
  found challans.challans;
  two_items jsonb := '[{"description":"DELL LAPTOP","quantity":2},{"description":"MOUSE","quantity":1}]';
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select client_id into test_client_id from core.client_addresses where id = test_address_id;
  select id into first_version_id from core.client_address_versions where address_id = test_address_id;
  test_challan_id := challans.create_challan(
    'outward', tests.today(), test_address_id, 'ramesh', 'DL1C 1234', 50000, null, tests.one_item());

  perform challans.update_challan(test_challan_id, test_address_id, false, 'ramesh', 'dl1c 1234', 50000, null, tests.one_item());
  return next is(
    (select count(*)::int from challans.challan_events where challan_id = test_challan_id and event_type = 'edited'), 0,
    'saving with nothing changed logs nothing');

  -- The address moves on to version 2; the challan keeps version 1.
  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', 'Moved', '07', null);
  perform challans.update_challan(test_challan_id, test_address_id, false, 'suresh', null, null, 'note', two_items);
  select * into found from challans.challans where id = test_challan_id;
  return next is(found.client_address_version_id, first_version_id, 'keeps the printed address unless asked');
  return next is(found.handled_by_name || '|' || coalesce(found.vehicle_number, '-') || '|'
    || coalesce(found.declared_value::text, '-') || '|' || found.notes, 'suresh|-|-|note', 'changes are saved');
  return next is((select count(*)::int from challans.challan_items where challan_id = test_challan_id), 2,
    'items are replaced');
  return next is(
    (select array_agg(key order by key) from challans.challan_events e, jsonb_object_keys(e.changes) key
     where e.challan_id = test_challan_id and e.event_type = 'edited'),
    array['declared_value', 'handled_by_name', 'items', 'notes', 'vehicle_number'],
    'the edit event lists each changed field');

  perform challans.update_challan(test_challan_id, test_address_id, true, 'suresh', null, null, 'note', two_items);
  return next is(
    (select v.version from challans.challans c
     join core.client_address_versions v on v.id = c.client_address_version_id where c.id = test_challan_id),
    2, 'asking for the latest details moves to version 2');
  return next ok(
    (select changes ? 'address' from challans.challan_events
     where challan_id = test_challan_id and event_type = 'edited' order by id desc limit 1),
    'the address change is logged');

  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, ' ', null, null, null, tests.one_item()) $sql$, test_challan_id, test_address_id),
    'P0001', 'Enter who is delivering it.', 'an edit still needs a delivered-by');
  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, 'r', null, -5, null, tests.one_item()) $sql$, test_challan_id, test_address_id),
    'P0001', 'The declared value must be more than zero, or left empty.', 'an edit can''t set a negative value');
  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, 'r', null, null, null, '[]') $sql$, test_challan_id, test_address_id),
    'P0001', 'Add at least one item.', 'an edit can''t remove every item');
  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, 'r', null, null, null, tests.one_item()) $sql$,
      gen_random_uuid(), test_address_id),
    'P0001', 'That challan no longer exists.', 'editing a missing challan is refused');
end;
$$;

create function tests.test_edit_inward_and_change_client()
returns setof text
language plpgsql
as $$
declare
  first_address_id uuid;
  other_address_id uuid;
  inward_id uuid;
begin
  perform tests.act_as_challans_user();
  first_address_id := tests.new_address('ZZ First');
  other_address_id := tests.new_address('ZZ Second');
  inward_id := tests.inward(first_address_id);

  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, ' ', null, null, null, tests.one_item()) $sql$,
      inward_id, first_address_id),
    'P0001', 'Enter who received it.', 'an inward edit needs a received-by');

  perform challans.update_challan(inward_id, other_address_id, false, 'suresh', null, null, null, tests.one_item());
  return next is(
    (select client_name from challans.challan_overview where id = inward_id), 'ZZ Second',
    'the challan can move to another client');
  return next isnt(
    (select locked_at from core.client_address_versions where address_id = other_address_id), null,
    'and that client''s address version is locked');
end;
$$;

create function tests.test_follow_ups()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_challan_id uuid;
  inward_id uuid;
  found challans.challans;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  test_challan_id := tests.outward(test_address_id);
  inward_id := tests.inward(test_address_id);

  perform challans.set_received(test_challan_id, tests.today());
  perform challans.set_bill_number(test_challan_id, ' b-12 ');
  perform challans.set_digitally_signed(test_challan_id, true);
  select * into found from challans.challans where id = test_challan_id;
  return next is(found.received_on, tests.today(), 'received date saved');
  return next is(found.bill_number, 'B-12', 'bill number saved, upper-cased');
  return next ok(found.digitally_signed, 'digitally signed saved');

  perform challans.set_bill_number(test_challan_id, null);
  return next is((select received_on from challans.challans where id = test_challan_id), tests.today(),
    'clearing the bill number leaves the received date alone (the old app''s bug)');

  -- Saving the same value again logs nothing.
  perform challans.set_received(test_challan_id, tests.today());
  perform challans.set_bill_number(test_challan_id, null);
  perform challans.set_digitally_signed(test_challan_id, true);
  return next is(
    (select count(*)::int from challans.challan_events
     where challan_id = test_challan_id and event_type in ('received', 'bill_number', 'digitally_signed')),
    4, 'each real change is logged once');

  perform challans.set_received(test_challan_id, null);
  return next is((select received_on from challans.challans where id = test_challan_id), null,
    'the received date can be cleared');

  return next throws_ok(format('select challans.set_received(%L, %L)', test_challan_id, tests.today() + 1),
    'P0001', 'The received date can''t be in the future.', 'a future received date is refused');
  return next throws_ok(format('select challans.set_received(%L, %L)', test_challan_id, tests.today() - 400),
    'P0001', 'It can''t be received before the challan date.', 'received before the challan date is refused');
  return next throws_ok(format('select challans.set_received(%L, %L)', inward_id, tests.today()),
    'P0001', 'Only outward challans have this.', 'inward has no received date');
  return next throws_ok(format('select challans.set_bill_number(%L, %L)', inward_id, 'X'),
    'P0001', 'Only outward challans have this.', 'inward has no bill number');
  return next throws_ok(format('select challans.set_digitally_signed(%L, true)', inward_id),
    'P0001', 'Only outward challans have this.', 'inward isn''t digitally signed');
end;
$$;

create function tests.test_cancel()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  plain_id uuid;
  outward_id uuid;
  return_id uuid;
  inward_id uuid;
  found challans.challans;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  plain_id := tests.outward(test_address_id);
  outward_id := tests.outward(test_address_id);
  inward_id := tests.inward(test_address_id);

  return next is(challans.cancel_challan(plain_id, null, false), null,
    'cancelling without a return makes no inward challan');
  select * into found from challans.challans where id = plain_id;
  return next isnt(found.cancelled_at, null, 'it is cancelled');
  return next ok(found.number is not null, 'and keeps its number');

  return_id := challans.cancel_challan(outward_id, ' wrong client ', true);
  return next is((select cancel_reason from challans.challans where id = outward_id), 'wrong client',
    'the reason is saved, trimmed');
  select * into found from challans.challans where id = return_id;
  return next is(found.direction || '|' || found.challan_date || '|' || found.reverses_challan_id,
    'inward|' || tests.today() || '|' || outward_id, 'the return is an inward challan dated today');
  return next is((select count(*)::int from challans.challan_items where challan_id = return_id), 1,
    'with the same items');
  return next is((select returned_by_challan_id from challans.challan_overview where id = outward_id), return_id,
    'the overview links the two');
  return next ok(
    (select changes ? 'return_challan_id' from challans.challan_events
     where challan_id = outward_id and event_type = 'cancelled'),
    'the cancel event records the return');
  return next ok(
    (select note like 'Brought back by cancelling outward challan %' from challans.challan_events
     where challan_id = return_id and event_type = 'created'),
    'the return''s history says where it came from');

  return next throws_ok(
    format($sql$ select challans.update_challan(%L, %L, false, 'x', null, null, null, tests.one_item()) $sql$,
      outward_id, test_address_id),
    'P0001', 'This challan is cancelled, so it can''t be changed.', 'a cancelled challan can''t be edited');
  return next throws_ok(format('select challans.cancel_challan(%L, null, false)', outward_id),
    'P0001', 'This challan is cancelled, so it can''t be changed.', 'or cancelled twice');
  return next throws_ok(format('select challans.set_bill_number(%L, %L)', outward_id, 'X'),
    'P0001', 'This challan is cancelled, so it can''t be changed.', 'or followed up');
  return next throws_ok(format('select challans.cancel_challan(%L, null, true)', inward_id),
    'P0001', 'Only an outward challan can have its goods brought back in.',
    'an inward challan can''t have a return');
end;
$$;
