#!/usr/bin/env bash
# Runs the database tests against the linked Supabase project, inside one
# transaction that is always rolled back. See README.md.
#
#   supabase/tests/run.sh            every *_test.sql
#   supabase/tests/run.sh clients    only clients_test.sql
set -euo pipefail

cd "$(dirname "$0")"

if [ $# -eq 0 ]; then
  test_files=(*_test.sql)
else
  test_files=()
  for name in "$@"; do test_files+=("${name%_test.sql}_test.sql"); done
fi

run_sql=$(mktemp --suffix=.sql)
result=$(mktemp)
trap 'rm -f "$run_sql" "$result"' EXIT

cat _begin.sql "${test_files[@]}" _end.sql > "$run_sql"

if ! supabase db query --linked -f "$run_sql" > "$result" 2>&1; then
  cat "$result"
  exit 1
fi

# The CLI prints a status line before the JSON.
sed -n '/^{/,$p' "$result" | jq -r '.rows[].line' > "$result.tap"
mv "$result.tap" "$result"
cat "$result"

# Top-level lines are one per test function; indented ones are its checks.
failed=$(grep -c '^not ok' "$result" || true)
passed=$(grep -c '^ok' "$result" || true)
echo
echo "$passed test functions passed, $failed failed."
[ "$failed" -eq 0 ]
