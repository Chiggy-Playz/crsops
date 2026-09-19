-- Bug found via real execution: migration 1 created every `core` table/view/
-- function with RLS policies, but never granted `authenticated` baseline
-- schema/table/function privileges. RLS restricts *which rows* a role can see —
-- it does not substitute for GRANT. Without this, every `.from()`/`.rpc()` call
-- from a signed-in user would fail with "permission denied for schema core"
-- regardless of how correct the RLS policies are; only PostgREST-schema-exposure
-- (the "Exposed schemas" Studio setting) had been accounted for, not the
-- underlying Postgres role grants.
--
-- No `anon` grants: this app requires sign-in for everything (the allow-list
-- gates account creation itself), so anonymous access to `core` is never needed.

grant usage on schema core to authenticated;

grant select, insert, update, delete on all tables in schema core to authenticated;
grant execute on all functions in schema core to authenticated;

-- so tables/functions added by LATER migrations (Phase 2 onward, still in `core`)
-- get the same grants automatically, without needing to remember this step again
alter default privileges in schema core grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema core grant execute on functions to authenticated;
