#!/usr/bin/env bash
# Guard installability: the two manifests must be valid JSON and carry the keys the
# Claude Code plugin loader needs. A malformed plugin.json or a missing source/version
# breaks `/plugin install` with no other test catching it. JSON well-formedness needs
# a parser (python3/jq/node) and is skipped if none is present; key presence is
# parser-independent and always runs.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"
root="$(bonk_root)"
plugin="$root/plugins/bonk/.claude-plugin/plugin.json"
market="$root/.claude-plugin/marketplace.json"
fail=0
pass() { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; fail=1; }

parser=""
if   command -v python3 >/dev/null 2>&1; then parser=python3
elif command -v jq      >/dev/null 2>&1; then parser=jq
elif command -v node    >/dev/null 2>&1; then parser=node
fi

valid_json() {
  case "$parser" in
    python3) python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" 2>/dev/null ;;
    jq)      jq -e . "$1" >/dev/null 2>&1 ;;
    node)    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$1" 2>/dev/null ;;
  esac
}

# Files exist.
[[ -f "$plugin" ]] && pass "plugin.json present"      || bad "plugin.json missing at $plugin"
[[ -f "$market" ]] && pass "marketplace.json present" || bad "marketplace.json missing at $market"

# Valid JSON (or skip when no parser is available).
for f in "$plugin" "$market"; do
  name="$(basename "$f")"
  if [[ -z "$parser" ]]; then
    pass "JSON parse skipped for $name (no python3/jq/node)"
  elif valid_json "$f"; then
    pass "valid JSON: $name"
  else
    bad "invalid JSON: $name"
  fi
done

# Required keys (parser-independent grep).
grep -q '"name"'    "$plugin" && grep -q '"version"' "$plugin" \
  && pass "plugin.json has name + version" || bad "plugin.json missing name/version"
grep -q '"name"'    "$market" && grep -q '"plugins"' "$market" && grep -q '"source"' "$market" \
  && pass "marketplace.json has name + plugins + source" || bad "marketplace.json missing name/plugins/source"

exit $fail
