#!/usr/bin/env bash
# Deterministic tests for artifact-inventory.sh using throwaway temp dirs.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/artifact-inventory.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# 1. Non-git directory → exactly NO_GIT
t1="$(mktemp -d)"
out="$(cd "$t1" && bash "$SCRIPT")"
[[ "$out" == "NO_GIT" ]] && pass "non-git → NO_GIT" || bad "non-git: got '$out'"
rm -rf "$t1"

# 2. Clean git repo → empty output, exit 0
t2="$(mktemp -d)"
( cd "$t2" && git init -q && git config user.email t@t && git config user.name t \
  && echo hi > a.txt && git add a.txt && git commit -qm init )
out="$(cd "$t2" && bash "$SCRIPT")"; code=$?
[[ -z "$out" && $code -eq 0 ]] && pass "clean repo → empty" || bad "clean repo: got '$out' ($code)"

# 3. Modified + untracked files → both listed
( cd "$t2" && echo more >> a.txt && echo new > b.txt )
out="$(cd "$t2" && bash "$SCRIPT")"
{ grep -q "a.txt" <<<"$out" && grep -q "b.txt" <<<"$out"; } \
  && pass "dirty repo lists changes" || bad "dirty repo: got '$out'"
rm -rf "$t2"
exit $fail
