#!/usr/bin/env bash
# lib.sh — shared path helpers for bonk scripts. Source it; do not execute.
set -uo pipefail

# bonk_root: git toplevel if inside a repo, else the current directory.
bonk_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# bonk_dir: the .bonk state directory at the project root.
bonk_dir() {
  printf '%s/.bonk\n' "$(bonk_root)"
}

# brief_path: full path to the persisted clean brief.
brief_path() {
  printf '%s/clean-brief.md\n' "$(bonk_dir)"
}
