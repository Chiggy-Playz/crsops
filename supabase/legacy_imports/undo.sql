-- Deliberate, manual wipe before re-importing fresh legacy data. Run this
-- by hand, on purpose -- never automatically. These three tables hold only
-- data from tool/generate_legacy_import.dart today; if real app usage ever
-- starts writing to them before a future re-import, this blunt truncate
-- stops being safe and needs revisiting then, not before.
truncate core.employees, core.employee_events, attendance.attendance_days cascade;
