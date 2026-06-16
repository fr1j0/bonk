#!/usr/bin/env bash
# preview-report.sh — render a sample /bonk:it re-grounding report in the current
# format, so you can eyeball formatting in your terminal after changing it.md.
#
# This is a HAND-MAINTAINED golden sample, not generated output: the real format
# is defined as LLM instructions in commands/it.md. When you change that format,
# update the examples below to match — then run this to see how they render.
#
# Usage:
#   bash preview-report.sh            # show both examples
#   bash preview-report.sh restart    # RESTART verdict only
#   bash preview-report.sh continue   # CONTINUE verdict only
set -euo pipefail

restart_example() {
  cat <<'EOF'
══════════════════════════════════════════════════════════════════
 EXAMPLE A — verdict: RESTART
══════════════════════════════════════════════════════════════════

■ BOTTOM LINE
  Verdict: RESTART — a foundational assumption is 🔴 Low-confidence.
  Wrong:   🔴 assumed the service has API-key auth — it has none to key on.
  Do now:  add an API-key layer first, else the limiter degrades to per-IP.

Load-bearing problems
─────────────────────
① 🔴 service has per-caller API keys to limit on
   guessed — no key handling anywhere; app/main.py has one unauthenticated route
   flips: a key scheme elsewhere in the repo (there is none)
② 🟡 slowapi cleanly supports per-key keying
   inferred — default key_func is per-IP; per-key needs a custom one
   flips: confirming a custom key_func is acceptable

Solid: (from-user) 100 req/min per key · (from-file) slowapi in requirements, no Redis

─────────────────────────────────────
Goal:       add per-API-key rate limiting (100/min) to the FastAPI service
Divergence: pattern-matched "API + rate limit" → Express, never verified the stack
Dismissed:  per-IP limiting · fastapi-limiter (Redis-native)
Artifacts:  clean — nothing to undo
EOF
}

continue_example() {
  cat <<'EOF'
══════════════════════════════════════════════════════════════════
 EXAMPLE B — verdict: CONTINUE
══════════════════════════════════════════════════════════════════

■ BOTTOM LINE
  Verdict: CONTINUE — core approach is sound; one secondary assumption was wrong.
  Wrong:   🟡 assumed the cache TTL is 60s — it's 600s (config/cache.yaml)
  Do now:  recompute the expiry window with 600s and keep going.

Load-bearing problems
─────────────────────
① 🟡 cache TTL is 60 seconds
   inferred — read the default, not the env override in config/cache.yaml
   flips: the config file (already checked — it's 600s)

Solid: (from-user) invalidate on write · (from-file) Redis-backed cache in deps

─────────────────────────────────────
Goal:       add write-through caching to the profile endpoint
Divergence: used the 60s default instead of the 600s override when sizing the window
Artifacts:  clean — nothing to undo
EOF
}

case "${1:-both}" in
  restart)  restart_example ;;
  continue) continue_example ;;
  both)     restart_example; echo; continue_example ;;
  *)
    printf 'usage: %s [restart|continue|both]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
