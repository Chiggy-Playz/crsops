# Database tests

Tests for the logic that lives in the database: the write functions, row-level
security, the attendance functions. Written with [pgTAP](https://pgtap.org),
Postgres's standard test framework.

```sh
supabase/tests/run.sh             # everything
supabase/tests/run.sh clients     # just clients_test.sql
```

It runs against the **linked project** (prod, for now), inside one
transaction that is always rolled back, so nothing is left behind: not the
test data, not the throwaway users, not the `tests` schema. No Docker needed;
it goes through `supabase db query --linked`.

## What you get

- One `ok` / `not ok` line per test function, with its checks indented under
  it, then a count. The script exits non-zero if anything failed.
- `tests.test_lint`: [plpgsql_check](https://github.com/okbob/plpgsql_check)
  reads every plpgsql function in `core`, `attendance` and `challans` without
  running it, like `flutter analyze`.
- `# coverage` lines: the share of each plpgsql function's statements and
  branches the tests ran. SQL-language functions and views can't be measured.

## Writing a test

Each `*_test.sql` file only defines functions named `tests.test_…` returning
`setof text`; `_begin.sql` (helpers) and `_end.sql` (runs them) wrap them.
Every test function runs in its own savepoint, so tests don't see each other's
data.

```sql
create function tests.test_something()
returns setof text
language plpgsql
as $$
declare
  test_address_id uuid;
begin
  perform tests.act_as_challans_user();   -- a signed-in user with challans access
  test_address_id := tests.new_address();
  return next is(…, …, 'what should be true');
  return next throws_ok(format('select tests.outward(%L, %L)', test_address_id, tests.today() + 1),
    'P0001', 'The challan date can''t be in the future.', 'a future date is refused');
end;
$$;
```

- Name plpgsql variables so they can't clash with column names
  (`test_address_id`, not `address_id`).
- Act as a user (`tests.create_user`, `tests.act_as`) rather than testing as
  the runner's own role, which skips row-level security.
- Don't count rows across the whole table: prod has real data. Limit to what
  the test made.
