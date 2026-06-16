#!/usr/bin/env bash
# brief-consume.sh — mark the clean brief as used once /bonk:resume has rehydrated
# it, so a later BARE /bonk:resume (no fresh /bonk:it in between) doesn't silently
# reload stale state. The brief is renamed clean-brief.md -> clean-brief.used.md —
# recoverable, never deleted — which makes the next validate report "no brief".
# Usage: brief-consume.sh [path]   (default: <root>/.bonk/clean-brief.md)
# Exit 0 always: prints the .used path if it moved one; a no-op note to stderr otherwise.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"

path="${1:-$(brief_path)}"

if [[ ! -f "$path" ]]; then
  printf 'no brief to consume at %s\n' "$path" >&2
  exit 0
fi

used="${path%.md}.used.md"
mv -f "$path" "$used"
printf '%s\n' "$used"
exit 0
