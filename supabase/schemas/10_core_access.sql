-- core: who can sign up, who has which role, and which modules they can use.
-- Every module's row-level security builds on the helpers here.

create schema if not exists core;

-- ── Grants for the whole schema ────────────────────────────────────────────
-- Row-level security decides *which rows* a role sees; it doesn't replace
-- GRANT. Without these, every request from a signed-in user would fail with
-- "permission denied for schema core".
--
-- No `anon` grants: everything in the app needs sign-in.
grant usage on schema core to authenticated;

-- The default for everything created in core from here on: signed-in users
-- can read tables and views (row-level security narrows which rows) and call
-- functions. Writing a table is granted table by table, next to its write
-- policy, so a new table is read-only for the app unless it says otherwise.
alter default privileges in schema core grant select on tables to authenticated;
alter default privileges in schema core grant execute on functions to authenticated;

-- ── Sign-up allow-list ─────────────────────────────────────────────────────

create table core.allowed_signup_emails (
  email text primary key,
  note text,
  added_by uuid references auth.users(id),
  added_at timestamptz not null default now()
);

-- The before_user_created auth hook (wired up in config.toml): GoTrue calls it
-- for every sign-up and forwards the returned `error` to the app as-is. A
-- plain trigger raising an exception can't do that: GoTrue reports any trigger
-- failure as a generic "Database error saving new user".
create function core.check_allowed_signup(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = core, public
as $$
declare
  signup_email text := event -> 'user' ->> 'email';
begin
  if not exists (
    select 1 from core.allowed_signup_emails
    where lower(email) = lower(signup_email)
  ) then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Sign-up not permitted for this email address.'
      )
    );
  end if;

  return jsonb_build_object();
end;
$$;

-- GoTrue runs the hook as supabase_auth_admin, which needs the schema too.
-- Signed-in users must not be able to call it (the default above would let them).
grant usage on schema core to supabase_auth_admin;
grant execute on function core.check_allowed_signup(jsonb) to supabase_auth_admin;
revoke execute on function core.check_allowed_signup(jsonb) from authenticated, anon, public;

-- ── Profiles ───────────────────────────────────────────────────────────────

create table core.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  created_at timestamptz not null default now()
);

create function core.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = core, public
as $$
begin
  insert into core.profiles (id, email) values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function core.handle_new_user();

-- Only ever runs as the trigger above. Postgres checks EXECUTE when a trigger
-- is created, not when it fires, so nobody needs to call it directly.
revoke execute on function core.handle_new_user() from public, anon, authenticated;

-- ── Roles ──────────────────────────────────────────────────────────────────
-- Rows ('superadmin', 'admin', 'employee') are seeded by a migration.

create table core.roles (
  id text primary key
);

-- One role per user (user_id is the key), so changing a role is one upsert.
create table core.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id text not null references core.roles(id),
  granted_by uuid references auth.users(id),
  granted_at timestamptz not null default now(),
  primary key (user_id)
);

create function core.is_superadmin()
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select exists (
    select 1 from core.user_roles
    where user_id = auth.uid() and role_id = 'superadmin'
  );
$$;

create function core.is_admin_or_above()
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select exists (
    select 1 from core.user_roles
    where user_id = auth.uid() and role_id in ('superadmin', 'admin')
  );
$$;

-- ── Modules ────────────────────────────────────────────────────────────────
-- Rows ('attendance', 'challans') are seeded by migrations.

create table core.modules (
  id text primary key,
  name text not null,
  description text
);

create table core.module_access (
  user_id uuid not null references auth.users(id) on delete cascade,
  module_id text not null references core.modules(id),
  granted_by uuid references auth.users(id),
  granted_at timestamptz not null default now(),
  primary key (user_id, module_id)
);

-- Admins and superadmins have every module.
create function core.has_module_access(p_module text)
returns boolean
language sql
stable
security definer
set search_path = core, public
as $$
  select core.is_admin_or_above() or exists (
    select 1 from core.module_access
    where user_id = auth.uid() and module_id = p_module
  );
$$;

-- Postgres grants EXECUTE on every new function to PUBLIC. Row-level security
-- calls these as the signed-in user, so only `authenticated` keeps it. They
-- only ever answer about auth.uid() itself.
revoke execute on function core.is_superadmin() from public, anon;
revoke execute on function core.is_admin_or_above() from public, anon;
revoke execute on function core.has_module_access(text) from public, anon;
grant execute on function core.is_superadmin() to authenticated;
grant execute on function core.is_admin_or_above() to authenticated;
grant execute on function core.has_module_access(text) to authenticated;

-- Stops the calling function unless the signed-in user has the module.
-- Errcode 42501 is "insufficient privilege", which the app already shows as
-- "You don't have permission to do that."
create function core.require_module_access(p_module text)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if not core.has_module_access(p_module) then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
end;
$$;

revoke execute on function core.require_module_access(text) from public, anon, authenticated;

-- ── Row-level security ─────────────────────────────────────────────────────

alter table core.allowed_signup_emails enable row level security;
create policy allowed_signup_emails_select on core.allowed_signup_emails
  for select using (core.is_superadmin());
create policy allowed_signup_emails_write on core.allowed_signup_emails
  for all using (core.is_superadmin()) with check (core.is_superadmin());
grant insert, update, delete on core.allowed_signup_emails to authenticated;

alter table core.profiles enable row level security;
create policy profiles_select_own_or_admin on core.profiles
  for select using (id = auth.uid() or core.is_admin_or_above());

alter table core.roles enable row level security;
create policy roles_select_authenticated on core.roles
  for select using (auth.role() = 'authenticated');

alter table core.user_roles enable row level security;
create policy user_roles_select on core.user_roles
  for select using (user_id = auth.uid() or core.is_admin_or_above());
create policy user_roles_write on core.user_roles
  for all using (core.is_superadmin()) with check (core.is_superadmin());
grant insert, update, delete on core.user_roles to authenticated;

alter table core.modules enable row level security;
create policy modules_select_authenticated on core.modules
  for select using (auth.role() = 'authenticated');

alter table core.module_access enable row level security;
create policy module_access_select on core.module_access
  for select using (user_id = auth.uid() or core.is_admin_or_above());
create policy module_access_write on core.module_access
  for all using (core.is_admin_or_above()) with check (core.is_admin_or_above());
grant insert, update, delete on core.module_access to authenticated;
