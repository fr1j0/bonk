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
# 🧭 Drift check
**Cause —** Context drift: you flagged the direction as wrong, and the audit confirms it — the work veered onto an unverified assumption and away from your actual goal.

---

> ## 🛑 Verdict — START OVER (clean slate)
> The work so far is built on an assumption that's probably wrong, so continuing would just stack more on a bad foundation. Drop this direction and restart the task from only what we've confirmed.
>
> **What's wrong** — assumed the FastAPI service already has API-key auth. It doesn't — so there's nothing to attach the rate limit to.
> **The fix** — add an API-key layer first, or the limiter just falls back to limiting per IP.
> **How the restart happens** — I save a short summary (confirmed facts + corrected plan) to a file; you run `/clear`, then `/bonk:resume` reloads it so we keep working without the wrong assumption following along.

---

### ⚖️ Load-bearing problems

**🔴 ①  The service has per-caller API keys to limit on**
> `guessed` — no key handling anywhere; `app/main.py` is one unauthenticated route
> *flips:* a key scheme elsewhere in the repo (there is none)

**🟡 ②  slowapi cleanly supports per-key keying**
> `inferred` — default `key_func` is per-IP; per-key needs a custom one
> *flips:* confirming a custom `key_func` is acceptable

✅ **Solid** — (from-user) 100 req/min per key · (from-file) slowapi in requirements, no Redis

---

### 📋 Context

| | |
|---|---|
| **Goal** | add per-API-key rate limiting (100/min) to the FastAPI service |
| **Divergence** | pattern-matched "API + rate-limit" → Express, never verified the stack |
| **Dismissed** | per-IP limiting · fastapi-limiter (Redis-native) |
| **Artifacts** | ✅ clean — nothing to undo |
EOF
}

continue_example() {
  cat <<'EOF'
# 🧭 Drift check
**Cause —** Minor drift: the core direction is intact, but one secondary assumption was off.

---

> ## ✅ Verdict — KEEP GOING (just fix one thing)
> The overall plan is sound — no restart needed. I'm dropping the wrong assumption below and continuing right here.
>
> **What's wrong** — assumed the cache TTL is 60s; it's actually **600s** (`config/cache.yaml`).
> **The fix** — recompute the expiry window with 600s and carry on.

---

### ⚖️ Load-bearing problems

**🟡 ①  Cache TTL is 60 seconds**
> `inferred` — read the default, not the env override in `config/cache.yaml`
> *flips:* the config file (already checked — it's 600s)

✅ **Solid** — (from-user) invalidate on write · (from-file) Redis-backed cache in deps

---

### 📋 Context

| | |
|---|---|
| **Goal** | add write-through caching to the profile endpoint |
| **Divergence** | used the 60s default instead of the 600s override when sizing the window |
| **Artifacts** | ✅ clean — nothing to undo |
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
