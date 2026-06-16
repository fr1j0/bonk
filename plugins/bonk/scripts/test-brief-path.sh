#!/usr/bin/env bash
# Tests for brief-path.sh: the path must be ABSOLUTE, root-anchored, and identical
# whether resolved from the repo root or a subdirectory — that symmetry is the fix
# for the write/read mismatch (issue #27). It must also create the .bonk/ dir.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/brief-path.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# Resolve a path's physical form so macOS /private symlinks don't cause false fails.
real() { ( cd "$(dirname "$1")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "$1")" ); }

# 1. In a git repo, the path is absolute, under <root>/.bonk, and .bonk is created.
t="$(mktemp -d)"
( cd "$t" && git init -q )
out_root="$(cd "$t" && bash "$SCRIPT")"
[[ "$out_root" == /* ]] && pass "path is absolute" || bad "not absolute: '$out_root'"
[[ "$(real "$out_root")" == "$(cd "$t" && pwd -P)/.bonk/clean-brief.md" ]] \
  && pass "path is <root>/.bonk/clean-brief.md" || bad "wrong path: '$out_root'"
[[ -d "$t/.bonk" ]] && pass ".bonk dir created" || bad ".bonk dir missing"

# 2. THE BUG: from a subdirectory, the path is IDENTICAL to the root resolution.
mkdir -p "$t/sub/deep"
out_sub="$(cd "$t/sub/deep" && bash "$SCRIPT")"
[[ "$(real "$out_sub")" == "$(real "$out_root")" ]] \
  && pass "subdir resolves to same path as root" || bad "subdir drifted: '$out_sub' != '$out_root'"
rm -rf "$t"

# 3. Outside a git repo, the path anchors to the current directory.
t2="$(mktemp -d)"
out_nogit="$(cd "$t2" && bash "$SCRIPT")"
[[ "$(real "$out_nogit")" == "$(cd "$t2" && pwd -P)/.bonk/clean-brief.md" ]] \
  && pass "non-git anchors to cwd" || bad "non-git wrong: '$out_nogit'"
rm -rf "$t2"

exit $fail
