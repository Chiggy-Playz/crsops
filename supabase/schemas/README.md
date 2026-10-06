# Database schema files

These files are **how the database should look right now**: every table, view,
function, policy and grant, one current copy of each, with comments. The
`migrations/` folder is the history of how it got there, and is still what
gets applied to the database.

| File | What's in it |
|---|---|
| `00_extensions.sql` | pgTAP and plpgsql_check (for the database tests) |
| `10_core_access.sql` | sign-up allow-list, profiles, roles, modules, the access helpers |
| `11_core_employees.sql` | employees, their events and payments |
| `12_core_clients.sql` | clients and their versioned addresses |
| `20_attendance.sql` | attendance days, shifts, the calendar functions |
| `30_challans.sql` | challans, items, history, search |

Files run in name order, and order matters: a function must exist before a
policy uses it.

## Changing the database

1. Edit the schema file. To change a function, change it in place.
2. `supabase/schemas/diff.sh add_thing` writes
   `migrations/<timestamp>_add_thing.sql` with what's needed to get there.
3. **Read that migration.** Renaming a column or table comes out as drop +
   create, which deletes the data: write that migration by hand instead
   (`alter table … rename …`), then edit the schema file to match.
4. `supabase migration up --local`, then `supabase/tests/run.sh`.
5. `supabase db push` to apply it to the hosted project.

`supabase/schemas/diff.sh` with no name only checks: it prints any difference
and fails. Run it before committing; it should say "Schema files and
migrations match."

## What still goes in a hand-written migration

- **Rows**: seed and reference data (states, roles, modules, status and
  event types) and any data fixes. The comparison only looks at structure,
  so these stay in `migrations/` and aren't in these files.
- **Renames**, as above.

After a hand-written migration that changes structure, update the schema file
too, and check `diff.sh` says they match.

## How the comparison works

`diff.sh` needs the local stack (`supabase start`), but not Docker access. It
creates two throwaway databases in the local Postgres, each starting from
Supabase's `auth` schema and extensions: one gets every migration, the other
every schema file. The CLI's pg-delta engine compares them (`auth`, `core`,
`attendance`, `challans`), and both are dropped again. It compares tables,
columns, constraints, indexes, views and their options, function code,
triggers, policies and grants.
