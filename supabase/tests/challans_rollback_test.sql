-- Tests for the clients and challans database functions, safe to run against
-- the real database: everything happens inside one DO block that always ends
-- by raising an error, and an error undoes everything the block did.
--
--   supabase db query --linked -f supabase/tests/challans_rollback_test.sql
--
-- Expected result: an error reading "ALL PASSED (rolled back)". Anything
-- else ("FAIL: ...", or a Postgres error) is a failing test.
--
-- It acts as the first superadmin (so module checks pass) by setting the
-- same JWT claims PostgREST sets for a signed-in request.

do $$
declare
  admin_id uuid;
  -- Worked out before switching to the signed-in role, which (rightly)
  -- can't call these internal helpers.
  today date := challans.today();
  this_year smallint := challans.financial_year_of(challans.today());
  yesterday_year smallint := challans.financial_year_of(challans.today() - 1);
  test_client_id uuid;
  test_address_id uuid;
  version1_id uuid;
  outward_id uuid;
  outward2_id uuid;
  inward_id uuid;
  return_id uuid;
  expected_number int;
  row_count int;
  message text;
  found_challan challans.challans;
  one_item jsonb := '[{"description":"DELL LAPTOP","serial":"SN1","quantity":2,"unit":"set"}]';
  two_items jsonb := '[{"description":"DELL LAPTOP","quantity":2},{"description":"MOUSE","quantity":1}]';
begin
  select user_id into admin_id
  from core.user_roles where role_id = 'superadmin' limit 1;
  if admin_id is null then
    raise exception 'FAIL: no superadmin to act as';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);

  -- ── Clients ──────────────────────────────────────────────────────────────

  test_client_id := core.create_client(
    'ZZ Test   Client', 'referred by test', null, null,
    E'Line 1\r\n  Line 2  ', '07', ' 07aaccv3676j1zy ');

  select a.id into test_address_id from core.client_addresses a where a.client_id = test_client_id;
  select v.id into version1_id from core.client_address_versions v where v.address_id = test_address_id;

  if (select name from core.clients where id = test_client_id) <> 'ZZ Test Client' then
    raise exception 'FAIL: client name not tidied';
  end if;
  if (select label from core.client_addresses where id = test_address_id) <> 'Main' then
    raise exception 'FAIL: first address label should default to Main';
  end if;
  if (select v.address from core.client_address_versions v where v.id = version1_id) <> E'Line 1\nLine 2' then
    raise exception 'FAIL: address text not cleaned';
  end if;
  if (select v.gstin from core.client_address_versions v where v.id = version1_id) <> '07AACCV3676J1ZY' then
    raise exception 'FAIL: GSTIN not cleaned';
  end if;
  if (select v.name_on_challan from core.client_address_versions v where v.id = version1_id) <> 'ZZ Test Client' then
    raise exception 'FAIL: name on challan should default to the client name';
  end if;

  begin
    perform core.create_client('zz test client', null, null, null, 'x', '07', null);
    raise exception 'FAIL: duplicate client name allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message not like 'A client named%already exists.' then
    raise exception 'FAIL: duplicate name message was: %', message;
  end if;

  begin
    perform core.create_client('ZZ Bad GSTIN', null, null, null, 'x', '07', 'NOT AVAILABLE');
    raise exception 'FAIL: bad GSTIN allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message not like 'GSTIN%isn''t valid%' then
    raise exception 'FAIL: bad GSTIN message was: %', message;
  end if;

  -- A lone \r (old Mac line break) is a line break, not deleted.
  if core.clean_text(E'A,\rB\r\nC') <> E'A,\nB\nC' then
    raise exception 'FAIL: line breaks not normalised: %', core.clean_text(E'A,\rB\r\nC');
  end if;

  -- An unused version is edited in place.
  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', E'Line 1\nLine 2', '07', null);
  if (select count(*) from core.client_address_versions where address_id = test_address_id) <> 1 then
    raise exception 'FAIL: editing an unused address should not add a version';
  end if;

  -- The last address can't be deleted.
  begin
    perform core.delete_client_address(test_address_id);
    raise exception 'FAIL: deleted the only address';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'A client needs at least one address.' then
    raise exception 'FAIL: last address message was: %', message;
  end if;

  -- ── Creating challans ────────────────────────────────────────────────────

  expected_number := coalesce((
    select max(number) from challans.challans
    where direction = 'outward' and financial_year = this_year
  ), 0) + 1;

  outward_id := challans.create_challan(
    'outward', today, test_address_id, ' ramesh ', 'dl1c 1234', 50000, null, one_item);
  select * into found_challan from challans.challans where id = outward_id;

  if found_challan.number <> expected_number then
    raise exception 'FAIL: number % but expected %', found_challan.number, expected_number;
  end if;
  if found_challan.financial_year <> this_year then
    raise exception 'FAIL: financial year not worked out from the date';
  end if;
  if found_challan.handled_by_name <> 'ramesh' or found_challan.vehicle_number <> 'DL1C 1234' then
    raise exception 'FAIL: text not cleaned: "%" "%"', found_challan.handled_by_name, found_challan.vehicle_number;
  end if;
  if found_challan.client_address_version_id <> version1_id then
    raise exception 'FAIL: challan should print the current address version';
  end if;
  if (select locked_at from core.client_address_versions where id = version1_id) is null then
    raise exception 'FAIL: the printed version was not locked';
  end if;
  if (select unit from challans.challan_items where challan_id = outward_id) <> 'SET' then
    raise exception 'FAIL: unit not upper-cased';
  end if;
  if (select count(*) from challans.challan_events where challan_id = outward_id and event_type = 'created') <> 1 then
    raise exception 'FAIL: no created event';
  end if;

  -- The next one gets the next number.
  outward2_id := challans.create_challan('outward', today, test_address_id, 'ramesh', null, null, null, one_item);
  if (select number from challans.challans where id = outward2_id) <> expected_number + 1 then
    raise exception 'FAIL: second challan did not get the next number';
  end if;

  -- Outward can't be dated before the year's latest outward challan.
  if yesterday_year = this_year then
    begin
      perform challans.create_challan('outward', today - 1, test_address_id, 'ramesh', null, null, null, one_item);
      raise exception 'FAIL: outward back-dated before the latest';
    exception when others then
      message := sqlerrm;
    end;
    if message not like 'The last outward challan of % is dated %' then
      raise exception 'FAIL: back-dating message was: %', message;
    end if;

    -- Inward can be back-dated.
    inward_id := challans.create_challan('inward', today - 1, test_address_id, 'suresh', null, null, null, one_item);
    if (select direction from challans.challans where id = inward_id) <> 'inward' then
      raise exception 'FAIL: inward not created';
    end if;
  end if;

  begin
    perform challans.create_challan('outward', today + 1, test_address_id, 'ramesh', null, null, null, one_item);
    raise exception 'FAIL: future date allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'The challan date can''t be in the future.' then
    raise exception 'FAIL: future date message was: %', message;
  end if;

  begin
    perform challans.create_challan('outward', today, test_address_id, 'ramesh', null, null, null, '[]');
    raise exception 'FAIL: no items allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'Add at least one item.' then
    raise exception 'FAIL: no items message was: %', message;
  end if;

  begin
    perform challans.create_challan('outward', today, test_address_id, 'ramesh', null, null, null,
      '[{"description":"X","quantity":0}]');
    raise exception 'FAIL: quantity 0 allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'Item 1: the quantity must be a whole number, 1 or more.' then
    raise exception 'FAIL: quantity message was: %', message;
  end if;

  begin
    perform challans.create_challan('outward', today, test_address_id, '  ', null, null, null, one_item);
    raise exception 'FAIL: blank delivered-by allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'Enter who is delivering it.' then
    raise exception 'FAIL: delivered-by message was: %', message;
  end if;

  -- ── Address versions after use ───────────────────────────────────────────

  -- The used version is frozen, so editing adds version 2.
  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', 'New address', '07', null);
  if (select max(version) from core.client_address_versions where address_id = test_address_id) <> 2 then
    raise exception 'FAIL: editing a used address should add version 2';
  end if;
  if (select address from core.client_address_versions where id = version1_id) <> E'Line 1\nLine 2' then
    raise exception 'FAIL: the used version changed';
  end if;

  begin
    update core.client_address_versions set address = 'hack' where id = version1_id;
    raise exception 'FAIL: direct update of a version allowed';
  exception when insufficient_privilege then
    null;
  end;

  -- The client can't be deleted now.
  begin
    perform core.delete_client(test_client_id);
    raise exception 'FAIL: deleted a client that is on challans';
  exception when others then
    message := sqlerrm;
  end;
  if message not like 'This client is on challans%' then
    raise exception 'FAIL: delete client message was: %', message;
  end if;

  -- ── Editing ──────────────────────────────────────────────────────────────

  -- Saving with nothing changed logs nothing.
  perform challans.update_challan(outward_id, test_address_id, false, 'ramesh', 'DL1C 1234', 50000, null, one_item);
  if (select count(*) from challans.challan_events where challan_id = outward_id and event_type = 'edited') <> 0 then
    raise exception 'FAIL: an edit with no changes was logged';
  end if;

  -- A real change keeps the old address version and logs what changed.
  perform challans.update_challan(outward_id, test_address_id, false, 'suresh', 'DL1C 1234', null, 'note', two_items);
  select * into found_challan from challans.challans where id = outward_id;
  if found_challan.client_address_version_id <> version1_id then
    raise exception 'FAIL: edit moved to the new address version without being asked';
  end if;
  if found_challan.declared_value is not null or found_challan.handled_by_name <> 'suresh' then
    raise exception 'FAIL: edit not saved';
  end if;
  if (select count(*) from challans.challan_items where challan_id = outward_id) <> 2 then
    raise exception 'FAIL: items not replaced';
  end if;
  if not (select changes ?& array['handled_by_name', 'declared_value', 'notes', 'items']
          from challans.challan_events
          where challan_id = outward_id and event_type = 'edited') then
    raise exception 'FAIL: edit event missing changes';
  end if;

  -- Asking for the latest details moves to version 2.
  perform challans.update_challan(outward_id, test_address_id, true, 'suresh', 'DL1C 1234', null, 'note', two_items);
  if (select v.version from challans.challans c
      join core.client_address_versions v on v.id = c.client_address_version_id
      where c.id = outward_id) <> 2 then
    raise exception 'FAIL: use-latest did not move to version 2';
  end if;

  -- ── Follow-ups ───────────────────────────────────────────────────────────

  perform challans.set_received(outward_id, today);
  perform challans.set_bill_number(outward_id, ' b-12 ');
  perform challans.set_digitally_signed(outward_id, true);
  select * into found_challan from challans.challans where id = outward_id;
  if found_challan.received_on <> today or found_challan.bill_number <> 'B-12' or not found_challan.digitally_signed then
    raise exception 'FAIL: follow-ups not saved';
  end if;
  -- Setting the bill number must not touch the received date (the old app's bug).
  perform challans.set_bill_number(outward_id, null);
  if (select received_on from challans.challans where id = outward_id) <> today then
    raise exception 'FAIL: bill number change cleared the received date';
  end if;
  if (select count(*) from challans.challan_events
      where challan_id = outward_id and event_type in ('received', 'bill_number', 'digitally_signed')) <> 4 then
    raise exception 'FAIL: follow-ups not logged';
  end if;

  begin
    perform challans.set_received(outward_id, today + 1);
    raise exception 'FAIL: future received date allowed';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'The received date can''t be in the future.' then
    raise exception 'FAIL: received message was: %', message;
  end if;

  if inward_id is not null then
    begin
      perform challans.set_bill_number(inward_id, 'X');
      raise exception 'FAIL: bill number on an inward challan';
    exception when others then
      message := sqlerrm;
    end;
    if message <> 'Only outward challans have this.' then
      raise exception 'FAIL: inward follow-up message was: %', message;
    end if;
  end if;

  -- ── Cancelling ───────────────────────────────────────────────────────────

  return_id := challans.cancel_challan(outward2_id, ' wrong client ', true);
  select * into found_challan from challans.challans where id = outward2_id;
  if found_challan.cancelled_at is null or found_challan.cancel_reason <> 'wrong client' then
    raise exception 'FAIL: not cancelled';
  end if;
  select * into found_challan from challans.challans where id = return_id;
  if found_challan.direction <> 'inward' or found_challan.reverses_challan_id <> outward2_id
     or found_challan.challan_date <> today then
    raise exception 'FAIL: return challan wrong';
  end if;
  if (select count(*) from challans.challan_items where challan_id = return_id) <> 1 then
    raise exception 'FAIL: items not copied to the return';
  end if;
  if (select returned_by_challan_id from challans.challan_overview where id = outward2_id) <> return_id then
    raise exception 'FAIL: overview does not link the return';
  end if;

  begin
    perform challans.update_challan(outward2_id, test_address_id, false, 'x', null, null, null, one_item);
    raise exception 'FAIL: edited a cancelled challan';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'This challan is cancelled, so it can''t be changed.' then
    raise exception 'FAIL: cancelled edit message was: %', message;
  end if;

  begin
    perform challans.cancel_challan(return_id, null, true);
    raise exception 'FAIL: return asked for on an inward challan';
  exception when others then
    message := sqlerrm;
  end;
  if message <> 'Only an outward challan can have its goods brought back in.' then
    raise exception 'FAIL: inward return message was: %', message;
  end if;

  -- ── Views ────────────────────────────────────────────────────────────────

  select count(*) into row_count from challans.challan_overview where client_id = test_client_id;
  if row_count < 3 then
    raise exception 'FAIL: overview shows % challans for the client', row_count;
  end if;
  if (select item_count from challans.challan_overview where id = outward_id) <> 2 then
    raise exception 'FAIL: overview item count';
  end if;
  if (select count(*) from challans.challan_history where challan_id = outward_id and created_by_email is not null) = 0 then
    raise exception 'FAIL: history has no emails';
  end if;

  -- ── Search ───────────────────────────────────────────────────────────────

  -- Only the test client's challans, so real data can't affect the counts.
  if (select count(*) from challans.search_challans(null, array[test_client_id], null, null, null)) < 3 then
    raise exception 'FAIL: search by client';
  end if;
  if (select count(*) from challans.search_challans('sn1', array[test_client_id], null, null, null)) < 1 then
    raise exception 'FAIL: search by item serial';
  end if;
  if (select count(*) from challans.search_challans('suresh', array[test_client_id], null, null, 'outward')) <> 1 then
    raise exception 'FAIL: search by person within outward';
  end if;
  if not exists (
    select 1 from challans.search_challans(
      (select number::text from challans.challans where id = outward_id),
      array[test_client_id], null, null, 'outward')
    where id = outward_id
  ) then
    raise exception 'FAIL: search by number';
  end if;
  if (select count(*) from challans.search_challans('%', array[test_client_id], null, null, null)) <> 0 then
    raise exception 'FAIL: %% should be searched literally';
  end if;
  if (select count(*) from challans.search_challans(null, array[test_client_id], today + 1, null, null)) <> 0 then
    raise exception 'FAIL: date range';
  end if;

  -- ── Access ───────────────────────────────────────────────────────────────

  begin
    insert into challans.challans (direction, challan_date, number, client_address_version_id, handled_by_name)
    values ('outward', today, 999999, version1_id, 'x');
    raise exception 'FAIL: direct insert allowed';
  exception when insufficient_privilege then
    null;
  end;

  -- Someone without the module can't call the functions or see rows.
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  begin
    perform challans.create_challan('outward', today, test_address_id, 'x', null, null, null, one_item);
    raise exception 'FAIL: no-access user created a challan';
  exception when insufficient_privilege then
    null;
  end;
  if (select count(*) from challans.challans) <> 0 then
    raise exception 'FAIL: no-access user can see challans';
  end if;
  if (select count(*) from challans.challan_history) <> 0 then
    raise exception 'FAIL: no-access user can see history';
  end if;
  if (select count(*) from core.clients) <> 0 then
    raise exception 'FAIL: no-access user can see clients';
  end if;

  raise exception 'ALL PASSED (rolled back)';
end;
$$;
