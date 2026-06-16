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

Output these sections, in order:

1. **Goal** — restate the user's original objective in one sentence, in your own
   words. If it has drifted from what they actually asked for, flag the drift.

2. **Assumption ledger** — a table of every assumption currently load-bearing in
   your approach, one row each:

   | Assumption | Source | Confidence | Evidence / what would flip it |

   - Source ∈ {from-user, from-file, inferred, guessed}.
   - Confidence ∈ {High, Medium, Low} — coarse buckets only, NEVER percentages
     (you have no calibrated probability to report).
   - Be ruthless: anything you did not directly read or get told is `inferred` or
     `guessed`, not `from-file`/`from-user`.

3. **Divergence point** — the last moment you were definitely on track, and the
   turn or decision that introduced the suspected wrong fork. Use the hint as a
   lead.

4. **Dismissed alternatives** — 2–3 interpretations or approaches you previously
   rejected or never seriously considered. State each plainly.

5. **Artifact inventory** — the files from Step 1 attributable to the suspected
   wrong path. **Identify only — do NOT run any destructive or undo command
   yourself.** For undo, advise the user:
   - uncommitted edits made by your edit tools → `/rewind` (code-only restore).
   - committed changes, or anything a bash command created/moved → git
     (`git checkout -- <file>` / `git revert <sha>`); `/rewind` cannot undo these.

6. **Verdict** — decide `continue-in-place` vs `restart`:
   - If any FOUNDATIONAL assumption (the goal itself, or the core approach) is
     `Low` confidence → `restart`.
   - Otherwise → `continue-in-place`.

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
   subagent contradicting you is the strongest signal you took a wrong turn.

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
