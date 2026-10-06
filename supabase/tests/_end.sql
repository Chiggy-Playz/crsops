-- Closes a test run (run.sh puts this last): lints, runs every test_
-- function, reports coverage, then rolls everything back.

-- The app's plpgsql functions, with the table each trigger function is
-- attached to (plpgsql_check needs it to know what NEW and OLD are).
create function tests.app_functions()
returns table (function_id oid, trigger_table oid, label text)
language sql
as $$
  select
    p.oid,
    (select t.tgrelid from pg_trigger t where t.tgfoid = p.oid limit 1),
    n.nspname || '.' || p.proname
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join pg_language l on l.oid = p.prolang
  where n.nspname in ('core', 'attendance', 'challans')
    and l.lanname = 'plpgsql'
  order by 3;
$$;

-- plpgsql_check reads each function without running it, like flutter
-- analyze: wrong column names, type mismatches, unused variables and so on.
create function tests.test_lint()
returns setof text
language plpgsql
as $$
declare
  fn record;
  problems text[];
begin
  for fn in select * from tests.app_functions() loop
    select coalesce(array_agg(
      coalesce('line ' || r.lineno || ': ', '') || r.level || ': ' || r.message
      order by r.lineno), '{}')
    into problems
    from extensions.plpgsql_check_function_tb(
      fn.function_id, coalesce(fn.trigger_table, 0),
      fatal_errors => false, extra_warnings => true) r
    -- Known and harmless: `changes jsonb := '{}'` (an untyped literal). Add
    -- ::jsonb next time update_challan changes, then delete this exception.
    where not (fn.label = 'challans.update_challan'
               and r.detail = 'cast "text" value to "jsonb" type');
    return next is(problems, '{}', fn.label || ' has no lint problems');
  end loop;
end;
$$;

-- Turn on the profiler before the tests run, so coverage can be reported.
-- If it can't run here, the tests still do.
create temp table coverage_status (message text);
do $$
begin
  perform extensions.plpgsql_check_profiler(true);
exception when others then
  insert into coverage_status values (sqlerrm);
end;
$$;

create temp table tap_output (n serial, line text);
insert into tap_output (line)
select * from runtests('tests'::name, '^test_');

-- Coverage: the share of each function's statements and branches the tests
-- ran. Only plpgsql functions can be measured; SQL functions and views can't.
insert into tap_output (line)
select '# coverage unavailable: ' || message from coverage_status;

insert into tap_output (line)
select '# coverage ' || rpad(fn.label, 40)
  || lpad(round(100 * extensions.plpgsql_coverage_statements(fn.function_id))::text, 4)
  || '% statements'
  || lpad(round(100 * extensions.plpgsql_coverage_branches(fn.function_id))::text, 5)
  || '% branches'
from tests.app_functions() fn
where not exists (select 1 from coverage_status);

select line from tap_output order by n;

rollback;
