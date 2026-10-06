-- Searching challans across every financial year, on the server (the list
-- only loads one year at a time).

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

-- Advisor fix (auth_rls_initplan): `(select auth.role())` is worked out once
-- per query instead of once per row.
drop policy indian_states_select on core.indian_states;
create policy indian_states_select on core.indian_states
  for select using ((select auth.role()) = 'authenticated');
