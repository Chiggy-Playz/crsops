-- Module access was enforced only in the app's UI: core.has_module_access()
-- existed but no policy used it. Add it to every attendance read policy so the
-- database enforces it too.
--
-- core.has_module_access() already returns true for admin-and-above, so the
-- admin-only write policies (shift_defaults_insert, status_types_insert,
-- status_types_update, attendance_days_write) already imply module access and
-- are left unchanged. The attendance functions (effective_range_status,
-- recent_gaps, derived_flags) are security invoker, so they pick these up too.

drop policy shift_defaults_select on attendance.shift_defaults;
create policy shift_defaults_select on attendance.shift_defaults
  for select using (core.has_module_access('attendance'));

drop policy status_types_select on attendance.status_types;
create policy status_types_select on attendance.status_types
  for select using (core.has_module_access('attendance'));

drop policy attendance_days_select on attendance.attendance_days;
create policy attendance_days_select on attendance.attendance_days
  for select using (
    core.has_module_access('attendance')
    and (
      core.is_admin_or_above()
      or exists (
        select 1 from core.employees e
        where e.id = employee_id and e.user_id = auth.uid()
      )
    )
  );
