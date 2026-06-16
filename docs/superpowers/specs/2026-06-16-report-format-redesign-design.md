# Design: Re-grounding report format redesign (BLUF + severity-led)

Date: 2026-06-16
Status: Approved design, pre-implementation
Scope: `plugins/bonk/commands/it.md` (Step 2 report + confidence legend). Prompt-only — no script changes.

## Problem

When `/bonk:it` fires on a drifting direction, the re-grounding report is hard for
the engineer to follow. Three compounding pains, all confirmed by the user:

1. **Conclusion is buried.** The report is emitted in the model's *reasoning* order
   — Goal → Assumption ledger → Divergence → Dismissed alternatives → Artifact
   inventory → **Verdict**. The actual answer (verdict + which assumptions are
   wrong + what to do) sits last, after five sections of analysis.
2. **Too much total text.** Every section renders at full length even when empty
   or trivial (clean working tree, no dismissed alternatives, etc.).
3. **Hard to scan visually.** A dense 4-column assumption table (Assumption /
   Source / Confidence / Evidence) does not surface the load-bearing rows; the
   reader cannot eyeball what is actually wrong.

Constraint: the report renders as **markdown in a terminal**. There are no
collapsible sections — "progressive disclosure" can only mean output *order*
(summary first, detail after) plus *trimming*. No click-to-expand.

## Goal

Restructure the Step 2 report so the engineer gets the bottom line in the first few
lines, the load-bearing problems are visually scannable, and supporting detail is
trimmed to one-liners (expanded only when it carries real information) — without
removing any reasoning the verdict depends on.

## Design

The report is emitted in **reading order, not reasoning order**: Bottom line →
Load-bearing problems → Supporting context. The model still reasons in whatever
order it needs internally; this governs only the order of the emitted sections.
After the report, routing to the verdict path (Step 3a `continue-in-place` /
Step 3b `restart`) is unchanged.

### Section 1 — Bottom line (always first, visually set off)

Three lines, nothing else:

```
■ BOTTOM LINE
  Verdict: RESTART — a foundational assumption is Low-confidence.
  Wrong:   🔴 assumed FastAPI service has API-key auth — it has none to key on.
  Do now:  add an API-key layer first, else the limiter silently degrades to per-IP.
```

- **Verdict:** `RESTART` or `CONTINUE`, plus a half-line reason.
- **Wrong:** the 1–3 load-bearing bad assumptions, each prefixed with its
  confidence icon, one clause each.
- **Do now:** the single most important corrective action.

On `CONTINUE`, "Wrong" lists the assumptions being discarded and "Do now" is the
corrected one-liner before proceeding.

### Section 2 — Load-bearing problems (severity-sorted blocks)

Replaces the 4-column table as the primary view. A block is rendered only for
assumptions that are **load-bearing AND not High-confidence**, sorted worst-first
(🔴 before 🟡). Each block:

```
① 🔴 service has per-caller API keys to limit on
   guessed — no key handling anywhere; app/main.py has one unauthenticated route
   flips: a key scheme elsewhere in the repo (there is none)
```

Line 1: number + icon + the assumption stated plainly.
Line 2: `<source>` (`from-user` | `from-file` | `inferred` | `guessed`) — why it's
shaky, one line.
Line 3: `flips:` — what evidence would confirm or kill it.

The trusted facts collapse to a single line beneath the blocks, so suspect-vs-solid
is visible at a glance:

```
Solid: (from-user) 100 req/min per key · (from-file) slowapi in requirements, no Redis
```

If there are no load-bearing non-High assumptions (nothing actually wrong), there
are no blocks — the model says so plainly rather than manufacturing a problem
(consistent with the existing "don't manufacture a fork" framing).

### Section 3 — Supporting context (trimmed one-liners, below a divider)

One line each; **omit any line that is empty**:

```
─────────────────────────────────────
Goal:       add per-API-key rate limiting (100/min) to the FastAPI service
Divergence: pattern-matched "API + rate limit" → Express, never verified the stack
Dismissed:  per-IP limiting · fastapi-limiter (Redis-native)
Artifacts:  clean — nothing to undo
```

- **Goal:** one sentence; prepend a `⚠ drift:` note only if the goal drifted from
  what the user asked.
- **Divergence:** the one decision/turn that introduced the fork. One line.
- **Dismissed:** alternatives not considered, `·`-separated. Omit the line entirely
  when there are none.
- **Artifacts:** the one-liner `clean — nothing to undo` when the working tree is
  clean. Expands to the **full file list + undo guidance** (`/rewind` for
  uncommitted edits; `git checkout`/`git revert` for committed or bash-created
  changes) **only** when wrong-path residue actually exists.

### Confidence legend

🔴 Low · 🟡 Medium · 🟢 High — coarse buckets only, **never percentages** (existing
rule, unchanged). Icons map 1:1 to the existing Low/Medium/High buckets.

## Out of scope (explicitly unchanged)

- **Verdict rule:** any foundational assumption (goal or core approach) at `Low`
  confidence → `restart`; otherwise `continue-in-place`.
- **Restart flow:** clean seed → blind subagent → delta → draft brief → gate. The
  #18 gate-prominence fix and the #19 ambiguity clarify-gate are untouched. The
  subagent **delta** keeps contradictions-first and adopts the same 🔴/🟡/🟢
  vocabulary for visual consistency — no structural change.
- **Draft-brief template:** the four `##` headers (`Goal` / `Verified facts` /
  `Corrected approach` / `Do not redo`) are validated by `brief-validate.sh` and
  are **not** redesigned.
- **Source-tagging discipline:** anything not directly read/told stays `inferred`
  or `guessed`.
- **Scripts and tests:** no changes. No test asserts on report prose.

## Versioning

Minor bump `0.2.2` → `0.3.0` (visible output change, backward-compatible: brief
template and scripts unchanged). On landing in `main`, tag + push `v0.3.0` per the
maintainer's standing release-tag preference.

## Risks / open considerations

- The icons (🔴/🟡/🟢) and box/divider glyphs (`■`, `─`) must render acceptably in
  the target terminals. They are plain Unicode already common in CLI output; low
  risk, but worth an eyeball during the dogfood.
- "Reading order, not reasoning order" is a presentation instruction; the prompt
  must be explicit that internal analysis order is unconstrained, only the emitted
  section order is fixed — so the model does not skip the analysis to reach the
  Bottom line faster.

## Verification

- All existing tests still pass (`plugins/bonk/scripts/test.sh`) — they exercise
  scripts, not prose, so they should be unaffected.
- Manual dogfood from a consuming repo: run `/bonk:it` on a genuinely drifted
  session and confirm the Bottom line appears first, problems are severity-sorted
  and icon-marked, and empty supporting lines are omitted.

---

## Revision 2026-06-16 — rich-markdown look (supersedes the monospace layout above)

After visually validating the monospace version, we switched the report to a
**rich-markdown** presentation, tuned for human readability. The reading-order
principle, severity-led problems, trimmed context, and all out-of-scope guarantees
(verdict rule, #18 gate, #19 clarify-gate, brief template) are UNCHANGED — only the
visual rendering changed. Final skeleton:

    # 🧭 Drift check
    **Cause —** <one plain sentence: what pulled the work off course; that the user triggered this>

    ---

    > ## 🛑 Verdict — START OVER (clean slate)        (RESTART)
    > <2–3 plain sentences, NO jargon — never "re-ground"/"brief"/"context window">
    >
    > **What's wrong** — <bad assumption(s)>
    > **The fix** — <corrective action>
    > **How the restart happens** — save a summary → you `/clear` → `/bonk:resume` reloads it

    ---

    ### ⚖️ Load-bearing problems
    **🔴 ①  <assumption>**
    > <source> — <why shaky>
    > *flips:* <what would confirm/kill it>

    ✅ **Solid** — (from-user) <fact> · (from-file) <fact>

    ---

    ### 📋 Context   (2-column table; omit empty rows)

Key human-readability decisions, all from live review:

- **Title + Cause first.** `# 🧭 Drift check` frames *what this is*; the `Cause —`
  line states *why it fired* in one plain sentence — before the verdict.
- **No jargon in the verdict.** The bare token `RESTART`/`CONTINUE` is internal-only
  (drives routing to Step 3b/3a). The human sees a plain action: **START OVER
  (clean slate)** / **KEEP GOING (just fix one thing)**, and for START OVER the
  callout spells out the mechanic (save summary → `/clear` → `/bonk:resume`) without
  insider words.
- **Verdict as a blockquote callout** with a 🛑/✅ colour cue — the eye lands on it
  first.
- **Problems stay scannable blocks** (bold title + 🔴/🟡, detail in a quote, a
  `flips:` line) — deliberately NOT a table, since the dense assumptions-table was
  the original complaint. The `Context` reference info DOES use a 2-column table.
- **`---` rules between blocks** (but NOT above the title) for clear visual bands.

The golden sample `plugins/bonk/scripts/preview-report.sh` now emits this markdown
and renders it through `glow`/`mdcat`/`bat` when available (raw fallback otherwise).
`test-report-format-drift.sh` markers updated to the new vocabulary.
