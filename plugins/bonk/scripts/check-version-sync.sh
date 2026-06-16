#!/usr/bin/env bash
# check-version-sync.sh — fail if the plugin version is not identical in the two
# manifests that both carry it: the plugin manifest and the marketplace manifest.
# They are hand-edited separately, so a release that bumps only one drifts silently
# (issue #28). This is the guard.
#
# Usage: check-version-sync.sh [plugin.json] [marketplace.json]
#   defaults: <root>/plugins/bonk/.claude-plugin/plugin.json
#             <root>/.claude-plugin/marketplace.json
# Exit 0 + prints the agreed version : in sync.
# Exit 5 : a version is missing or the two disagree (reason on stderr).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$DIR/lib.sh"
root="$(bonk_root)"

plugin="${1:-$root/plugins/bonk/.claude-plugin/plugin.json}"
market="${2:-$root/.claude-plugin/marketplace.json}"

# First "version": "X" value in a JSON file. Both manifests carry exactly one.
extract_version() {
  sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$1" | head -n1
}

pv="$(extract_version "$plugin")"
mv="$(extract_version "$market")"

if [[ -z "$pv" ]]; then printf 'no "version" found in %s\n' "$plugin" >&2; exit 5; fi
if [[ -z "$mv" ]]; then printf 'no "version" found in %s\n' "$market" >&2; exit 5; fi

if [[ "$pv" != "$mv" ]]; then
  printf 'version mismatch: plugin.json=%s vs marketplace.json=%s — bump both\n' "$pv" "$mv" >&2
  exit 5
fi

printf '%s\n' "$pv"
exit 0
