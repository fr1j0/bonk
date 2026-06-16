#!/usr/bin/env bash
# brief-validate.sh — validate the bonk clean brief.
# Usage: brief-validate.sh [path]   (default: <root>/.bonk/clean-brief.md)
# Exit 0 + prints path : valid (all four required sections present).
# Exit 3 : file missing (reason on stderr).
# Exit 4 : malformed — a required section header is missing (reason on stderr).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"

path="${1:-$(brief_path)}"

if [[ ! -f "$path" ]]; then
  printf 'no brief found at %s; run /bonk first\n' "$path" >&2
  exit 3
fi

for section in "## Goal" "## Verified facts" "## Corrected approach" "## Do not redo"; do
  if ! grep -qxF "$section" "$path"; then
    printf "malformed brief: missing section '%s'\n" "$section" >&2
    exit 4
  fi
done

printf '%s\n' "$path"
exit 0
