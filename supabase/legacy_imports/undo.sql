-- Deliberate, manual wipe before re-importing fresh legacy data. Run this
-- by hand, on purpose -- never automatically.
--
-- No CASCADE: core.employee_ledger_entries also has an FK into
-- core.employees (on delete cascade), but this tool never writes ledger
-- entries, so it has no business deleting them. Truncating the three
-- tables this tool DOES write, child-to-parent, with no cascade, errors
-- loudly instead if a real ledger entry exists by the time this runs --
-- exactly what should happen, rather than silently destroying finance data
-- this script doesn't own.
truncate attendance.attendance_days;
truncate core.employee_events;
truncate core.employees;
