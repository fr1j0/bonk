# bonk

A pattern-interrupt and context re-grounding plugin for Claude Code.

When the agent commits to a wrong path and keeps compounding it — defending the
bad approach turn after turn — `bonk` halts it, audits what it's actually
assuming, and (when the context is too far gone) restarts from a clean, verified
problem statement re-derived by a fresh-context subagent.

The real problem usually isn't the model's reasoning — it's the **polluted
context** it keeps conditioning on (stale assumptions, dead ends, its own prior
commitments). `bonk` is about re-grounding that context, not scolding the model.

## Usage ritual

`bonk` runs *after* you've stopped the agent (a slash command can't interrupt a
running turn — only `Esc` can):

```
Esc            # stop the wrong-path execution immediately
(Esc Esc       # optional: rewind to undo bad edits
 or /rewind)
/bonk [hint]   # re-ground on the clean state
```

## Commands

- **`/bonk [optional hint]`** — emits a structured re-grounding report (goal
  restatement, per-assumption confidence ledger, divergence point, dismissed
  alternatives, artifact inventory) and a verdict: continue-in-place, or restart.
  On restart, a fresh-context subagent re-derives the approach blind to the bad
  turns; you approve, and it persists a clean brief.
- **`/bonk:resume`** — after you `/clear`, rehydrates the clean brief into the
  fresh context and continues from the corrected approach.

## Status

Design phase. See [the design spec](docs/superpowers/specs/2026-06-16-bonk-design.md).
