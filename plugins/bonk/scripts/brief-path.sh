#!/usr/bin/env bash
# brief-path.sh — print the ABSOLUTE canonical path for the clean brief, creating
# its parent `.bonk/` directory. /bonk:it writes the brief to exactly this path so
# that /bonk:resume (which resolves the same path via brief-validate.sh → lib.sh)
# always finds it — even when invoked from a subdirectory of the repo.
#
# Resolving through lib.sh's bonk_root (git toplevel, else cwd) is what keeps the
# write side and the read side symmetric. Always exit 0 on success.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"

mkdir -p "$(bonk_dir)"
brief_path
