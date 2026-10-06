-- Table grants: what signed-in users may write before row-level security has
-- its say.

create function tests.test_new_tables_are_read_only()
returns setof text
language plpgsql
as $$
begin
  create table core.zz_new_table (id int);
  create table attendance.zz_new_table (id int);
  create table challans.zz_new_table (id int);

  return next ok(has_table_privilege('authenticated', 'core.zz_new_table', 'select'),
    'a new core table can be read');
  return next ok(not has_table_privilege('authenticated', 'core.zz_new_table', 'insert, update, delete'),
    'but not written');
  return next ok(has_table_privilege('authenticated', 'attendance.zz_new_table', 'select'),
    'a new attendance table can be read');
  return next ok(not has_table_privilege('authenticated', 'attendance.zz_new_table', 'insert, update, delete'),
    'but not written');
  return next ok(not has_table_privilege('authenticated', 'challans.zz_new_table', 'select, insert, update, delete'),
    'a new challans table isn''t even readable until granted');
end;
$$;

-- The tables the app writes to directly. Row-level security decides who.
create function tests.test_app_written_tables_keep_their_grants()
returns setof text
language plpgsql
as $$
declare
  writable constant text[] := array[
    'core.allowed_signup_emails insert, delete',
    'core.user_roles insert, update, delete',
    'core.module_access insert, update, delete',
    'core.employees insert, update, delete',
    'core.employee_events insert, update, delete',
    'core.employee_ledger_entries insert, update, delete',
    'core.event_types insert, update',
    'attendance.attendance_days insert, update, delete',
    'attendance.shift_defaults insert',
    'attendance.status_types insert, update'
  ];
  entry text;
  table_name text;
  privileges text;
  privilege text;
begin
  foreach entry in array writable loop
    table_name := split_part(entry, ' ', 1);
    privileges := substr(entry, length(table_name) + 2);
    foreach privilege in array string_to_array(privileges, ', ') loop
      return next ok(has_table_privilege('authenticated', table_name, privilege),
        table_name || ' allows ' || privilege);
    end loop;
  end loop;
end;
$$;
