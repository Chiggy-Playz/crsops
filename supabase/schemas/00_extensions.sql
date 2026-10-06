-- Extensions the database's own tests use (see supabase/tests/README.md).
-- Neither changes how the app behaves; they only add functions.
--
-- pgtap: Postgres's standard test framework (ok/is/throws_ok/runtests).
-- plpgsql_check: a linter for plpgsql functions, plus a profiler that reports
-- which lines and branches the tests ran (coverage).
create extension if not exists pgtap with schema extensions;
create extension if not exists plpgsql_check with schema extensions;
