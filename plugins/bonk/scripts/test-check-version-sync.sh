#!/usr/bin/env bash
# Tests for check-version-sync.sh: matching → 0+version, mismatch/missing → 5.
# Also asserts the REAL repo manifests are currently in sync.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/check-version-sync.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

mkjson() { printf '{ "name": "x", "version": "%s" }\n' "$1" > "$2"; }

# 1. Matching versions → exit 0 and echo the version.
a="$(mktemp)"; b="$(mktemp)"
mkjson "1.2.3" "$a"; mkjson "1.2.3" "$b"
out="$(bash "$SCRIPT" "$a" "$b" 2>/dev/null)"; code=$?
[[ $code -eq 0 && "$out" == "1.2.3" ]] && pass "match → 0 + version" || bad "match: got '$out' ($code)"

# 2. Mismatched versions → exit 5.
mkjson "1.2.3" "$a"; mkjson "1.2.4" "$b"
bash "$SCRIPT" "$a" "$b" >/dev/null 2>&1
[[ $? -eq 5 ]] && pass "mismatch → 5" || bad "mismatch: wrong exit"

# 3. Missing version → exit 5.
printf '{ "name": "x" }\n' > "$a"; mkjson "1.2.3" "$b"
bash "$SCRIPT" "$a" "$b" >/dev/null 2>&1
[[ $? -eq 5 ]] && pass "missing version → 5" || bad "missing: wrong exit"
rm -f "$a" "$b"

# 4. The real manifests are in sync (no args → defaults).
out="$(bash "$SCRIPT" 2>/dev/null)"; code=$?
[[ $code -eq 0 ]] && pass "repo manifests in sync ($out)" || bad "repo manifests drifted ($code)"

exit $fail
