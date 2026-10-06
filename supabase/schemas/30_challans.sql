-- Challans: delivery challans going out to clients (outward) and coming back
-- in (inward). Design: docs/superpowers/specs/2026-10-06-clients-and-challans-design.md
--
-- Shape:
--   challans        one row per challan, both directions
--   challan_items   the lines printed on it
--   challan_events  append-only history: created, edited, cancelled, ...
--
-- Like clients, the app can only read these tables. Every change goes through
-- the functions below, which check access, keep the numbering and date rules,
-- and write the history row in the same transaction.

create schema if not exists challans;

-- ── Helpers ────────────────────────────────────────────────────────────────

-- The financial year a date falls in, by its starting year: April 2026 to
-- March 2027 is 2026.
create function challans.financial_year_of(p_date date)
returns smallint
language sql
immutable
set search_path = ''
as $$
  select (extract(year from p_date)::int
          - case when extract(month from p_date) < 4 then 1 else 0 end)::smallint;
$$;

-- "2026-27", as printed after the challan number.
create function challans.financial_year_label(p_year smallint)
returns text
language sql
immutable
set search_path = ''
as $$
  select p_year::text || '-' || lpad(((p_year + 1) % 100)::text, 2, '0');
$$;

-- Today in India. now()::date would be the server's (UTC) date, which is
-- still yesterday until 5:30 in the morning here.
create function challans.today()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'Asia/Kolkata')::date;
$$;

-- ── Tables ─────────────────────────────────────────────────────────────────

create table challans.challans (
  id uuid primary key default gen_random_uuid(),
  direction text not null check (direction in ('outward', 'inward')),
  challan_date date not null,
  -- Worked out from the date, so the two can never disagree.
  financial_year smallint not null generated always as (
    (extract(year from challan_date)::int
     - case when extract(month from challan_date) < 4 then 1 else 0 end)::smallint
  ) stored,
  number integer not null check (number > 0),
  -- The exact client details printed (see the clients migration). Creating a
  -- challan locks this version so it never changes.
  client_address_version_id uuid not null references core.client_address_versions(id),
  -- Who delivered it (outward) or received it (inward). The name is what's
  -- printed; the employee link is filled in when the name is an employee's.
  handled_by_name text not null check (btrim(handled_by_name) <> ''),
  handled_by_employee_id uuid references core.employees(id) on delete set null,
  vehicle_number text,
  -- "The value of the above materials does not exceed ₹…", whole rupees.
  declared_value integer check (declared_value > 0),
  notes text,

  -- Follow-ups, outward only.
  bill_number text,
  received_on date,       -- the day the signed copy came back
  digitally_signed boolean not null default false,

  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  cancel_reason text,
  -- On an inward challan made by cancelling an outward one: that outward one.
  reverses_challan_id uuid unique references challans.challans(id),

  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),

  -- Numbers run separately for each direction and financial year.
  unique (direction, financial_year, number),
  constraint inward_has_no_follow_ups check (
    direction = 'outward'
    or (bill_number is null and received_on is null and not digitally_signed)
  ),
  constraint only_inward_reverses check (
    reverses_challan_id is null or direction = 'inward'
  )
);

create index challans_list_idx
  on challans.challans (direction, financial_year, number desc);
create index challans_address_version_idx
  on challans.challans (client_address_version_id);

create table challans.challan_items (
  id uuid primary key default gen_random_uuid(),
  challan_id uuid not null references challans.challans(id) on delete cascade,
  position smallint not null check (position > 0),
  description text not null check (btrim(description) <> ''),
  additional_description text,
  serial text,
  quantity integer not null check (quantity > 0),
  unit text,
  unique (challan_id, position)
);

create table challans.challan_events (
  id bigint generated always as identity primary key,
  challan_id uuid not null references challans.challans(id) on delete cascade,
  event_type text not null check (event_type in (
    'created', 'edited', 'cancelled', 'received', 'bill_number', 'digitally_signed'
  )),
  -- What changed, as {"field": {"from": ..., "to": ...}}.
  changes jsonb not null default '{}',
  note text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create index challan_events_challan_id_idx on challans.challan_events (challan_id);

-- ── Views ──────────────────────────────────────────────────────────────────
-- security_invoker so the tables' own row-level security applies to readers.

-- Each challan with the client details it prints, its item totals, and the
-- challan linked to it by a cancellation. Lists and the detail page read this.
create view challans.challan_overview
with (security_invoker = true) as
select
  c.id,
  c.direction,
  c.financial_year,
  c.number,
  c.challan_date,
  c.handled_by_name,
  c.handled_by_employee_id,
  c.vehicle_number,
  c.declared_value,
  c.notes,
  c.bill_number,
  c.received_on,
  c.digitally_signed,
  c.cancelled_at,
  c.cancel_reason,
  c.created_at,
  c.updated_at,
  cl.id as client_id,
  cl.name as client_name,
  a.id as address_id,
  a.label as address_label,
  c.client_address_version_id as address_version_id,
  v.version as address_version,
  (select max(lv.version) from core.client_address_versions lv
   where lv.address_id = a.id) as latest_address_version,
  v.name_on_challan,
  v.address,
  v.state_code,
  s.name as state_name,
  v.gstin,
  coalesce(totals.item_count, 0)::int as item_count,
  coalesce(totals.total_quantity, 0)::int as total_quantity,
  (select i.description from challans.challan_items i
   where i.challan_id = c.id order by i.position limit 1) as first_item,
  c.reverses_challan_id,
  reversed.number as reverses_number,
  reversed.financial_year as reverses_financial_year,
  returned.id as returned_by_challan_id,
  returned.number as returned_by_number,
  returned.financial_year as returned_by_financial_year
from challans.challans c
join core.client_address_versions v on v.id = c.client_address_version_id
join core.client_addresses a on a.id = v.address_id
join core.clients cl on cl.id = a.client_id
join core.indian_states s on s.code = v.state_code
left join lateral (
  select count(*) as item_count, sum(i.quantity) as total_quantity
  from challans.challan_items i
  where i.challan_id = c.id
) totals on true
left join challans.challans reversed on reversed.id = c.reverses_challan_id
left join challans.challans returned on returned.reverses_challan_id = c.id;

-- Names typed before into "Delivered by" / "Received by", most used first,
-- for the form's suggestions.
create view challans.handled_by_names
with (security_invoker = true) as
select handled_by_name as name, count(*)::int as uses
from challans.challans
group by handled_by_name
order by count(*) desc, handled_by_name;

-- Units typed before ("SET", "NOS"), most used first.
create view challans.item_units
with (security_invoker = true) as
select upper(unit) as unit, count(*)::int as uses
from challans.challan_items
where unit is not null
group by upper(unit)
order by count(*) desc, upper(unit);

-- The financial years that have challans, for the list's year picker.
create view challans.financial_years
with (security_invoker = true) as
select distinct direction, financial_year
from challans.challans;

-- History rows with the email of whoever made each change. Not
-- security_invoker: profiles only lets people read their own row, so this
-- view reads them with its owner's rights and checks module access itself.
create view challans.challan_history as
select
  e.id,
  e.challan_id,
  e.event_type,
  e.changes,
  e.note,
  e.created_at,
  p.email as created_by_email
from challans.challan_events e
left join core.profiles p on p.id = e.created_by
where core.has_module_access('challans');

-- ── Access ─────────────────────────────────────────────────────────────────

alter table challans.challans enable row level security;
create policy challans_select on challans.challans
  for select using (core.has_module_access('challans'));

alter table challans.challan_items enable row level security;
create policy challan_items_select on challans.challan_items
  for select using (core.has_module_access('challans'));

alter table challans.challan_events enable row level security;
create policy challan_events_select on challans.challan_events
  for select using (core.has_module_access('challans'));

-- Read-only for the app: only the functions below write.
grant usage on schema challans to authenticated;
grant select on all tables in schema challans to authenticated;

-- ── Internal helpers used by the functions below ───────────────────────────

-- The challan's items as a JSON array, in order. Used to record before/after
-- in the history.
create function challans.items_json(p_challan_id uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'description', i.description,
    'additional_description', i.additional_description,
    'serial', i.serial,
    'quantity', i.quantity,
    'unit', i.unit
  ) order by i.position), '[]'::jsonb)
  from challans.challan_items i
  where i.challan_id = p_challan_id;
$$;

-- Replaces a challan's items with p_items: a JSON array of
-- {description, additional_description, serial, quantity, unit}.
create function challans.replace_items(p_challan_id uuid, p_items jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  item jsonb;
  item_number int;
  quantity_value jsonb;
begin
  -- Checked one step at a time: Postgres doesn't promise to stop at the
  -- first true part of an `or`, and jsonb_array_length fails on a non-array.
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'Add at least one item.';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one item.';
  end if;

  for item, item_number in
    select e.value, e.ordinality from jsonb_array_elements(p_items) with ordinality e
  loop
    if core.clean_text(item->>'description') is null then
      raise exception 'Item %: enter a description.', item_number;
    end if;
    quantity_value := item->'quantity';
    if quantity_value is null or jsonb_typeof(quantity_value) <> 'number' then
      raise exception 'Item %: enter the quantity.', item_number;
    end if;
    if quantity_value::numeric <> trunc(quantity_value::numeric)
       or quantity_value::numeric < 1 then
      raise exception 'Item %: the quantity must be a whole number, 1 or more.', item_number;
    end if;
  end loop;

  delete from challans.challan_items where challan_id = p_challan_id;

  insert into challans.challan_items
    (challan_id, position, description, additional_description, serial, quantity, unit)
  select
    p_challan_id,
    e.ordinality,
    core.clean_text(e.value->>'description'),
    core.clean_text(e.value->>'additional_description'),
    core.clean_text(e.value->>'serial'),
    (e.value->>'quantity')::int,
    upper(core.clean_text(e.value->>'unit'))
  from jsonb_array_elements(p_items) with ordinality e;
end;
$$;

-- The newest version of an address, locked so a challan can point at it.
create function challans.lock_latest_version(p_address_id uuid)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  version_id uuid;
  version_locked_at timestamptz;
begin
  select v.id, v.locked_at into version_id, version_locked_at
  from core.client_address_versions v
  where v.address_id = p_address_id
  order by v.version desc
  limit 1
  for update;

  if version_id is null then
    raise exception 'That address no longer exists. It may have been deleted.';
  end if;
  if version_locked_at is null then
    update core.client_address_versions set locked_at = now() where id = version_id;
  end if;
  return version_id;
end;
$$;

-- The employee with exactly this name, if there's just one.
create function challans.employee_named(p_name text)
returns uuid
language sql
stable
set search_path = ''
as $$
  select case when count(*) = 1 then min(e.id::text)::uuid end
  from core.employees e
  where lower(e.name) = lower(p_name);
$$;

-- Takes the lock on a number series (direction + financial year) and returns
-- its next number. The lock is held until the caller's transaction ends, so
-- the caller must insert the challan in that same transaction.
create function challans.lock_number_series(p_direction text, p_financial_year smallint)
returns integer
language plpgsql
set search_path = ''
as $$
begin
  -- Two people saving at once wait here in turn, so they can't both take the
  -- same number. Released automatically when the transaction ends.
  perform pg_advisory_xact_lock(
    hashtext('challans.number'),
    hashtext(p_direction || ':' || p_financial_year)
  );
  return coalesce((
    select max(c.number) from challans.challans c
    where c.direction = p_direction and c.financial_year = p_financial_year
  ), 0) + 1;
end;
$$;

-- Loads and locks a challan for a change, failing with a readable message if
-- it's gone or cancelled (a cancelled challan is final).
create function challans.challan_for_update(p_challan_id uuid)
returns challans.challans
language plpgsql
set search_path = ''
as $$
declare
  found challans.challans;
begin
  select * into found from challans.challans where id = p_challan_id for update;
  if found.id is null then
    raise exception 'That challan no longer exists.';
  end if;
  if found.cancelled_at is not null then
    raise exception 'This challan is cancelled, so it can''t be changed.';
  end if;
  return found;
end;
$$;

create function challans.require_outward(p_challan challans.challans)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_challan.direction <> 'outward' then
    raise exception 'Only outward challans have this.';
  end if;
end;
$$;

-- ── Functions the app calls ────────────────────────────────────────────────
-- security definer (the app can't write these tables itself), each starting
-- with an access check.

-- Makes a challan and gives it the next number in its series. Returns its id.
--
-- Date rules: never in the future. Outward challans can be back-dated, but not
-- before the latest outward challan of that financial year, so numbers and
-- dates run in the same order. Inward challans can have any past date (they're
-- often entered weeks late).
create function challans.create_challan(
  p_direction text,
  p_challan_date date,
  p_address_id uuid,
  p_handled_by_name text,
  p_vehicle_number text,
  p_declared_value integer,
  p_notes text,
  p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_handled_by text := core.clean_text(p_handled_by_name);
  series_year smallint := challans.financial_year_of(p_challan_date);
  latest_date date;
  next_number int;
  version_id uuid;
  new_id uuid;
begin
  perform core.require_module_access('challans');

  if p_direction not in ('outward', 'inward') then
    raise exception 'Unknown challan direction "%".', p_direction;
  end if;
  if p_challan_date is null then
    raise exception 'Pick the challan date.';
  end if;
  if p_challan_date > challans.today() then
    raise exception 'The challan date can''t be in the future.';
  end if;
  if clean_handled_by is null then
    if p_direction = 'outward' then
      raise exception 'Enter who is delivering it.';
    else
      raise exception 'Enter who received it.';
    end if;
  end if;
  if p_declared_value is not null and p_declared_value < 1 then
    raise exception 'The declared value must be more than zero, or left empty.';
  end if;

  next_number := challans.lock_number_series(p_direction, series_year);

  if p_direction = 'outward' then
    select max(challan_date) into latest_date
    from challans.challans
    where direction = 'outward' and financial_year = series_year;

    if p_challan_date < latest_date then
      raise exception 'The last outward challan of % is dated %, so this one can''t be dated earlier.',
        challans.financial_year_label(series_year), to_char(latest_date, 'FMDD Mon YYYY');
    end if;
  end if;

  version_id := challans.lock_latest_version(p_address_id);

  insert into challans.challans (
    direction, challan_date, number, client_address_version_id,
    handled_by_name, handled_by_employee_id, vehicle_number, declared_value,
    notes, created_by
  )
  values (
    p_direction, p_challan_date, next_number, version_id,
    clean_handled_by, challans.employee_named(clean_handled_by),
    upper(core.clean_text(p_vehicle_number)), p_declared_value,
    core.clean_text(p_notes), auth.uid()
  )
  returning id into new_id;

  perform challans.replace_items(new_id, p_items);

  insert into challans.challan_events (challan_id, event_type, created_by)
  values (new_id, 'created', auth.uid());

  return new_id;
end;
$$;

-- Saves changes to a challan. Direction, date and number never change.
-- The printed client details stay as they were unless the address is changed
-- or p_use_latest_address asks for that address's newest details.
create function challans.update_challan(
  p_challan_id uuid,
  p_address_id uuid,
  p_use_latest_address boolean,
  p_handled_by_name text,
  p_vehicle_number text,
  p_declared_value integer,
  p_notes text,
  p_items jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing challans.challans;
  old_address_id uuid;
  new_version_id uuid;
  clean_handled_by text := core.clean_text(p_handled_by_name);
  clean_vehicle text := upper(core.clean_text(p_vehicle_number));
  clean_notes text := core.clean_text(p_notes);
  old_items jsonb;
  new_items jsonb;
  changes jsonb := '{}';
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);

  if clean_handled_by is null then
    if existing.direction = 'outward' then
      raise exception 'Enter who is delivering it.';
    else
      raise exception 'Enter who received it.';
    end if;
  end if;
  if p_declared_value is not null and p_declared_value < 1 then
    raise exception 'The declared value must be more than zero, or left empty.';
  end if;

  select address_id into old_address_id
  from core.client_address_versions where id = existing.client_address_version_id;

  if p_address_id is distinct from old_address_id or p_use_latest_address then
    new_version_id := challans.lock_latest_version(p_address_id);
  else
    new_version_id := existing.client_address_version_id;
  end if;

  if new_version_id <> existing.client_address_version_id then
    changes := changes || jsonb_build_object('address', jsonb_build_object(
      'from', (select v.name_on_challan || ', ' || a.label || ' (v' || v.version || ')'
               from core.client_address_versions v
               join core.client_addresses a on a.id = v.address_id
               where v.id = existing.client_address_version_id),
      'to', (select v.name_on_challan || ', ' || a.label || ' (v' || v.version || ')'
             from core.client_address_versions v
             join core.client_addresses a on a.id = v.address_id
             where v.id = new_version_id)
    ));
  end if;
  if clean_handled_by is distinct from existing.handled_by_name then
    changes := changes || jsonb_build_object('handled_by_name',
      jsonb_build_object('from', existing.handled_by_name, 'to', clean_handled_by));
  end if;
  if clean_vehicle is distinct from existing.vehicle_number then
    changes := changes || jsonb_build_object('vehicle_number',
      jsonb_build_object('from', existing.vehicle_number, 'to', clean_vehicle));
  end if;
  if p_declared_value is distinct from existing.declared_value then
    changes := changes || jsonb_build_object('declared_value',
      jsonb_build_object('from', existing.declared_value, 'to', p_declared_value));
  end if;
  if clean_notes is distinct from existing.notes then
    changes := changes || jsonb_build_object('notes',
      jsonb_build_object('from', existing.notes, 'to', clean_notes));
  end if;

  old_items := challans.items_json(p_challan_id);
  perform challans.replace_items(p_challan_id, p_items);
  new_items := challans.items_json(p_challan_id);
  if new_items <> old_items then
    changes := changes || jsonb_build_object('items',
      jsonb_build_object('from', old_items, 'to', new_items));
  end if;

  -- Saved without changing anything: no history row.
  if changes = '{}'::jsonb then
    return;
  end if;

  update challans.challans
  set client_address_version_id = new_version_id,
      handled_by_name = clean_handled_by,
      handled_by_employee_id = challans.employee_named(clean_handled_by),
      vehicle_number = clean_vehicle,
      declared_value = p_declared_value,
      notes = clean_notes,
      updated_at = now()
  where id = p_challan_id;

  insert into challans.challan_events (challan_id, event_type, changes, created_by)
  values (p_challan_id, 'edited', changes, auth.uid());
end;
$$;

-- Cancels a challan; it keeps its number. With p_create_return, an outward
-- challan also gets an inward challan dated today with the same client and
-- items, linked both ways. Returns that inward challan's id (or null).
create function challans.cancel_challan(
  p_challan_id uuid,
  p_reason text,
  p_create_return boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing challans.challans;
  clean_reason text := core.clean_text(p_reason);
  return_date date := challans.today();
  return_year smallint := challans.financial_year_of(challans.today());
  return_number int;
  return_id uuid;
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);

  if p_create_return and existing.direction <> 'outward' then
    raise exception 'Only an outward challan can have its goods brought back in.';
  end if;

  update challans.challans
  set cancelled_at = now(),
      cancelled_by = auth.uid(),
      cancel_reason = clean_reason,
      updated_at = now()
  where id = p_challan_id;

  if p_create_return then
    return_number := challans.lock_number_series('inward', return_year);

    insert into challans.challans (
      direction, challan_date, number, client_address_version_id,
      handled_by_name, handled_by_employee_id, vehicle_number,
      declared_value, reverses_challan_id, created_by
    )
    values (
      'inward', return_date, return_number, existing.client_address_version_id,
      existing.handled_by_name, existing.handled_by_employee_id, existing.vehicle_number,
      existing.declared_value, existing.id, auth.uid()
    )
    returning id into return_id;

    insert into challans.challan_items
      (challan_id, position, description, additional_description, serial, quantity, unit)
    select return_id, position, description, additional_description, serial, quantity, unit
    from challans.challan_items
    where challan_id = existing.id;

    insert into challans.challan_events (challan_id, event_type, note, created_by)
    values (
      return_id, 'created',
      'Brought back by cancelling outward challan ' || existing.number || ' / '
        || challans.financial_year_label(existing.financial_year) || '.',
      auth.uid()
    );
  end if;

  insert into challans.challan_events (challan_id, event_type, changes, note, created_by)
  values (
    p_challan_id, 'cancelled',
    case when return_id is null then '{}'::jsonb
         else jsonb_build_object('return_challan_id', return_id,
                                 'return_number', return_number,
                                 'return_financial_year', return_year)
    end,
    clean_reason, auth.uid()
  );

  return return_id;
end;
$$;

-- The signed copy came back on p_received_on; null marks it not received.
create function challans.set_received(p_challan_id uuid, p_received_on date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing challans.challans;
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);
  perform challans.require_outward(existing);

  if p_received_on > challans.today() then
    raise exception 'The received date can''t be in the future.';
  end if;
  if p_received_on < existing.challan_date then
    raise exception 'It can''t be received before the challan date.';
  end if;
  if p_received_on is not distinct from existing.received_on then
    return;
  end if;

  update challans.challans
  set received_on = p_received_on, updated_at = now()
  where id = p_challan_id;

  insert into challans.challan_events (challan_id, event_type, changes, created_by)
  values (p_challan_id, 'received',
    jsonb_build_object('received_on',
      jsonb_build_object('from', existing.received_on, 'to', p_received_on)),
    auth.uid());
end;
$$;

create function challans.set_bill_number(p_challan_id uuid, p_bill_number text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing challans.challans;
  clean_bill text := upper(core.clean_text(p_bill_number));
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);
  perform challans.require_outward(existing);

  if clean_bill is not distinct from existing.bill_number then
    return;
  end if;

  update challans.challans
  set bill_number = clean_bill, updated_at = now()
  where id = p_challan_id;

  insert into challans.challan_events (challan_id, event_type, changes, created_by)
  values (p_challan_id, 'bill_number',
    jsonb_build_object('bill_number',
      jsonb_build_object('from', existing.bill_number, 'to', clean_bill)),
    auth.uid());
end;
$$;

create function challans.set_digitally_signed(p_challan_id uuid, p_signed boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing challans.challans;
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);
  perform challans.require_outward(existing);

  if p_signed = existing.digitally_signed then
    return;
  end if;

  update challans.challans
  set digitally_signed = p_signed, updated_at = now()
  where id = p_challan_id;

  insert into challans.challan_events (challan_id, event_type, changes, created_by)
  values (p_challan_id, 'digitally_signed',
    jsonb_build_object('digitally_signed',
      jsonb_build_object('from', existing.digitally_signed, 'to', p_signed)),
    auth.uid());
end;
$$;

-- Postgres grants EXECUTE to PUBLIC on every new function. Only the app-facing
-- ones are callable, and only by signed-in users; the rest are internal.
revoke execute on all functions in schema challans from public, anon, authenticated;

grant execute on function challans.create_challan(text, date, uuid, text, text, integer, text, jsonb) to authenticated;
grant execute on function challans.update_challan(uuid, uuid, boolean, text, text, integer, text, jsonb) to authenticated;
grant execute on function challans.cancel_challan(uuid, text, boolean) to authenticated;
grant execute on function challans.set_received(uuid, date) to authenticated;
grant execute on function challans.set_bill_number(uuid, text) to authenticated;
grant execute on function challans.set_digitally_signed(uuid, boolean) to authenticated;

-- ── Search ─────────────────────────────────────────────────────────────────
-- Across every financial year, on the server (the list only loads one year at
-- a time).

-- Challans matching all the filters given; a null filter is ignored.
--   p_text        the number exactly, or part of the printed name, address
--                 label, client name, delivered/received by, vehicle, bill
--                 number, notes, or any item's description, second line or serial
--   p_client_ids  only these clients
--   p_from, p_to  challan date range, inclusive
--   p_direction   'outward' or 'inward'
-- Newest first, at most 1000. security invoker: the tables' own row-level
-- security decides what the caller sees.
create function challans.search_challans(
  p_text text,
  p_client_ids uuid[],
  p_from date,
  p_to date,
  p_direction text
)
returns setof challans.challan_overview
language sql
stable
security invoker
set search_path = ''
as $$
  with query as (
    select
      nullif(btrim(p_text), '') as text,
      -- Typed % and _ are searched for literally, not as wildcards.
      '%' || replace(replace(replace(btrim(p_text), '\', '\\'), '%', '\%'), '_', '\_') || '%'
        as pattern
  )
  select o.*
  from challans.challan_overview o, query q
  where (p_direction is null or o.direction = p_direction)
    and (p_client_ids is null or o.client_id = any(p_client_ids))
    and (p_from is null or o.challan_date >= p_from)
    and (p_to is null or o.challan_date <= p_to)
    and (
      q.text is null
      or o.number::text = q.text
      or o.client_name ilike q.pattern
      or o.name_on_challan ilike q.pattern
      or o.address_label ilike q.pattern
      or o.handled_by_name ilike q.pattern
      or o.vehicle_number ilike q.pattern
      or o.bill_number ilike q.pattern
      or o.notes ilike q.pattern
      or exists (
        select 1 from challans.challan_items i
        where i.challan_id = o.id
          and (i.description ilike q.pattern
               or i.additional_description ilike q.pattern
               or i.serial ilike q.pattern)
      )
    )
  order by o.challan_date desc, o.number desc
  limit 1000;
$$;

revoke execute on function challans.search_challans(text, uuid[], date, date, text) from public, anon;
grant execute on function challans.search_challans(text, uuid[], date, date, text) to authenticated;
