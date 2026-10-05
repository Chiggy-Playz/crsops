-- Security Advisor clean-up. Defence in depth: nothing was reachable before
-- this (anon has no usage on the core/attendance schemas, and sign-up is
-- gated by core.check_allowed_signup), but these close the gaps the
-- advisor flags.

-- 1. "Function Search Path Mutable": pin search_path so these can't resolve
-- names through a caller-controlled path. Every reference inside them is
-- already schema-qualified (built-ins come from pg_catalog regardless).
-- Cost: a SET clause stops Postgres inlining SQL functions. Measured on live
-- data for September: effective_range_status ~5ms -> ~9ms. Accepted.
alter function core.employee_status_as_of(uuid, date) set search_path = '';
alter function attendance.recent_gaps(integer) set search_path = '';
alter function attendance.derived_flags(date, date, uuid) set search_path = '';
alter function attendance.effective_range_status(date, date, uuid) set search_path = '';

-- 2. "Public Can Execute SECURITY DEFINER": Postgres grants EXECUTE on every
-- new function to PUBLIC. RLS policies call these helpers as the signed-in
-- user, so authenticated keeps EXECUTE (the advisor's "Signed-In Users Can
-- Execute" warning stays for them by design: they only ever answer about
-- auth.uid() itself).
revoke execute on function core.is_superadmin() from public, anon;
revoke execute on function core.is_admin_or_above() from public, anon;
revoke execute on function core.has_module_access(text) from public, anon;
grant execute on function core.is_superadmin() to authenticated;
grant execute on function core.is_admin_or_above() to authenticated;
grant execute on function core.has_module_access(text) to authenticated;

-- handle_new_user only ever runs as the on-insert trigger on auth.users.
-- Postgres checks EXECUTE when a trigger is created, not when it fires, so
-- nobody needs to be able to call it directly.
revoke execute on function core.handle_new_user() from public, anon, authenticated;
