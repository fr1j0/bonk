# bonk 🔨

<!-- the real ones -->
![status](https://img.shields.io/badge/status-design%20phase-orange)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)](https://docs.claude.com/en/docs/claude-code)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](https://github.com/fr1j0/bonk/issues)

<!-- the honest ones -->
![stop energy](https://img.shields.io/badge/stop%20energy-maximum-red)
![vibes](https://img.shields.io/badge/vibes-rechecked-ff69b4)
![context](https://img.shields.io/badge/context-freshly%20cleared-success)
![powered by](https://img.shields.io/badge/powered%20by-the%20Esc%20key-lightgrey)
![works on](https://img.shields.io/badge/works%20on-my%20machine-yellow)
![agents bonked](https://img.shields.io/badge/agents%20bonked-%E2%88%9E-blueviolet)
![sycophancy](https://img.shields.io/badge/%22you're%20absolutely%20right%22-blocked-critical)

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

> Note: `/rewind` only undoes edits made by Claude's edit tools — not bash
> side-effects (`rm`/`mv`/generated files), which need git.

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
