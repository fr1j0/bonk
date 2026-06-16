#!/usr/bin/env bash
# test.sh — run every test-*.sh in this directory; non-zero if any fail.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$DIR"/test-*.sh; do
  echo "=== $(basename "$t") ==="
  bash "$t" || fail=1
done
exit $fail
