-- Three data-model fixes from the code review.

-- 1. Salary is always whole rupees. Any existing paise are rounded away.
-- (Payments in employee_ledger_entries keep `numeric`: those can have paise.)
alter table core.employees
  alter column salary type integer using round(salary)::integer;

-- 2. Creating an employee and recording their "joined" event used to be two
-- separate requests from the app, so a failure in between left an employee
-- with no history. Every PostgREST request is its own transaction, so the
-- only way to make both inserts all-or-nothing is to do them inside one
-- database function: if the second insert fails, Postgres undoes the first.
create function core.create_employee(
  p_name text,
  p_color integer,
  p_salary integer,
  p_notes text,
  p_joined_on date
)
returns core.employees
language plpgsql
-- Runs as the signed-in user, so the existing RLS policies on employees and
-- employee_events still decide whether they're allowed to do this.
security invoker
set search_path = ''
as $$
declare
  new_employee core.employees;
begin
  insert into core.employees (name, color, salary, notes)
  values (p_name, p_color, p_salary, p_notes)
  returning * into new_employee;

  insert into core.employee_events (employee_id, event_type, event_date, created_by)
  values (new_employee.id, 'joined', p_joined_on, auth.uid());

  return new_employee;
end;
$$;

-- Postgres grants EXECUTE to PUBLIC on every new function; only signed-in
-- users should be able to call this.
revoke execute on function core.create_employee(text, integer, integer, text, date) from public, anon;
grant execute on function core.create_employee(text, integer, integer, text, date) to authenticated;

-- 3. A user has exactly one role. The old key, (user_id, role_id), allowed
-- several, and changing a role took two requests (revoke, then grant) that
-- could half-fail and leave the user with no role at all. With user_id as
-- the key, changing a role is a single upsert.

-- Keep only each user's highest role, in case anyone has more than one.
-- `distinct on (user_id)` keeps the first row per user in the given order,
-- so ordering by rank keeps the best one.
delete from core.user_roles
where (user_id, role_id) not in (
  select distinct on (user_id) user_id, role_id
  from core.user_roles
  order by user_id,
    case role_id
      when 'superadmin' then 1
      when 'admin' then 2
      else 3
    end
);

alter table core.user_roles drop constraint user_roles_pkey;
alter table core.user_roles add primary key (user_id);

-- 4. Names and labels people type are now saved title-cased by the app
-- ("abcd" → "Abcd"). Bring existing rows in line, the same way: capitalise
-- the first letter of each word, leave the rest of the word as it is (so
-- "McDonald" stays "McDonald"), and collapse repeated spaces.
-- How it works, for one name: regexp_split_to_table splits it into words
-- (one row per word, numbered by `with ordinality` to keep their order),
-- upper(left(word, 1)) || substr(word, 2) capitalises each, and string_agg
-- glues them back together with single spaces.
update core.employees e
set name = (
  select string_agg(upper(left(word, 1)) || substr(word, 2), ' ' order by position)
  from regexp_split_to_table(trim(e.name), '\s+') with ordinality as words(word, position)
)
-- A blank name would come out NULL, which the column doesn't allow.
where trim(e.name) <> '';

update attendance.status_types s
set label = (
  select string_agg(upper(left(word, 1)) || substr(word, 2), ' ' order by position)
  from regexp_split_to_table(trim(s.label), '\s+') with ordinality as words(word, position)
)
where trim(s.label) <> '';
