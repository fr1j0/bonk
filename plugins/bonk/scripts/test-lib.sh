#!/usr/bin/env bash
# Tests for lib.sh path helpers.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# In a git repo, bonk_root is the repo toplevel; brief_path nests under it.
t="$(mktemp -d)"
( cd "$t" && git init -q )
out="$(cd "$t" && . "$DIR/lib.sh" && bonk_root)"
# macOS mktemp dirs may be symlinked via /private; compare resolved paths.
[[ "$(cd "$out" && pwd -P)" == "$(cd "$t" && pwd -P)" ]] && pass "bonk_root = repo root" || bad "bonk_root: got '$out'"

out="$(cd "$t" && . "$DIR/lib.sh" && brief_path)"
[[ "$out" == */.bonk/clean-brief.md ]] && pass "brief_path under .bonk" || bad "brief_path: got '$out'"
rm -rf "$t"
exit $fail
