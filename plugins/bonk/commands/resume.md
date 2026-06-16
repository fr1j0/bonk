---
description: After /clear, rehydrate the clean brief from a /bonk:it restart and continue from the corrected approach on fresh context.
---

You are resuming after a `/bonk:it` restart and a `/clear`. Your context is
intentionally fresh — the polluted history is gone. The clean brief is now your
single source of truth. Do NOT try to reconstruct or second-guess the discarded
history.

## Step 1 — Load and validate the brief

Run:

    bash "${CLAUDE_PLUGIN_ROOT}/scripts/brief-validate.sh"

- Exit 3 (no brief): tell the user "No clean brief found — run `/bonk:it` first to
  produce one." Then stop.
- Exit 4 (malformed): report which section the script said is missing, and ask the
  user to fix `.bonk/clean-brief.md`. Then stop.
- Exit 0: the script prints the brief path. Read that file.

## Step 2 — Rehydrate

Read the brief file at the path the script printed (by default
`.bonk/clean-brief.md`) and internalize:
- the **Goal** as your objective,
- the **Verified facts** as the ONLY established facts (treat nothing else as
  known),
- the **Corrected approach** as your starting direction,
- **Do not redo** as paths/work to avoid repeating.

## Step 3 — Plan on clean context

Now produce the DETAILED plan — deliberately deferred to here, where your context
is clean. If the `superpowers:writing-plans` skill is available and the work is
multi-step, use it. Otherwise lay out concrete next steps. Confirm with the user
before executing.
