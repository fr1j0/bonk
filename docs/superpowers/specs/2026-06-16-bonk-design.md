# bonk — design spec

**Date:** 2026-06-16
**Status:** Design approved (sections), pending written-spec review
**Plugin name:** `bonk` (commands `/bonk`, `/bonk:resume`)

## Problem

Engineers using Claude Code daily hit a recurring failure mode: the agent commits
to a wrong path, makes an unexamined assumption early, and then compounds it —
defending the wrong approach turn after turn instead of reconsidering. Ad-hoc
"you're wrong, stop" messages tend to produce performative agreement followed by
the same trajectory, because the real problem isn't the model's reasoning — it's
the **polluted context** the model keeps conditioning on (stale assumptions, dead
ends, its own prior commitments).

`bonk` is a pattern-interrupt and context re-grounding tool: a fast, consistent
way to halt the wrong path, audit what the agent is actually assuming, and — when
the context is too far gone — restart from a clean, verified problem statement
derived by a fresh-context subagent.

## Core insight

The lever is **context re-grounding**, not "reason better" (the weights don't
degrade mid-session; the context does). The tool's stance is therefore: *treat
all accumulated context as suspect, separate verified facts from guesses, and be
willing to throw the polluted context away entirely.*

## Scope of this tool vs. the harness

`bonk` cannot stop a running turn and cannot clear the session — both are
harness-level actions reserved to the user by design. `bonk` runs *after* the
engineer has stopped the agent. The usage ritual is three steps:

```
Esc            ← stop the wrong-path execution immediately (keeps work so far)
(Esc Esc       ← optional: open rewind to undo bad edits — see Rewind notes)
 or /rewind)
/bonk [hint]   ← now re-ground on the clean state
```

### Verified harness facts (Claude Code, 2026-06; official docs)

- **`Esc` once** interrupts mid-turn and keeps work done so far. This is the only
  reliable immediate stop.
- **Rewind** is invoked by **`Esc Esc`** (only when the input box is empty) or the
  **`/rewind`** command. Restore is three-way selectable: *code + conversation*,
  *conversation only*, or *code only*. Checkpoints are auto-created per user
  prompt and retained 30 days by default.
- **Rewind coverage caveat:** code-restore only covers files edited through
  Claude's edit tools. It does **not** undo bash side-effects (`rm`/`mv`/generated
  files), external edits, or untracked files.
- **Queued messages:** a message/slash-command typed while the agent runs is read
  at the next decision boundary, not necessarily after the whole turn — so a long
  execution must hit a boundary first. This is why typing `/bonk` mid-run feels
  like "it won't listen." Use `Esc`.

## Components

### Command 1 — `/bonk [optional hint]`

Fires the interrupt and emits a **structured re-grounding report**. Does not
defend prior work. Accepts an optional free-text hint (`/bonk "you keep assuming
Postgres"`) that seeds the analysis as a *lead*, never as gospel — if the hint
contradicts the evidence, the report surfaces the conflict.

Report sections:

1. **Goal restatement** — the original objective in the agent's own words.
   Catches silent goal-drift first.
2. **Assumption ledger** — the core component. Each assumption is a row:
   - *Source*: `from-user` / `from-file` / `inferred` / `guessed`
   - *Confidence*: `High` / `Medium` / `Low` (coarse buckets — no fake
     percentages; the model has no calibrated probability to report)
   - *Evidence*: what it rests on, and what would flip it
3. **Divergence point** — the last moment the agent was definitely on track, and
   the turn that introduced the bad fork. The hint seeds this.
4. **Dismissed alternatives** — 2–3 interpretations/approaches previously rejected
   or never considered.
5. **Artifact inventory** — files/functions touched on the suspected wrong path,
   with *suggested* (never executed) undo commands. Undo guidance:
   - uncommitted edit-tool changes → prefer **rewind** (`/rewind`, code-only)
   - committed changes, or anything **bash** touched → use **git** (`git checkout
     -- <f>`, `git revert <sha>`); rewind cannot undo these
6. **Verdict** — `continue-in-place` vs `restart`, gated mechanically: if any
   **foundational** assumption (the goal or the core approach) scored `Low`,
   recommend `restart`. Leaf-detail uncertainty does not trigger it.

On `continue`: the agent re-grounds in place, explicitly overriding the bad
assumptions, and proceeds. No subagent, no `/clear`.

On `restart`: proceed to the restart flow below.

### Confidence model (design rationale)

LLM self-reported confidence is poorly calibrated and systematically
overconfident — exactly the situation `bonk` exists to catch. So:

- Confidence is **per-assumption**, never a single global score (the per-row
  distribution is the diagnostic — it points at *which* assumption is shaky).
- **Coarse buckets** only (`High`/`Med`/`Low`), no percentages.
- **Evidence-backed** — every score carries "what it's based on" + "what flips
  it," which forces grounding instead of vibes.
- Used as a **gate**, not a deliverable: foundational-`Low` → restart.
- Treated as the model's self-assessment for *locating doubt*, not a trustworthy
  probability.

### The subagent — restart only

Dispatched (Agent/Task tool) with a **clean seed**: the distilled problem
statement — goal + verified (`from-user`/`from-file`) facts only — stripped of
every `inferred`/`guessed` assumption and all wrong-turn history. Blind to the
pollution, it independently re-derives the correct approach.

It returns a **lean** result, not a full plan: goal, a fresh verified-fact
ledger, and a **short corrected approach (a few bullets)**. Detailed
step-by-step planning is deliberately *not* done here — a full plan produced
before `/clear` would land back in polluted context and be redone anyway.
Detailed planning happens in the fresh post-`/clear` session (where writing-plans
can run on clean context). Keeping the subagent output lean avoids that waste.

### Approval gate

Designed around how engineers actually work at the moment of frustration:
high-signal, low-ceremony, human-in-the-loop only on what matters.

- **Present the delta, not just the brief.** Show the subagent's clean ledger as
  *kept / dropped / contradicted* against the original polluted ledger, with
  **contradictions front and center**. A blind subagent rejecting an assumption is
  the signal that confirms the wrong turn — that delta is the core payload.
- **Approval = editing the file.** The engineer edits `.bonk/clean-brief.md`
  directly and confirms. Deterministic, matches engineer muscle memory, and they
  know the verified facts better than any agent. Re-dispatching the subagent is
  available but is the **escape hatch** for "the whole approach is wrong" — not the
  default loop (re-running a stochastic agent is slow and non-deterministic).
- **Gate provenance, not leaves.** The one human-only check: confirm each entry in
  `verified_facts` is *actually* `from-user`/`from-file`, not a guess the subagent
  re-laundered as fact (it inherits the same "confidently wrong" tendency). The
  gate foregrounds `verified_facts` + sources and the foundational approach; it
  does not ask the engineer to approve every leaf detail.

Nothing persists until explicit confirm.

### Persist — `.bonk/clean-brief.md`

On approval, write the brief to disk. This is the single artifact that crosses
the `/clear` boundary, so it must be self-contained:

```
{
  goal:              restated objective
  verified_facts:    [ {fact, source} ]   # from-user / from-file only
  corrected_approach: [ ... ]              # a few bullets, NOT a full plan
  do_not_redo:       [ ... ]               # from the artifact inventory
}
```

The detailed step-by-step plan is intentionally absent — it is produced in the
fresh post-`/clear` session via writing-plans, on clean context.

(`.bonk/` is gitignored.)

### Command 2 — `/bonk:resume`

Run after the engineer hits `/clear`. Reads `.bonk/clean-brief.md` into the fresh
main context and continues from the corrected plan. Same persist → `/clear` →
rehydrate idiom as `/bit:resume`.

## Data flow

### Light path (`continue` verdict)

```
on a questionable path → /bonk [hint] → re-grounding report
  → verdict: continue-in-place → re-ground in place, override bad assumptions, proceed
```

### Heavy path (`restart` verdict)

```
/bonk [hint] → report → verdict: restart (foundational assumption scored Low)
  → distill CLEAN SEED (goal + verified facts only)
  → dispatch fresh-context subagent → returns clean ledger + corrected plan
  → approval gate (engineer edits/approves; reject loops back)
  → write .bonk/clean-brief.md
  → print: "Brief saved. Run /clear, then /bonk:resume."
  → [engineer hits /clear  ← only manual step]
  → /bonk:resume → reads brief into fresh context → continues from clean plan
```

The single manual step in the entire flow is the `/clear` keystroke (harness
boundary). Everything else is automated.

## Edge cases

- **No git repo** → artifact inventory degrades to "files touched this session,"
  no git revert commands; no hard git dependency. (Rewind guidance still applies.)
- **`/bonk:resume` with no brief file** → clear message ("no pending brief; run
  `/bonk` first"), no crash.
- **Stale brief** → resume treats the existing brief as active and proceeds; a new
  `/bonk` restart overwrites it. Single-slot, last-write-wins; no brief history in
  v1.
- **Hint contradicts evidence** → report surfaces the conflict rather than trusting
  the hint.
- **Bash side-effects on the wrong path** → flagged in the artifact inventory as
  *not* rewind-undoable; git-only.

## Out of scope (v1) / future

- **Auto-revert of wrong-path artifacts.** v1 is identify-only — list + suggest,
  never execute. Reasoning: the command is fired precisely when the agent's
  judgment is suspect; letting that judgment do destructive git surgery on
  interleaved good/bad changes is backwards, and a frustration-fired tool must be
  safe to invoke reflexively. Auto-revert is a possible v2, gated behind explicit
  confirmation and limited to changes wholly attributable to the bad path.
- **Brief history / multiple slots.** v1 is single-slot last-write-wins (YAGNI).
- **No descriptive alias.** Decided: pure `/bonk`, no `/recenter` alias. The name
  is the identity.

## Open items

- Plugin packaging mirrors bitácora: `.claude-plugin/marketplace.json` +
  `plugins/bonk/commands/{bonk.md, resume.md}`. Finalize in the implementation
  plan.
