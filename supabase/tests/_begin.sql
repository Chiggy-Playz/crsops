-- Opens a test run (run.sh puts this first). Everything up to the rollback
-- at the end of _end.sql is one transaction, so nothing a test does, nor the
-- `tests` schema itself, is left behind in the database.
begin;

-- pgTAP's own functions call each other by bare name.
set local search_path = public, extensions;

create schema tests;
-- Tests switch to the app's database role part-way through, and still need
-- the helpers below.
grant usage on schema tests to authenticated, anon;

-- ── Helpers ────────────────────────────────────────────────────────────────
-- Functions in `tests` that don't start with test_ are helpers: runtests()
-- only runs the test_ ones.

-- A throwaway signed-in user: a row in auth.users (which also makes their
-- profile), an optional role ('admin', 'superadmin', 'employee') and module
-- access. Call it before act_as: only the runner's own role can do this.
create function tests.create_user(
  p_role text default null,
  p_modules text[] default '{}'
)
returns uuid
language plpgsql
as $$
declare
  new_id uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, aud, role)
  values (new_id, 'test-' || new_id || '@test.invalid', 'authenticated', 'authenticated');
  if p_role is not null then
    insert into core.user_roles (user_id, role_id) values (new_id, p_role);
  end if;
  insert into core.module_access (user_id, module_id)
  select new_id, unnest(p_modules);
  return new_id;
end;
$$;

-- From here on, act as this user: the same JWT claims and database role
-- that PostgREST gives a request from the app.
create function tests.act_as(p_user_id uuid)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user_id, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

-- Back to the runner's own role, which sees past row-level security.
create function tests.act_as_owner()
returns void
language plpgsql
as $$
begin
  reset role;
end;
$$;

-- challans.today() and financial_year_of() aren't callable by the app's
-- role, but tests acting as a user need them.
create function tests.today()
returns date
language sql
security definer
set search_path = ''
as $$ select challans.today() $$;

create function tests.financial_year(p_date date)
returns smallint
language sql
security definer
set search_path = ''
as $$ select challans.financial_year_of(p_date) $$;

-- A user with challans access who isn't an admin, already acted as.
create function tests.act_as_challans_user()
returns uuid
language plpgsql
as $$
declare
  new_user_id uuid := tests.create_user(null, '{challans}');
begin
  perform tests.act_as(new_user_id);
  return new_user_id;
end;
$$;

-- A client with one address, made through core.create_client. Returns the
-- address id. Needs a challans user (act_as_challans_user first).
create function tests.new_address(p_client_name text default 'ZZ Test Client')
returns uuid
language plpgsql
as $$
declare
  new_client_id uuid := core.create_client(p_client_name, null, null, null, 'Line 1', '07', null);
begin
  return (select a.id from core.client_addresses a where a.client_id = new_client_id);
end;
$$;

create function tests.one_item()
returns jsonb
language sql
as $$ select '[{"description":"DELL LAPTOP","serial":"SN1","quantity":2,"unit":"set"}]'::jsonb $$;

-- An outward challan for the address, dated today unless given.
create function tests.outward(
  p_address_id uuid,
  p_date date default null,
  p_items jsonb default null
)
returns uuid
language sql
as $$
  select challans.create_challan(
    'outward', coalesce(p_date, tests.today()), p_address_id, 'ramesh',
    null, null, null, coalesce(p_items, tests.one_item()));
$$;

create function tests.inward(p_address_id uuid, p_date date default null)
returns uuid
language sql
as $$
  select challans.create_challan(
    'inward', coalesce(p_date, tests.today()), p_address_id, 'suresh',
    null, null, null, tests.one_item());
$$;
