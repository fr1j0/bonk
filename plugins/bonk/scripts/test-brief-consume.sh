#!/usr/bin/env bash
# Tests for brief-consume.sh: a present brief is renamed to .used (original gone);
# an absent brief is a no-op. Always exit 0.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/brief-consume.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# 1. Present brief → renamed to clean-brief.used.md; original removed.
d="$(mktemp -d)"
b="$d/clean-brief.md"
echo "brief body" > "$b"
out="$(bash "$SCRIPT" "$b")"; code=$?
{ [[ $code -eq 0 ]] && [[ "$out" == "$d/clean-brief.used.md" ]] \
  && [[ ! -f "$b" ]] && [[ -f "$d/clean-brief.used.md" ]]; } \
  && pass "present → renamed to .used" || bad "present: out='$out' ($code)"

# 2. A second consume (brief now absent) → exit 0, no .used recreated from nothing.
bash "$SCRIPT" "$b" >/dev/null 2>&1
[[ $? -eq 0 ]] && pass "absent → no-op exit 0" || bad "absent: wrong exit"

# 3. Subsequent validate on the consumed brief reports missing (exit 3).
bash "$DIR/brief-validate.sh" "$b" >/dev/null 2>&1
[[ $? -eq 3 ]] && pass "consumed brief → validate exit 3" || bad "post-consume validate: wrong exit"
rm -rf "$d"

exit $fail
