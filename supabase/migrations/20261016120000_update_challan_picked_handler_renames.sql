create or replace function challans.update_challan(
  p_challan_id uuid,
  p_address_id uuid,
  p_use_latest_address boolean,
  p_handled_by_name text,
  p_vehicle_number text,
  p_declared_value integer,
  p_notes text,
  p_items jsonb,
  p_handled_by_employee_id uuid default null
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
  clean_handled_by text;
  handler_employee_id uuid;
  clean_vehicle text := upper(core.clean_text(p_vehicle_number));
  clean_notes text := core.clean_text(p_notes);
  old_items jsonb;
  new_items jsonb;
  changes jsonb := '{}';
begin
  perform core.require_module_access('challans');
  existing := challans.challan_for_update(p_challan_id);

  -- Left as it was (same employee, name not changed): keeps the name the
  -- challan was made with, even if they've since been renamed. Picking them
  -- again from the list sends their current name, which takes over.
  if p_handled_by_employee_id is not null
     and p_handled_by_employee_id is not distinct from existing.handled_by_employee_id
     and (p_handled_by_name is null
          or btrim(p_handled_by_name) = existing.handled_by_name) then
    clean_handled_by := existing.handled_by_name;
    handler_employee_id := existing.handled_by_employee_id;
  else
    select r.handler_name, r.handler_employee_id
    into clean_handled_by, handler_employee_id
    from challans.resolve_handler(p_handled_by_name, p_handled_by_employee_id) r;
  end if;
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
      handled_by_employee_id = handler_employee_id,
      vehicle_number = clean_vehicle,
      declared_value = p_declared_value,
      notes = clean_notes,
      updated_at = now()
  where id = p_challan_id;

  insert into challans.challan_events (challan_id, event_type, changes, created_by)
  values (p_challan_id, 'edited', changes, auth.uid());
end;
$$;
