#!/usr/bin/env bash
# test-report-format-drift.sh — keep the report format in sync.
# The format is defined as LLM instructions in commands/it.md; preview-report.sh
# is a hand-maintained golden sample of that format. These two must not drift:
# if you change a format element in one, this test fails until the other matches.
# Add a marker below whenever you add a load-bearing format element.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ITMD="$DIR/../commands/it.md"
PREVIEW="$DIR/preview-report.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# Structural markers that MUST appear in BOTH files.
markers=(
  "# 🧭 Drift check"
  "**Cause —**"
  "Verdict —"
  "START OVER (clean slate)"
  "KEEP GOING (just fix one thing)"
  "What's wrong"
  "The fix"
  "How the restart happens"
  "Load-bearing problems"
  "*flips:*"
  "**Solid**"
  "📋 Context"
  "🔴"
  "🟡"
)

for m in "${markers[@]}"; do
  in_it=0; in_pv=0
  grep -qF -- "$m" "$ITMD" && in_it=1
  grep -qF -- "$m" "$PREVIEW" && in_pv=1
  if   [[ $in_it -eq 1 && $in_pv -eq 1 ]]; then pass "in both: '$m'"
  elif [[ $in_it -eq 0 && $in_pv -eq 0 ]]; then bad "missing from BOTH (stale test marker?): '$m'"
  elif [[ $in_it -eq 0 ]];                 then bad "in preview-report.sh but NOT it.md (format drift): '$m'"
  else                                          bad "in it.md but NOT preview-report.sh (update the sample): '$m'"
  fi
done

exit $fail
