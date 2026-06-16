#!/usr/bin/env bash
# brief-validate.sh — validate the bonk clean brief.
# Usage: brief-validate.sh [path]   (default: <root>/.bonk/clean-brief.md)
# Exit 0 + prints path : valid (all four required sections present AND non-empty).
#   If the brief is also stale (mtime > 1 day), a warning is printed to stderr —
#   it still exits 0; staleness is advisory, not a failure.
# Exit 3 : file missing (reason on stderr).
# Exit 4 : malformed — a required section header is missing, or its body is empty
#          (reason on stderr).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"

path="${1:-$(brief_path)}"

if [[ ! -f "$path" ]]; then
  printf 'no brief found at %s; run /bonk:it first\n' "$path" >&2
  exit 3
fi

# section_body <header>: the lines after a "## <name>" header, up to the next
# level-2 header (or EOF). Used to reject present-but-empty sections.
section_body() {
  awk -v hdr="$1" '
    $0 == hdr { inseg = 1; next }
    inseg && /^## / { inseg = 0 }
    inseg { print }
  ' "$path"
}

for section in "## Goal" "## Verified facts" "## Corrected approach" "## Do not redo"; do
  if ! grep -qxF "$section" "$path"; then
    printf "malformed brief: missing section '%s'\n" "$section" >&2
    exit 4
  fi
  if ! section_body "$section" | grep -q '[^[:space:]]'; then
    printf "malformed brief: empty section '%s'\n" "$section" >&2
    exit 4
  fi
done

printf '%s\n' "$path"

# Staleness: warn (but still succeed) when the brief is over a day old — it may
# describe a task you've since moved on from. mtime is reliable here: .bonk/ is
# git-ignored, so the brief only ever lives in the working tree.
if find "$path" -mtime +0 2>/dev/null | grep -q .; then
  now=$(date +%s)
  # GNU stat (-c) first, then BSD/macOS stat (-f). Guard the result to digits:
  # on the "wrong" platform the other stat can print non-numeric noise instead
  # of failing, which would break the arithmetic under `set -u`.
  mt=$(stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo "$now")
  case "$mt" in ''|*[!0-9]*) mt=$now ;; esac
  days=$(( (now - mt) / 86400 ))
  printf "warning: brief is %d day(s) old — confirm it's still the task you mean\n" "$days" >&2
fi
exit 0
