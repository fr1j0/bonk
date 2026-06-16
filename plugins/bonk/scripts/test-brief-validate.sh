#!/usr/bin/env bash
# Tests for brief-validate.sh: missing → 3, valid → 0+path, malformed → 4.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/brief-validate.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# 1. Missing file → exit 3
miss="$(mktemp -d)/nope.md"
bash "$SCRIPT" "$miss" >/dev/null 2>&1
[[ $? -eq 3 ]] && pass "missing → exit 3" || bad "missing: wrong exit"

# 2. Valid brief → exit 0 and echoes the path
v="$(mktemp)"
cat > "$v" <<'EOF'
# bonk clean brief
## Goal
Do the thing.
## Verified facts
- (from-user) x
## Corrected approach
- step
## Do not redo
- y
EOF
out="$(bash "$SCRIPT" "$v" 2>/dev/null)"; code=$?
[[ $code -eq 0 && "$out" == "$v" ]] && pass "valid → exit 0 + path" || bad "valid: got '$out' ($code)"

# 3. Malformed (missing "## Do not redo") → exit 4
m="$(mktemp)"
cat > "$m" <<'EOF'
# bonk clean brief
## Goal
Do the thing.
## Verified facts
- (from-user) x
## Corrected approach
- step
EOF
bash "$SCRIPT" "$m" >/dev/null 2>&1
[[ $? -eq 4 ]] && pass "malformed → exit 4" || bad "malformed: wrong exit"
rm -f "$v" "$m"
exit $fail
