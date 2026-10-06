-- Clients and their versioned addresses (core.create_client and friends).

create function tests.test_create_client_tidies_input()
returns setof text
language plpgsql
as $$
declare
  test_client_id uuid;
  version core.client_address_versions;
begin
  perform tests.act_as_challans_user();
  test_client_id := core.create_client(
    'ZZ Test   Client', 'referred by test', null, null,
    E'Line 1\r\n  Line 2  ', '07', ' 07aaccv3676j1zy ');
  select v.* into version
  from core.client_address_versions v
  join core.client_addresses a on a.id = v.address_id
  where a.client_id = test_client_id;

  return next is((select name from core.clients where id = test_client_id), 'ZZ Test Client',
    'spaces in the name are collapsed');
  return next is((select label from core.client_addresses where client_id = test_client_id), 'Main',
    'the first address is labelled Main');
  return next is(version.address, E'Line 1\nLine 2', 'address line breaks kept, spaces trimmed');
  return next is(version.gstin, '07AACCV3676J1ZY', 'GSTIN upper-cased and trimmed');
  return next is(version.name_on_challan, 'ZZ Test Client', 'name on challan defaults to the client name');
  return next is(version.version, 1, 'starts at version 1');
end;
$$;

create function tests.test_clean_text()
returns setof text
language plpgsql
as $$
begin
  return next is(core.clean_text(E'A,\rB\r\nC'), E'A,\nB\nC',
    'a lone \r (old Mac line break) becomes a line break');
  return next is(core.clean_text(E'  a \t  b  '), 'a b', 'runs of spaces and tabs collapse');
  return next is(core.clean_text(E' \n '), null, 'blank becomes null');
end;
$$;

create function tests.test_client_name_rules()
returns setof text
language plpgsql
as $$
declare
  other_id uuid;
begin
  perform tests.act_as_challans_user();
  perform tests.new_address('ZZ Test Client');
  other_id := core.create_client('ZZ Other', null, null, null, 'x', '07', null);

  return next throws_ok(
    $sql$ select core.create_client('zz test client', null, null, null, 'x', '07', null) $sql$,
    'P0001', 'A client named "zz test client" already exists.',
    'a duplicate name is refused, ignoring case');
  return next throws_ok(
    $sql$ select core.create_client('  ', null, null, null, 'x', '07', null) $sql$,
    'P0001', 'Enter the client''s name.', 'a blank name is refused');
  return next throws_ok(
    format($sql$ select core.update_client(%L, 'ZZ TEST CLIENT', null) $sql$, other_id),
    'P0001', 'A client named "ZZ TEST CLIENT" already exists.',
    'renaming onto another client''s name is refused');
  return next throws_ok(
    format($sql$ select core.update_client(%L, ' ', null) $sql$, other_id),
    'P0001', 'Enter the client''s name.', 'renaming to blank is refused');

  perform core.update_client(other_id, 'zz other', ' a note ');
  return next is((select name || '|' || notes from core.clients where id = other_id),
    'zz other|a note', 'a client can change the case of its own name');
end;
$$;

create function tests.test_gstin_shape()
returns setof text
language plpgsql
as $$
begin
  perform tests.act_as_challans_user();
  return next throws_like(
    $sql$ select core.create_client('ZZ Bad', null, null, null, 'x', '07', 'NOT AVAILABLE') $sql$,
    'GSTIN "NOTAVAILABLE" isn''t valid%', 'a badly shaped GSTIN is refused');
  return next lives_ok(
    $sql$ select core.create_client('ZZ Other State', null, null, null, 'x', '07', '06AACCV3676J1ZY') $sql$,
    'a GSTIN from another state is allowed');
end;
$$;

create function tests.test_address_versions()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_client_id uuid;
  first_version_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select a.client_id into test_client_id from core.client_addresses a where a.id = test_address_id;
  select id into first_version_id from core.client_address_versions where address_id = test_address_id;

  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', 'Line 1 fixed', '07', null);
  return next is((select count(*)::int from core.client_address_versions where address_id = test_address_id), 1,
    'editing an address no challan uses changes it in place');

  perform core.save_client_address(test_address_id, test_client_id, 'Head office', 'ZZ TEST CLIENT', 'Line 1 fixed', '07', null);
  return next is((select label from core.client_addresses where id = test_address_id), 'Head office',
    'the label can change on its own');

  perform tests.outward(test_address_id);
  return next isnt((select locked_at from core.client_address_versions where id = first_version_id), null,
    'a challan locks the version it prints');

  perform core.save_client_address(test_address_id, test_client_id, 'Head office', 'ZZ TEST CLIENT', 'Moved', '07', null);
  return next is((select max(version) from core.client_address_versions where address_id = test_address_id), 2,
    'editing a used address adds version 2');
  return next is((select address from core.client_address_versions where id = first_version_id), 'Line 1 fixed',
    'the used version is unchanged');

  perform core.save_client_address(test_address_id, test_client_id, 'Head office', 'ZZ TEST CLIENT', 'Moved', '07', null);
  return next is((select max(version) from core.client_address_versions where address_id = test_address_id), 2,
    'saving with nothing changed adds no version');

  perform tests.act_as_owner();
  return next throws_ok(
    format($sql$ update core.client_address_versions set address = 'x' where id = %L $sql$, first_version_id),
    'P0001', 'This address version is used by a challan and can''t be changed.',
    'even the database owner can''t change a used version');
end;
$$;

create function tests.test_save_client_address_rules()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_client_id uuid;
  second_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select a.client_id into test_client_id from core.client_addresses a where a.id = test_address_id;

  return next throws_ok(
    format($sql$ select core.save_client_address(null, %L, ' ', 'N', 'A', '07', null) $sql$, test_client_id),
    'P0001', 'Enter a label for this address, like "Head office".', 'a blank label is refused');
  return next throws_ok(
    format($sql$ select core.save_client_address(null, %L, 'L', ' ', 'A', '07', null) $sql$, test_client_id),
    'P0001', 'Enter the name to print on challans.', 'a blank printed name is refused');
  return next throws_ok(
    format($sql$ select core.save_client_address(null, %L, 'L', 'N', ' ', '07', null) $sql$, test_client_id),
    'P0001', 'Enter the address.', 'a blank address is refused');
  return next throws_ok(
    format($sql$ select core.save_client_address(%L, %L, 'L', 'N', 'A', '07', null) $sql$,
      gen_random_uuid(), test_client_id),
    'P0001', 'That address no longer exists. It may have been deleted.',
    'saving an address that''s gone is refused');

  second_id := core.save_client_address(null, test_client_id, 'Branch', 'ZZ BRANCH', 'Somewhere', '06', null);
  return next is((select count(*)::int from core.client_addresses where client_id = test_client_id), 2,
    'a second address can be added');

  perform core.set_client_address_archived(second_id, true);
  return next isnt((select archived_at from core.client_addresses where id = second_id), null,
    'an address can be archived');
  perform core.set_client_address_archived(second_id, false);
  return next is((select archived_at from core.client_addresses where id = second_id), null,
    'and unarchived');

  perform core.delete_client_address(second_id);
  return next is((select count(*)::int from core.client_addresses where client_id = test_client_id), 1,
    'an unused address can be deleted');
  return next throws_ok(
    format($sql$ select core.delete_client_address(%L) $sql$, test_address_id),
    'P0001', 'A client needs at least one address.', 'the last address can''t be deleted');
end;
$$;

create function tests.test_deleting_and_archiving_clients()
returns setof text
language plpgsql
as $$
declare
  used_address_id uuid;
  used_client_id uuid;
  unused_client_id uuid;
begin
  perform tests.act_as_challans_user();
  used_address_id := tests.new_address('ZZ Used');
  select client_id into used_client_id from core.client_addresses where id = used_address_id;
  perform tests.outward(used_address_id);
  unused_client_id := core.create_client('ZZ Unused', null, null, null, 'x', '07', null);

  return next throws_ok(
    format($sql$ select core.delete_client(%L) $sql$, used_client_id),
    'P0001', 'This client is on challans, so it can''t be deleted. Archive it instead.',
    'a client on challans can''t be deleted');
  return next throws_ok(
    format($sql$ select core.delete_client_address(%L) $sql$, used_address_id),
    'P0001', 'This address is on challans, so it can''t be deleted. Archive it instead.',
    'an address on challans can''t be deleted');

  perform core.delete_client(unused_client_id);
  return next is((select count(*)::int from core.clients where id = unused_client_id), 0,
    'a client on no challans can be deleted');

  perform core.set_client_archived(used_client_id, true);
  return next isnt((select archived_at from core.clients where id = used_client_id), null,
    'a client can be archived');
  perform core.set_client_archived(used_client_id, false);
  return next is((select archived_at from core.clients where id = used_client_id), null,
    'and unarchived');
end;
$$;

create function tests.test_current_client_addresses_view()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
  test_client_id uuid;
begin
  perform tests.act_as_challans_user();
  test_address_id := tests.new_address();
  select a.client_id into test_client_id from core.client_addresses a where a.id = test_address_id;
  perform tests.outward(test_address_id);
  perform core.save_client_address(test_address_id, test_client_id, 'Main', 'ZZ TEST CLIENT', 'Moved', '07', null);

  return next is(
    (select address from core.current_client_addresses where address_id = test_address_id), 'Moved',
    'shows each address''s newest version');
end;
$$;
