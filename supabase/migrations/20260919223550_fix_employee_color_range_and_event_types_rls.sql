-- Corrective migration, found via real execution the same night migration 1 was
-- written (zero rows existed yet in either affected table — safe, additive fix,
-- not a retroactive edit of already-relied-upon history).

-- Bug 1: core.employees.color was `integer` (signed 32-bit, max ~2.1 billion), but a
-- fully-opaque Flutter Color.value (alpha=0xFF) like 0xFF4CAF50 = 4,283,215,696
-- exceeds that — every normal opaque color would have failed to insert.
alter table core.employees alter column color type bigint;

-- Bug 2: event_types_insert only checked is_admin_or_above(), not the
-- superadmin-only restriction the design calls for on structural
-- (status_effect is not null) rows — a plain admin could insert one via a direct
-- API call, bypassing "your dad never adds one of these himself." Purely
-- descriptive self-service inserts (status_effect is null) stay admin-or-above.
drop policy event_types_insert on core.event_types;
create policy event_types_insert on core.event_types
  for insert with check (
    core.is_superadmin() or (core.is_admin_or_above() and status_effect is null)
  );

-- Bug 3 (same root cause as Bug 2): event_types_update had no restriction at all
-- beyond admin-or-above, but the Event-types manager screen (icons/colors, adding
-- new structural types) is superadmin-only per plan.md's Screens section.
drop policy event_types_update on core.event_types;
create policy event_types_update on core.event_types
  for update using (core.is_superadmin()) with check (core.is_superadmin());
