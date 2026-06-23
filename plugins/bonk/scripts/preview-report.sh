#!/usr/bin/env bash
# preview-report.sh — render a sample /bonk:it re-grounding report in the current
# (rich-markdown) format, so you can eyeball formatting after changing it.md.
#
# This is a HAND-MAINTAINED golden sample, not generated output: the real format
# is defined as LLM instructions in commands/it.md. When you change that format,
# update the examples below to match — then run this to see how they render.
# test-report-format-drift.sh guards that the two stay in sync.
#
# The report is rich markdown, so this renders it through a markdown viewer
# (glow / mdcat / bat) when one is installed, and falls back to raw markdown
# (with a hint) otherwise.
#
# Usage:
#   bash preview-report.sh            # show both examples
#   bash preview-report.sh restart    # RESTART (START OVER) verdict only
#   bash preview-report.sh continue   # CONTINUE (KEEP GOING) verdict only
set -euo pipefail

render() {
  if   command -v glow  >/dev/null 2>&1; then glow -
  elif command -v mdcat >/dev/null 2>&1; then mdcat
  elif command -v bat   >/dev/null 2>&1; then bat --language=md --style=plain --paging=never
  else
    echo "(no markdown viewer found — showing raw markdown; install 'glow' for the rendered look)" >&2
    cat
  fi
}

restart_example() {
  cat <<'EOF'
```
═══════════  b o n k . i t  ·  ↺ DRIFT CHECK  ═══════════
```

## ↺ START OVER — restart from confirmed facts only

> Continuing would stack more work on a foundation that's probably wrong. The load-bearing assumption doesn't hold, so the credible move is to reset to what's verified and rebuild from there.

**What's wrong** — assumed the FastAPI service already has API-key auth. It doesn't, so there's nothing to attach the rate limit to.
**The fix** — add an API-key layer first, or the limiter silently falls back to per-IP.
**Restart path** — save confirmed facts + corrected plan to a file → `/clear` → `/bonk:resume` reloads it, so the wrong assumption doesn't follow along.

### ▌Load-bearing problems

|  | Assumption | Source | Why shaky → what flips it |
|---|---|---|---|
| `○` | Service has per-caller API keys to limit on | `guessed` | No key handling anywhere; one unauthenticated route → flips if a key scheme exists in the repo (there is none) |
| `◐` | slowapi cleanly supports per-key keying | `inferred` | Default `key_func` is per-IP → flips if a custom `key_func` is acceptable |

`○` low · `◐` med · `●` high confidence

`✓ solid` (from-user) 100 req/min per key · (from-file) slowapi in requirements, no Redis

### ▌Context

**Goal** — add per-API-key rate limiting (100/min) to the FastAPI service
**Divergence** — pattern-matched "API + rate-limit" → Express, never verified the stack
**Dismissed** — per-IP limiting · fastapi-limiter (Redis-native)
**Artifacts** — clean; nothing to undo

```
══════════════════════  END · DRIFT CHECK  ═══════════════════
```
EOF
}

continue_example() {
  cat <<'EOF'
```
═══════════  b o n k . i t  ·  ▸ DRIFT CHECK  ═══════════
```

## ▸ KEEP GOING — the plan holds, fixing one thing in place

> The overall plan is sound — no restart needed. I'm dropping the wrong assumption below and continuing right here.

**What's wrong** — assumed the cache TTL is 60s; it's actually 600s (`config/cache.yaml`).
**The fix** — recompute the expiry window with 600s and carry on.

### ▌Load-bearing problems

|  | Assumption | Source | Why shaky → what flips it |
|---|---|---|---|
| `◐` | Cache TTL is 60 seconds | `inferred` | Read the default, not the env override → flips if the config file says otherwise (it's 600s) |

`○` low · `◐` med · `●` high confidence

`✓ solid` (from-user) invalidate on write · (from-file) Redis-backed cache in deps

### ▌Context

**Goal** — add write-through caching to the profile endpoint
**Divergence** — used the 60s default instead of the 600s override when sizing the window
**Artifacts** — clean; nothing to undo

```
══════════════════════  END · DRIFT CHECK  ═══════════════════
```
EOF
}

case "${1:-both}" in
  restart)  restart_example | render ;;
  continue) continue_example | render ;;
  both)     { restart_example; printf '\n\n'; continue_example; } | render ;;
  *)
    printf 'usage: %s [restart|continue|both]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
