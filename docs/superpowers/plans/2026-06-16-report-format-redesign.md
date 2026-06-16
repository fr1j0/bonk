# Re-grounding Report Format Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the `/bonk:it` re-grounding report so the engineer reads the bottom line first, sees load-bearing problems as scannable severity blocks, and gets trimmed one-liner context — without dropping any reasoning the verdict depends on.

**Architecture:** Prompt-only edit to `plugins/bonk/commands/it.md`. Replace the whole of "Step 2 — Produce the re-grounding report" with a reading-order layout (Bottom line → Load-bearing problems → Supporting context → Verdict rule), preserving the #19 clarify-gate. Give the restart-flow delta the same icon vocabulary. Bump version 0.2.2 → 0.3.0.

**Tech Stack:** Markdown command file (terminal-rendered); bash test harness (`plugins/bonk/scripts/test.sh`).

**Spec:** `docs/superpowers/specs/2026-06-16-report-format-redesign-design.md`

---

## File Structure

- Modify: `plugins/bonk/commands/it.md` — replace Step 2; add icon vocabulary to the Step 3b delta.
- Modify: `plugins/bonk/.claude-plugin/plugin.json` — version `0.2.2` → `0.3.0`.
- Modify: `.claude-plugin/marketplace.json` — plugin `version` `0.2.2` → `0.3.0`.
- No script or test files change. No test asserts on report prose.

---

### Task 1: Replace Step 2 with the reading-order report

**Files:**
- Modify: `plugins/bonk/commands/it.md` (the section beginning `## Step 2 — Produce the re-grounding report` through the end of its item `6. **Verdict**`, i.e. everything up to but not including `## Step 3a — If verdict is \`continue-in-place\``)

- [ ] **Step 1: Replace the Step 2 section**

Replace the entire current Step 2 block (the `## Step 2 — Produce the re-grounding report` heading and its numbered items 1–6, including the #19 "Clarify before committing" paragraph currently under item 3) with EXACTLY this text:

````markdown
## Step 2 — Produce the re-grounding report

Reason in whatever order you need internally, but EMIT the report in this reading
order: bottom line first, analysis after. Do NOT skip the analysis to reach the
bottom line faster — the verdict must be earned by the ledger beneath it.

Confidence icons (coarse buckets only — NEVER percentages): 🔴 Low · 🟡 Medium · 🟢 High.

### 1. Bottom line — emit FIRST, set off as its own block

    ■ BOTTOM LINE
      Verdict: RESTART | CONTINUE — <half-line reason>
      Wrong:   <icon> <the 1–3 load-bearing bad assumptions, one clause each>
      Do now:  <the single most important corrective action>

On `CONTINUE`, "Wrong" lists the assumptions you are discarding and "Do now" is the
corrected understanding in one line before you proceed.

### 2. Load-bearing problems — severity-sorted blocks

For each assumption that is load-bearing AND not 🟢 High-confidence, worst first
(🔴 before 🟡), emit a three-line block:

    ① 🔴 <assumption, stated plainly>
       <source> — <why it's shaky, one line>
       flips: <what evidence would confirm or kill it>

- `<source>` ∈ {from-user, from-file, inferred, guessed}. Be ruthless: anything you
  did not directly read or get told is `inferred` or `guessed`, not
  `from-file`/`from-user`.
- If nothing is both load-bearing AND shaky (nothing is actually wrong), say so
  plainly — do NOT manufacture a problem to fill this section.

Then collapse the trusted facts to ONE line so suspect-vs-solid is clear at a glance:

    Solid: (from-user) <fact> · (from-file) <fact>

### 3. Supporting context — trimmed one-liners below a divider

Emit each line only if it carries information; OMIT any empty line:

    ─────────────────────────────────────
    Goal:       <one sentence; prefix "⚠ drift:" only if it drifted from the ask>
    Divergence: <the one turn/decision that introduced the suspected wrong fork>
    Dismissed:  <2–3 alternatives never seriously considered, "·"-separated>
    Artifacts:  clean — nothing to undo

`Artifacts` shows the one-liner above when the working tree is clean. Expand it to
the full file list + undo guidance ONLY when wrong-path residue exists:

- uncommitted edits made by your edit tools → `/rewind` (code-only restore).
- committed changes, or anything a bash command created/moved → git
  (`git checkout -- <file>` / `git revert <sha>`); `/rewind` cannot undo these.

### Verdict rule

The Bottom line's verdict follows this rule: if any FOUNDATIONAL assumption (the
goal itself, or the core approach) is 🔴 Low confidence → `RESTART`. Otherwise →
`CONTINUE`. Then go to the matching step below.

Clarify before committing: if the hint is vague (names no specific fork) AND more
than one 🔴 Low-confidence foundational fork is plausible, do NOT pick one silently.
List the candidate divergence points (one line each) and ask the user which they
mean before settling the verdict. When the hint clearly points at one fork, or only
one Low-confidence fork exists, pick it and proceed — do not ask. (If the evidence
shows no wrong turn at all, say so — don't manufacture one to match the hint.)
````

- [ ] **Step 2: Verify the structural markers are present**

Run:
```bash
cd ~/Projects/bonk
grep -c "■ BOTTOM LINE" plugins/bonk/commands/it.md
grep -c "🔴 Low · 🟡 Medium · 🟢 High" plugins/bonk/commands/it.md
grep -c "Clarify before committing" plugins/bonk/commands/it.md
```
Expected: each prints `1` (BLUF block present, legend present, #19 clarify-gate preserved).

- [ ] **Step 3: Verify the old table header is gone**

Run:
```bash
grep -c "| Assumption | Source | Confidence" plugins/bonk/commands/it.md
```
Expected: `0` (the dense 4-column table was replaced by severity blocks).

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/bonk
git add plugins/bonk/commands/it.md
git commit -m "feat(it): reading-order report — BLUF + severity-led problem blocks"
```

---

### Task 2: Give the restart-flow delta the icon vocabulary

**Files:**
- Modify: `plugins/bonk/commands/it.md` — Step 3b item `3.` (the subagent DELTA presentation)

- [ ] **Step 1: Update the delta instruction**

Find this text in Step 3b (item 3):

```markdown
3. Present the subagent's result as a DELTA against your original assumption
   ledger: **kept / dropped / contradicted**, with contradictions FIRST — a blind
   subagent contradicting you is the strongest signal you took a wrong turn.
```

Replace it with:

```markdown
3. Present the subagent's result as a DELTA against your original assumption
   ledger: **kept / dropped / contradicted**, with contradictions FIRST — a blind
   subagent contradicting you is the strongest signal you took a wrong turn. Use the
   same confidence icons as the report (🔴 Low · 🟡 Medium · 🟢 High) so the delta
   reads consistently with Step 2.
```

- [ ] **Step 2: Verify the edit landed**

Run:
```bash
cd ~/Projects/bonk
grep -c "so the delta" plugins/bonk/commands/it.md
```
Expected: `1`.

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/bonk
git add plugins/bonk/commands/it.md
git commit -m "feat(it): align restart delta with report confidence icons"
```

---

### Task 3: Version bump to 0.3.0

**Files:**
- Modify: `plugins/bonk/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Bump plugin.json**

In `plugins/bonk/.claude-plugin/plugin.json`, change:
```json
  "version": "0.2.2",
```
to:
```json
  "version": "0.3.0",
```

- [ ] **Step 2: Bump marketplace.json**

In `.claude-plugin/marketplace.json`, change the plugin entry's:
```json
      "version": "0.2.2",
```
to:
```json
      "version": "0.3.0",
```

- [ ] **Step 3: Verify both bumped**

Run:
```bash
cd ~/Projects/bonk
grep '"version"' plugins/bonk/.claude-plugin/plugin.json
grep '"version"' .claude-plugin/marketplace.json
```
Expected: both show `0.3.0`.

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/bonk
git add plugins/bonk/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump bonk to 0.3.0"
```

---

### Task 4: Regression-test and open the PR

**Files:** none (verification + PR)

- [ ] **Step 1: Run the full test suite**

Run:
```bash
cd ~/Projects/bonk
bash plugins/bonk/scripts/test.sh
```
Expected: all 9 tests PASS (3 artifact-inventory, 3 brief-validate, 2 lib; suite exercises scripts only, so the prose change must not affect them).

- [ ] **Step 2: Push the branch**

```bash
cd ~/Projects/bonk
git push -u origin feat/report-bluf-redesign
```

- [ ] **Step 3: Open the PR**

```bash
cd ~/Projects/bonk
gh pr create --base main --head feat/report-bluf-redesign \
  --title "feat(it): reading-order re-grounding report (BLUF + severity blocks)" \
  --body "Implements docs/superpowers/specs/2026-06-16-report-format-redesign-design.md. Replaces the reasoning-order report (Goal→ledger→...→verdict) with reading order: Bottom line → severity-sorted problem blocks → trimmed context. Preserves the verdict rule, #18 gate fix, #19 clarify-gate, and the 4-header brief template. Version 0.3.0. All 9 tests pass."
```

- [ ] **Step 4: Manual dogfood (post-merge or on branch)**

From a consuming repo (e.g. `~/Projects/bonk-dogfood`), with bonk at 0.3.0, run `/bonk:it` on a genuinely drifted session and confirm by eye:
- the `■ BOTTOM LINE` block is the FIRST thing emitted;
- problems are severity-sorted (🔴 before 🟡) and icon-marked;
- empty supporting-context lines (e.g. `Dismissed`, `Artifacts` when clean) are omitted;
- icons/glyphs render acceptably in the terminal.

This step is observational — no automated assertion.

---

## Notes for the executor

- This is a **prompt** change: the "tests" are the structural greps in Tasks 1–2 plus the unchanged script suite in Task 4. There is no unit test for report prose, by design.
- Do NOT touch the draft-brief template (the four `##` headers in Step 3b item 4) — `brief-validate.sh` depends on it.
- Do NOT merge in this plan; opening the PR is the last automated step. The maintainer reviews/merges, then tags `v0.3.0`.
