#!/usr/bin/env bash
# Integration guard: every scripts/<name>.sh that a command (commands/*.md) tells
# the agent to run must actually exist. A rename or typo here breaks a slash command
# at runtime — invisible to shellcheck and to the per-script unit tests.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CMDS="$DIR/../commands"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

refs="$(grep -rhoE 'scripts/[A-Za-z0-9_-]+\.sh' "$CMDS" | sort -u)"

if [[ -z "$refs" ]]; then
  bad "no scripts/*.sh references found in commands/ — extraction broke?"
else
  while IFS= read -r ref; do
    base="${ref#scripts/}"
    if [[ -f "$DIR/$base" ]]; then
      pass "command-referenced script exists: $base"
    else
      bad "command references a missing script: $ref"
    fi
  done <<< "$refs"
fi
exit $fail
