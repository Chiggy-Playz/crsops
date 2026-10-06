-- Clients: the companies challans are made out to. They live in `core` (like
-- employees) because more than one module will use them — challans now,
-- assets later. Design: docs/superpowers/specs/2026-10-06-clients-and-challans-design.md
--
-- Shape:
--   clients                  one per company
--   client_addresses         one per site/branch of that company
--   client_address_versions  what gets printed on a challan for that site
--
-- Why versions: a challan must keep printing the address it was made with,
-- even after the client moves. So a challan points at a *version*, and once
-- any challan uses a version (locked_at is set) it can never change; editing
-- that address adds a new version instead. A version nobody uses yet is just
-- edited in place, so fixing a typo doesn't pile up versions.
--
-- The app can only read these tables. Every change goes through the
-- functions at the bottom, which check access and keep the rules.

-- ── Module registration ────────────────────────────────────────────────────

-- Clients come with the challans module, so the same access grant covers both.
insert into core.modules (id, name, description)
  values ('challans', 'Challans', 'Delivery challans and the clients they go to');

-- ── Indian states (GST state codes) ────────────────────────────────────────

create table core.indian_states (
  code text primary key check (code ~ '^[0-9]{2}$'),
  name text not null unique
);

-- The codes GST uses today. 25 (Daman & Diu) merged into 26 in 2020 and 28
-- (undivided Andhra Pradesh) was replaced by 37, so neither is listed.
insert into core.indian_states (code, name) values
  ('01', 'Jammu and Kashmir'),
  ('02', 'Himachal Pradesh'),
  ('03', 'Punjab'),
  ('04', 'Chandigarh'),
  ('05', 'Uttarakhand'),
  ('06', 'Haryana'),
  ('07', 'Delhi'),
  ('08', 'Rajasthan'),
  ('09', 'Uttar Pradesh'),
  ('10', 'Bihar'),
  ('11', 'Sikkim'),
  ('12', 'Arunachal Pradesh'),
  ('13', 'Nagaland'),
  ('14', 'Manipur'),
  ('15', 'Mizoram'),
  ('16', 'Tripura'),
  ('17', 'Meghalaya'),
  ('18', 'Assam'),
  ('19', 'West Bengal'),
  ('20', 'Jharkhand'),
  ('21', 'Odisha'),
  ('22', 'Chhattisgarh'),
  ('23', 'Madhya Pradesh'),
  ('24', 'Gujarat'),
  ('26', 'Dadra and Nagar Haveli and Daman and Diu'),
  ('27', 'Maharashtra'),
  ('29', 'Karnataka'),
  ('30', 'Goa'),
  ('31', 'Lakshadweep'),
  ('32', 'Kerala'),
  ('33', 'Tamil Nadu'),
  ('34', 'Puducherry'),
  ('35', 'Andaman and Nicobar Islands'),
  ('36', 'Telangana'),
  ('37', 'Andhra Pradesh'),
  ('38', 'Ladakh');

-- ── Tables ─────────────────────────────────────────────────────────────────

create table core.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

-- Unique ignoring case, so "Vega Corporate" and "VEGA CORPORATE" can't both exist.
create unique index clients_name_key on core.clients (lower(name));

create table core.client_addresses (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references core.clients(id) on delete cascade,
  -- Internal only, never printed: "Sector 4", "Head office".
  label text not null check (btrim(label) <> ''),
  archived_at timestamptz,
  created_at timestamptz not null default now()
);

create index client_addresses_client_id_idx on core.client_addresses (client_id);

create table core.client_address_versions (
  id uuid primary key default gen_random_uuid(),
  address_id uuid not null references core.client_addresses(id) on delete cascade,
  version integer not null check (version > 0),
  name_on_challan text not null check (btrim(name_on_challan) <> ''),
  address text not null check (btrim(address) <> ''),
  state_code text not null references core.indian_states(code),
  -- Only the shape is checked. Its first two digits are deliberately NOT
  -- required to match state_code: the state is where the goods go, which can
  -- differ from where the client is registered.
  gstin text check (gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'),
  -- Set the first time a challan uses this version. From then on the row is
  -- frozen (see the trigger below).
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  unique (address_id, version)
);

-- A version a challan has used must print the same forever.
create function core.prevent_locked_version_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.locked_at is not null then
    raise exception 'This address version is used by a challan and can''t be changed.';
  end if;
  return new;
end;
$$;

create trigger client_address_versions_frozen
  before update on core.client_address_versions
  for each row execute function core.prevent_locked_version_change();

-- Each address with its newest version: what new challans will print.
-- security_invoker so the tables' own row-level security applies to readers.
create view core.current_client_addresses
with (security_invoker = true) as
select distinct on (a.id)
  a.id as address_id,
  a.client_id,
  a.label,
  a.archived_at,
  a.created_at,
  v.id as version_id,
  v.version,
  v.name_on_challan,
  v.address,
  v.state_code,
  s.name as state_name,
  v.gstin
from core.client_addresses a
join core.client_address_versions v on v.address_id = a.id
join core.indian_states s on s.code = v.state_code
order by a.id, v.version desc;

-- ── Access ─────────────────────────────────────────────────────────────────

alter table core.indian_states enable row level security;
create policy indian_states_select on core.indian_states
  for select using (auth.role() = 'authenticated');

alter table core.clients enable row level security;
create policy clients_select on core.clients
  for select using (core.has_module_access('challans'));

alter table core.client_addresses enable row level security;
create policy client_addresses_select on core.client_addresses
  for select using (core.has_module_access('challans'));

alter table core.client_address_versions enable row level security;
create policy client_address_versions_select on core.client_address_versions
  for select using (core.has_module_access('challans'));

-- `core` gives signed-in users insert/update/delete on new tables by default
-- (see the grant_core_schema_privileges migration). Take that back here: the
-- functions below are the only way to change these tables.
revoke insert, update, delete on core.indian_states from authenticated;
revoke insert, update, delete on core.clients from authenticated;
revoke insert, update, delete on core.client_addresses from authenticated;
revoke insert, update, delete on core.client_address_versions from authenticated;

-- ── Helpers ────────────────────────────────────────────────────────────────

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

-- Tidies typed text: drops Windows line-ending \r characters, collapses runs
-- of spaces/tabs, removes spaces around line breaks, trims the ends. Line
-- breaks themselves stay (addresses are multi-line). Blank becomes null.
create function core.clean_text(p_value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := p_value;
begin
  cleaned := replace(cleaned, E'\r', '');
  cleaned := regexp_replace(cleaned, '[ \t]+', ' ', 'g');
  cleaned := regexp_replace(cleaned, ' ?\n ?', E'\n', 'g');
  cleaned := btrim(cleaned, E' \n');
  return nullif(cleaned, '');
end;
$$;

-- Upper-cases and strips spaces from a GSTIN, null if blank, and fails with
-- a readable message if it isn't a valid shape.
create function core.clean_gstin(p_value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := nullif(upper(regexp_replace(coalesce(p_value, ''), '\s', '', 'g')), '');
begin
  if cleaned is not null
     and cleaned !~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$' then
    raise exception 'GSTIN "%" isn''t valid. It should be 15 characters, like 07AAACV3676J1ZY.', cleaned;
  end if;
  return cleaned;
end;
$$;

-- ── Functions the app calls ────────────────────────────────────────────────
-- All are security definer (run with the owner's rights, since the app can't
-- write these tables itself) and start by checking module access.

-- Creates a client together with its first address: a client with no
-- address can't be put on a challan, so the two are one step.
create function core.create_client(
  p_name text,
  p_notes text,
  p_label text,
  p_name_on_challan text,
  p_address text,
  p_state_code text,
  p_gstin text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_name text := core.clean_text(p_name);
  new_client_id uuid;
  new_address_id uuid;
begin
  perform core.require_module_access('challans');

  if clean_name is null then
    raise exception 'Enter the client''s name.';
  end if;
  if exists (select 1 from core.clients where lower(name) = lower(clean_name)) then
    raise exception 'A client named "%" already exists.', clean_name;
  end if;

  insert into core.clients (name, notes, created_by)
  values (clean_name, core.clean_text(p_notes), auth.uid())
  returning id into new_client_id;

  insert into core.client_addresses (client_id, label)
  values (new_client_id, coalesce(core.clean_text(p_label), 'Main'))
  returning id into new_address_id;

  insert into core.client_address_versions
    (address_id, version, name_on_challan, address, state_code, gstin, created_by)
  values (
    new_address_id,
    1,
    coalesce(core.clean_text(p_name_on_challan), clean_name),
    core.clean_text(p_address),
    p_state_code,
    core.clean_gstin(p_gstin),
    auth.uid()
  );

  return new_client_id;
end;
$$;

create function core.update_client(p_client_id uuid, p_name text, p_notes text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_name text := core.clean_text(p_name);
begin
  perform core.require_module_access('challans');

  if clean_name is null then
    raise exception 'Enter the client''s name.';
  end if;
  if exists (
    select 1 from core.clients
    where lower(name) = lower(clean_name) and id <> p_client_id
  ) then
    raise exception 'A client named "%" already exists.', clean_name;
  end if;

  update core.clients
  set name = clean_name, notes = core.clean_text(p_notes)
  where id = p_client_id;
end;
$$;

-- Archived clients stay on old challans but are hidden when picking a client.
create function core.set_client_archived(p_client_id uuid, p_archived boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform core.require_module_access('challans');

  update core.clients
  set archived_at = case when p_archived then now() end
  where id = p_client_id;
end;
$$;

-- Only for mistakes: a client any challan uses can't be deleted (archive it).
create function core.delete_client(p_client_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform core.require_module_access('challans');

  if exists (
    select 1
    from core.client_address_versions v
    join core.client_addresses a on a.id = v.address_id
    where a.client_id = p_client_id and v.locked_at is not null
  ) then
    raise exception 'This client is on challans, so it can''t be deleted. Archive it instead.';
  end if;

  delete from core.clients where id = p_client_id;
end;
$$;

-- Adds an address (p_address_id null) or saves changes to one. When the
-- printed details change: if a challan already uses the current version, a
-- new version is added; otherwise the current version is edited in place.
-- Returns the address id.
create function core.save_client_address(
  p_address_id uuid,
  p_client_id uuid,
  p_label text,
  p_name_on_challan text,
  p_address text,
  p_state_code text,
  p_gstin text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_label text := core.clean_text(p_label);
  clean_name text := core.clean_text(p_name_on_challan);
  clean_address text := core.clean_text(p_address);
  clean_gstin text := core.clean_gstin(p_gstin);
  current_version core.client_address_versions;
  saved_address_id uuid := p_address_id;
begin
  perform core.require_module_access('challans');

  if clean_label is null then
    raise exception 'Enter a label for this address, like "Head office".';
  end if;
  if clean_name is null then
    raise exception 'Enter the name to print on challans.';
  end if;
  if clean_address is null then
    raise exception 'Enter the address.';
  end if;

  if saved_address_id is null then
    insert into core.client_addresses (client_id, label)
    values (p_client_id, clean_label)
    returning id into saved_address_id;

    insert into core.client_address_versions
      (address_id, version, name_on_challan, address, state_code, gstin, created_by)
    values (saved_address_id, 1, clean_name, clean_address, p_state_code, clean_gstin, auth.uid());

    return saved_address_id;
  end if;

  update core.client_addresses set label = clean_label where id = saved_address_id;

  -- `for update` holds the row until this transaction ends, so two people
  -- saving the same address at once can't both add the same version number.
  select * into current_version
  from core.client_address_versions
  where address_id = saved_address_id
  order by version desc
  limit 1
  for update;

  if current_version.id is null then
    raise exception 'That address no longer exists. It may have been deleted.';
  end if;

  -- Nothing printed changed (maybe only the label did): no new version.
  if current_version.name_on_challan = clean_name
     and current_version.address = clean_address
     and current_version.state_code = p_state_code
     and current_version.gstin is not distinct from clean_gstin then
    return saved_address_id;
  end if;

  if current_version.locked_at is null then
    update core.client_address_versions
    set name_on_challan = clean_name,
        address = clean_address,
        state_code = p_state_code,
        gstin = clean_gstin
    where id = current_version.id;
  else
    insert into core.client_address_versions
      (address_id, version, name_on_challan, address, state_code, gstin, created_by)
    values (
      saved_address_id,
      current_version.version + 1,
      clean_name,
      clean_address,
      p_state_code,
      clean_gstin,
      auth.uid()
    );
  end if;

  return saved_address_id;
end;
$$;

create function core.set_client_address_archived(p_address_id uuid, p_archived boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform core.require_module_access('challans');

  update core.client_addresses
  set archived_at = case when p_archived then now() end
  where id = p_address_id;
end;
$$;

-- Only for mistakes, like delete_client. The client's last address can't go:
-- a client needs one to be put on a challan.
create function core.delete_client_address(p_address_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_id uuid;
begin
  perform core.require_module_access('challans');

  select client_id into owner_id from core.client_addresses where id = p_address_id;

  if exists (
    select 1 from core.client_address_versions
    where address_id = p_address_id and locked_at is not null
  ) then
    raise exception 'This address is on challans, so it can''t be deleted. Archive it instead.';
  end if;
  if (select count(*) from core.client_addresses where client_id = owner_id) <= 1 then
    raise exception 'A client needs at least one address.';
  end if;

  delete from core.client_addresses where id = p_address_id;
end;
$$;

-- Postgres grants EXECUTE to PUBLIC on every new function. Only signed-in
-- users may call the app-facing ones; the helpers and the trigger function
-- are only called from other functions.
revoke execute on function core.create_client(text, text, text, text, text, text, text) from public, anon;
revoke execute on function core.update_client(uuid, text, text) from public, anon;
revoke execute on function core.set_client_archived(uuid, boolean) from public, anon;
revoke execute on function core.delete_client(uuid) from public, anon;
revoke execute on function core.save_client_address(uuid, uuid, text, text, text, text, text) from public, anon;
revoke execute on function core.set_client_address_archived(uuid, boolean) from public, anon;
revoke execute on function core.delete_client_address(uuid) from public, anon;
revoke execute on function core.require_module_access(text) from public, anon, authenticated;
revoke execute on function core.prevent_locked_version_change() from public, anon, authenticated;

grant execute on function core.create_client(text, text, text, text, text, text, text) to authenticated;
grant execute on function core.update_client(uuid, text, text) to authenticated;
grant execute on function core.set_client_archived(uuid, boolean) to authenticated;
grant execute on function core.delete_client(uuid) to authenticated;
grant execute on function core.save_client_address(uuid, uuid, text, text, text, text, text) to authenticated;
grant execute on function core.set_client_address_archived(uuid, boolean) to authenticated;
grant execute on function core.delete_client_address(uuid) to authenticated;
