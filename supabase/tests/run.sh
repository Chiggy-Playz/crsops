#!/usr/bin/env bash
# Runs the database tests inside one transaction that is always rolled back.
# See README.md.
#
#   supabase/tests/run.sh                    every *_test.sql, local database
#   supabase/tests/run.sh clients            only clients_test.sql
#   supabase/tests/run.sh --linked [names]   against the linked project (prod)
#
# Local means the stack `supabase start` runs; set LOCAL_DB_URL to use
# another database.
set -euo pipefail

cd "$(dirname "$0")"

linked=false
if [ "${1:-}" = --linked ]; then
  linked=true
  shift
fi
local_db_url=${LOCAL_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}

if [ $# -eq 0 ]; then
  test_files=(*_test.sql)
else
  test_files=()
  for name in "$@"; do test_files+=("${name%_test.sql}_test.sql"); done
fi

# The run is only harmless because it all ends in one rollback. A test file
# that ends the transaction itself would make everything before it permanent,
# on prod. (`end;` alone is fine: plpgsql blocks end with it.)
if grep -niwE 'commit|rollback|abort|end +(transaction|work)|start +transaction' "${test_files[@]}"; then
  echo "Refusing to run: test files must not end or start transactions (lines above)." >&2
  exit 1
fi

run_sql=$(mktemp --suffix=.sql)
result=$(mktemp)
trap 'rm -f "$run_sql" "$result"' EXIT

cat _begin.sql "${test_files[@]}" _end.sql > "$run_sql"

if $linked; then
  # Goes through the Management API, which returns only the last query's rows
  # (the TAP lines), after a status line.
  if ! supabase db query --linked -f "$run_sql" > "$result" 2>&1; then
    cat "$result"
    exit 1
  fi
  sed -n '/^{/,$p' "$result" | jq -r '.rows[].line' > "$result.tap"
  mv "$result.tap" "$result"
else
  # Quiet, rows only: the only rows printed are the TAP lines.
  if ! psql "$local_db_url" -X -q -A -t -v ON_ERROR_STOP=1 -f "$run_sql" > "$result" 2>&1; then
    cat "$result"
    exit 1
  fi
fi
cat "$result"

# Top-level lines are one per test function; indented ones are its checks.
failed=$(grep -c '^not ok' "$result" || true)
passed=$(grep -c '^ok' "$result" || true)
echo
echo "$passed test functions passed, $failed failed."
[ "$failed" -eq 0 ]
