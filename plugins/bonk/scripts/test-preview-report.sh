#!/usr/bin/env bash
# Smoke-test preview-report.sh: it must actually RUN. The report-format drift test
# only string-matches its examples; a syntax error in the heredocs or the render
# fallback would slip past that but break the script. Each verdict mode should exit
# 0 with output (markdown viewer or the raw cat fallback); a bogus arg exits 2.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/preview-report.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# 1. `both` → exit 0 with non-empty output.
out="$(bash "$SCRIPT" both 2>/dev/null)"; code=$?
{ [[ $code -eq 0 ]] && [[ -n "$out" ]]; } && pass "both → 0 + output" || bad "both: empty/err ($code)"

# 2. Each single mode runs cleanly.
for mode in restart continue; do
  bash "$SCRIPT" "$mode" >/dev/null 2>&1
  [[ $? -eq 0 ]] && pass "$mode → exit 0" || bad "$mode: non-zero exit"
done

# 3. Unknown mode → usage error, exit 2.
bash "$SCRIPT" bogus >/dev/null 2>&1
[[ $? -eq 2 ]] && pass "bogus arg → exit 2" || bad "bogus: wrong exit"

exit $fail
