#!/usr/bin/env bash
# Cross-file contract guard: the clean-brief template that commands/it.md tells the
# agent to emit MUST validate cleanly under brief-validate.sh — same four headers,
# all non-empty. If a section is renamed in one place but not the other (it.md ↔
# brief-validate.sh ↔ resume.md's "validates these four headers" claim), this fails.
# The brief-contract analog of test-report-format-drift.sh.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ITMD="$DIR/../commands/it.md"
VALIDATE="$DIR/brief-validate.sh"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

# Pull the "# bonk clean brief" template out of it.md (an indented markdown sample)
# and de-indent it: take the header line plus the blank/indented lines after it,
# stripping leading whitespace. Kept mawk-safe (no interval/POSIX-class regex).
tmpl="$(mktemp)"
awk '
  /# bonk clean brief/ { grab = 1 }
  grab {
    if ($0 !~ /[^ \t]/) { print ""; next }                 # blank line in block
    if ($0 ~ /^    /)   { sub(/^[ \t]+/, ""); print; next } # indented → de-indent
    grab = 0                                                # dedented prose → end
  }
' "$ITMD" > "$tmpl"

if grep -qxF "# bonk clean brief" "$tmpl"; then
  pass "extracted the brief template from it.md"
else
  bad "could not extract '# bonk clean brief' template from it.md (moved/renamed?)"
fi

if bash "$VALIDATE" "$tmpl" >/dev/null 2>&1; then
  pass "it.md template passes brief-validate.sh"
else
  bad "it.md template REJECTED by brief-validate.sh — header/section drift between them"
fi
rm -f "$tmpl"
exit $fail
