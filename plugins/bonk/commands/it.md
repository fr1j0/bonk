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

Reason in whatever order you need internally, but EMIT the report in the reading
order of the skeleton below. Render it as RICH MARKDOWN — it is shown to a human in a
terminal, so make it scannable: open and close with the fenced banner bands so the
report can't get lost in log output, lead with the verdict, use the monochrome
confidence glyphs, and keep the grid cells terse. Do NOT skip the analysis to reach
the verdict faster — the verdict must be earned by the problems beneath it.

Confidence glyphs (coarse buckets only — NEVER percentages): `○` Low · `◐` Medium · `●` High.

Source tags: `<source>` ∈ {from-user, from-file, inferred, guessed}. Be ruthless —
anything you did not directly read or get told is `inferred` or `guessed`, not
`from-file`/`from-user`.

Before emitting anything, resolve an ambiguous fork: if the hint is vague (names no
specific fork) AND more than one `○` Low-confidence foundational fork is plausible, do
NOT pick one silently — list the candidate divergence points (one line each) and ask
the user which they mean before producing the report. When the hint clearly points at
one fork, or only one Low-confidence fork exists, pick it and proceed. (If the evidence
shows no wrong turn at all, say so — don't manufacture one to match the hint.)

The verdict is internally `RESTART` or `CONTINUE` (see the Verdict rule below) — it is
shown to the human ONLY as the plain-language banner + header, never as the bare token.
Emit the report using EXACTLY this skeleton (the skeleton shows the `RESTART` form);
the banner bands are fenced code blocks:

<!-- Editor note: the skeleton below is indented 4 spaces, so it is a literal
     code block — the inner ``` fences are characters to reproduce, not active
     fences. Keep the 4-space indent; do not "tidy" it away. -->

    ```
    ═══════════  b o n k . i t  ·  ↺ DRIFT CHECK  ═══════════
    ```

    ## ↺ START OVER — <one plain-language headline; the call in a few words>

    > <2–3 plain sentences: the call and why. NO jargon — never "re-ground", "brief", or "context window".>

    **What's wrong** — <the load-bearing bad assumption(s), in plain words>
    **The fix** — <the corrective action>
    **Restart path** — save confirmed facts + corrected plan to a file → `/clear` → `/bonk:resume` reloads it, so the wrong assumption doesn't follow along.

    ### ▌Load-bearing problems

    |  | Assumption | Source | Why shaky → what flips it |
    |---|---|---|---|
    | `○` | <assumption, stated plainly and terse> | `guessed` | <why it's shaky, one line> → flips if <evidence that would confirm or kill it> |
    | `◐` | <assumption, terse> | `inferred` | <one line> → flips if <evidence> |

    `○` low · `◐` med · `●` high confidence

    `✓ solid` (from-user) <fact> · (from-file) <fact>

    ### ▌Context

    **Goal** — <one sentence; prefix "drift:" only if it drifted from the ask>
    **Divergence** — <the one turn/decision that introduced the wrong fork>
    **Dismissed** — <2–3 alternatives never seriously considered, "·"-separated>
    **Artifacts** — clean; nothing to undo

    ```
    ══════════════════════  END · DRIFT CHECK  ═══════════════════
    ```

Skeleton rules:
- **Banner bands.** Open with the top band and close with the bottom band, each as a
  fenced code block so they render as literal monospace scroll-stops. Keep each on ONE
  line; do not pad to terminal width. The top band carries the `b o n k . i t` wordmark
  and the verdict glyph next to `DRIFT CHECK`. On `CONTINUE`, swap the top band's `↺` to
  `▸` so it reads `b o n k . i t  ·  ▸ DRIFT CHECK`.
- **Verdict header.** The skeleton shows the `RESTART` form (`## ↺ START OVER — …`). On
  `CONTINUE`, swap it to `## ▸ KEEP GOING — <headline>`, DROP the `Restart path` line,
  and let `The fix` be the in-place correction you then proceed with.
- **Load-bearing problems.** One ROW per assumption that is load-bearing AND not `●`
  High, worst first (`○` before `◐`). Keep every cell terse — long cells wrap badly in a
  terminal. If nothing is both load-bearing AND shaky (nothing is actually wrong), say so
  plainly in one line instead of an empty grid — do NOT manufacture a problem. Always
  print the `` `○` low · `◐` med · `●` high confidence `` legend under the table. The
  `✓ solid` line collapses the trusted (`●` High) facts to one line.
- **Context.** Labeled rows; omit any row that carries no information. `Artifacts` is
  `clean; nothing to undo` when the tree is clean; expand it to the file list + undo
  guidance ONLY when wrong-path residue exists:
  - uncommitted edits made by your edit tools → `/rewind` (code-only restore).
  - committed changes, or anything a bash command created/moved → git
    (`git checkout -- <file>` / `git revert <sha>`); `/rewind` cannot undo these.

### Verdict rule

If any FOUNDATIONAL assumption (the goal itself, or the core approach) is `○` Low →
`RESTART` (render the `↺ START OVER` banner + header, then go to Step 3b). Otherwise →
`CONTINUE` (render the `▸ KEEP GOING` banner + header, then go to Step 3a).

## Step 3a — If verdict is CONTINUE

Explicitly list which bad assumptions you are discarding, restate the corrected
understanding in a sentence or two, and proceed with the task. Do NOT spawn a
subagent. Stop here.

## Step 3b — If verdict is RESTART

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
   same confidence glyphs as the report (`○` Low · `◐` Medium · `●` High) so the delta
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

6. On explicit confirmation, resolve the canonical brief path — do NOT hand-write
   a relative `.bonk/...` path, which can land in the wrong directory and leave
   `/bonk:resume` unable to find it:

       bash "${CLAUDE_PLUGIN_ROOT}/scripts/brief-path.sh"

   It prints one absolute path (and creates the `.bonk/` directory). Write the
   final (possibly user-edited) brief to that EXACT path, then tell the user
   verbatim:

   > Brief saved to `.bonk/clean-brief.md`. Run `/clear`, then `/bonk:resume`.
