#!/usr/bin/env bash
# Invariant guard: the .bonk/ state dir MUST be git-ignored. brief-validate.sh's
# staleness check trusts the brief's mtime, which is only reliable if briefs never
# get committed; and a leaked brief would land in the user's history. Verified via
# git's own ignore resolution, not a .gitignore text grep.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

root="$(bonk_root)"

if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pass ".bonk/ ignore check skipped (not in a git repo)"
elif git -C "$root" check-ignore -q ".bonk/clean-brief.md"; then
  pass ".bonk/ is git-ignored"
else
  bad ".bonk/ is NOT git-ignored — briefs could be committed and mtime staleness breaks"
fi
exit $fail
