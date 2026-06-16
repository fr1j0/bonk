---
description: Pattern-interrupt — stop the wrong path, audit assumptions, and (if needed) restart from clean context via a fresh-context subagent.
---

You are being invoked because the user believes you have gone down a wrong path
and may be defending it. Treat ALL accumulated context as suspect. Do NOT defend
prior work. Your job is to re-ground, not to reassure. Avoid agreement theater
("you're absolutely right") — show the re-grounding instead.

Optional user hint (a lead, NOT gospel — if it conflicts with the evidence, say
so explicitly):

Arguments: $ARGUMENTS

## Step 1 — Gather deterministic context

Run the artifact inventory (lists working-tree changes):

    bash "${CLAUDE_PLUGIN_ROOT}/scripts/artifact-inventory.sh"

If it prints `NO_GIT`, there is no git repo — enumerate the files you touched this
session from your own memory instead.

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

## Step 3a — If verdict is `continue-in-place`

Explicitly list which bad assumptions you are discarding, restate the corrected
understanding in a sentence or two, and proceed with the task. Do NOT spawn a
subagent. Stop here.

## Step 3b — If verdict is `restart`

1. Distill a CLEAN SEED: the goal + ONLY the `from-user`/`from-file` facts. Strip
   every `inferred`/`guessed` assumption and all wrong-turn narrative.

2. Dispatch a subagent (Task/Agent tool, `general-purpose`) whose ENTIRE context
   is the clean seed. Instruct it to re-derive the correct approach BLIND to your
   prior work and return ONLY:
   - a restated goal,
   - a fresh verified-fact ledger,
   - a `corrected_approach` of a FEW bullets (NOT a full step-by-step plan).

3. Present the subagent's result as a DELTA against your original assumption
   ledger: **kept / dropped / contradicted**, with contradictions FIRST — a blind
   subagent contradicting you is the strongest signal you took a wrong turn. Use the
   same confidence icons as the report (🔴 Low · 🟡 Medium · 🟢 High) so the delta
   reads consistently with Step 2.

4. Present the DRAFT brief as a formatted block — **do NOT write any file yet** —
   filling in EXACTLY this template (the resume command validates these four
   `##` headers):

       # bonk clean brief

       ## Goal
       <one sentence>

       ## Verified facts
       - (from-user) <fact>
       - (from-file) <fact>

       ## Corrected approach
       - <bullet>

       ## Do not redo
       - <artifact-inventory note>

5. Ask the user to review and edit the draft directly. The one thing they MUST
   check is verified-fact PROVENANCE: confirm each "verified fact" is genuinely
   from-user/from-file, not a guess re-dressed as fact. Re-dispatching the
   subagent is only for when the whole approach is wrong — it is not the default
   loop. Write the file ONLY after the user explicitly confirms.

   Make the required action unmistakable. End your message with the action as the
   LAST thing, on its own line, set off as a blockquote — never trailing in prose.
   Any open questions you have go in the body ABOVE it and must be framed as
   optional ("answer inline if useful — they don't block confirming"), so they
   never compete with the action. Use exactly:

   > **Action:** reply `confirm` to write the brief — or reply with edits.
   > (Re-dispatch the subagent only if the whole approach is wrong.)

6. On explicit confirmation, write the final (possibly user-edited) brief to
   `.bonk/clean-brief.md`, then tell the user verbatim:

   > Brief saved to `.bonk/clean-brief.md`. Run `/clear`, then `/bonk:resume`.
