#!/usr/bin/env bash
# artifact-inventory.sh — list working-tree changes (the residue a wrong path
# tends to leave). Prints `git status --porcelain` lines (one per changed or
# untracked file). If not inside a git repo, prints exactly `NO_GIT` so the
# caller degrades gracefully. Read-only: never writes or deletes. Always exit 0.
set -uo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'NO_GIT\n'
  exit 0
fi

git status --porcelain
exit 0
