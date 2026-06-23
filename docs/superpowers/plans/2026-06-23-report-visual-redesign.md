# Drift Check Report Visual Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the `/bonk:it` Drift Check report so it reads as a trustworthy instrument — bounding banners with a `b o n k . i t` wordmark, monochrome Unicode icons instead of color emoji, and a scannable grid for load-bearing problems — then ship it as v0.5.0.

**Architecture:** The report is emitted by the model as a markdown message and drawn by Claude Code's own terminal renderer — there is no runtime renderer to theme, so the entire change lives in the LLM-facing format instructions (`commands/it.md`), its hand-maintained golden sample (`scripts/preview-report.sh`), and the drift guard that keeps those two in sync (`scripts/test-report-format-drift.sh`). The report's control flow (artifact inventory → audit → verdict → restart/continue) is untouched; only Step 2's presentation changes. A second task bumps the version across the two manifests and the README.

**Tech Stack:** Markdown (LLM command prompts), POSIX bash (`set -uo pipefail`) for the golden sample and guard tests, JSON manifests. No build step; verification is the bash test suite (`plugins/bonk/scripts/test.sh`) plus `shellcheck`.

## Global Constraints

- **No new runtime dependency.** The format must look right with zero tools installed (no glow/mdcat/bat, no Nerd Font). Universally-available Unicode only.
- **Text-default codepoints only** (so nothing flips to color emoji on macOS): verdict `↺` U+21BA / `▸` U+25B8; confidence `○` U+25CB · `◐` U+25D0 · `●` U+25CF; status `✓` U+2713 · `✗` U+2717; section bar `▌` U+258C; banner rule `═` U+2550. Do NOT use `⚠` U+26A0 or any emoji-presentation glyph.
- **Banner bands stay on one line**, not padded to terminal width.
- **Drift guard is law:** every load-bearing format element must appear verbatim in BOTH `commands/it.md` and `scripts/preview-report.sh`; `test-report-format-drift.sh` enforces it.
- **Version bump 0.4.1 → 0.5.0** must be identical in `plugins/bonk/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (guarded by `check-version-sync.sh`).
- **No AI attribution** in commits (repo + user convention).
- **CI must stay green** on ubuntu-latest and macos-latest: `shellcheck --severity=warning plugins/bonk/scripts/*.sh`, `check-version-sync.sh`, and `test.sh`.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `plugins/bonk/commands/it.md` | LLM instructions defining the report format (Step 2) | Modify (Step 2 skeleton + rules + verdict rule; one glyph reference in Step 3b) |
| `plugins/bonk/scripts/preview-report.sh` | Hand-maintained golden samples (restart + continue) | Modify (both heredocs) |
| `plugins/bonk/scripts/test-report-format-drift.sh` | Marker list that keeps the two in sync | Modify (markers array) |
| `plugins/bonk/.claude-plugin/plugin.json` | Plugin manifest version | Modify (version) |
| `.claude-plugin/marketplace.json` | Marketplace manifest version | Modify (version) |
| `README.md` | Status line + spec link | Modify (version text + spec link) |

---

### Task 1: Restyle the report format (it.md + preview + drift guard)

These three files must change together — the drift guard fails on any intermediate state where `it.md` and the golden sample disagree — so they form one reviewable deliverable.

**Files:**
- Modify: `plugins/bonk/commands/it.md` (Step 2 block, currently lines 24–102; plus the confidence-glyph reference in Step 3b, currently line 125–126)
- Modify: `plugins/bonk/scripts/preview-report.sh` (the `restart_example` and `continue_example` heredocs, currently lines 30–104)
- Modify: `plugins/bonk/scripts/test-report-format-drift.sh` (the `markers` array, currently lines 16–31)
- Test: `plugins/bonk/scripts/test-report-format-drift.sh`, `plugins/bonk/scripts/test-preview-report.sh`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the new format vocabulary that Task 2's README copy references. Marker strings the guard asserts in both files: `b o n k . i t`, `DRIFT CHECK`, `END · DRIFT CHECK`, `START OVER`, `KEEP GOING`, `What's wrong`, `The fix`, `Restart path`, `Load-bearing problems`, `flips if`, `✓ solid`, `Context`, `↺`, `▸`, `○`, `◐`, `●`, `high confidence`.

- [ ] **Step 1: Replace the Step 2 block in `commands/it.md`**

In `plugins/bonk/commands/it.md`, replace everything from the line `## Step 2 — Produce the re-grounding report` through the end of the `### Verdict rule` section (current lines 24–102, i.e. up to and including the line that ends `then go to Step 3a).`) with the following. Note the report skeleton stays indented 4 spaces, exactly like the existing file, and the banner fences inside it are literal:

````text
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
````

- [ ] **Step 2: Update the confidence-glyph reference in Step 3b**

Still in `plugins/bonk/commands/it.md`, find this line inside Step 3b point 3 (currently ~line 125):

```text
   same confidence icons as the report (🔴 Low · 🟡 Medium · 🟢 High) so the delta
```

Replace it with:

```text
   same confidence glyphs as the report (`○` Low · `◐` Medium · `●` High) so the delta
```

- [ ] **Step 3: Rewrite the `restart_example` heredoc in `preview-report.sh`**

In `plugins/bonk/scripts/preview-report.sh`, replace the body between `restart_example() {` `  cat <<'EOF'` and the closing `EOF` (current lines 31–68) so the heredoc content is exactly:

````text
═══════════  b o n k . i t  ·  ↺ DRIFT CHECK  ═══════════
```

## ↺ START OVER — restart from confirmed facts only

> Continuing would stack more work on a foundation that's probably wrong. The load-bearing assumption doesn't hold, so the credible move is to reset to what's verified and rebuild from there.

**What's wrong** — assumed the FastAPI service already has API-key auth. It doesn't, so there's nothing to attach the rate limit to.
**The fix** — add an API-key layer first, or the limiter silently falls back to per-IP.
**Restart path** — save confirmed facts + corrected plan to a file → `/clear` → `/bonk:resume` reloads it, so the wrong assumption doesn't follow along.

### ▌Load-bearing problems

|  | Assumption | Source | Why shaky → what flips it |
|---|---|---|---|
| `○` | Service has per-caller API keys to limit on | `guessed` | No key handling anywhere; one unauthenticated route → flips if a key scheme exists in the repo (there is none) |
| `◐` | slowapi cleanly supports per-key keying | `inferred` | Default `key_func` is per-IP → flips if a custom `key_func` is acceptable |

`○` low · `◐` med · `●` high confidence

`✓ solid` (from-user) 100 req/min per key · (from-file) slowapi in requirements, no Redis

### ▌Context

**Goal** — add per-API-key rate limiting (100/min) to the FastAPI service
**Divergence** — pattern-matched "API + rate-limit" → Express, never verified the stack
**Dismissed** — per-IP limiting · fastapi-limiter (Redis-native)
**Artifacts** — clean; nothing to undo

```
══════════════════════  END · DRIFT CHECK  ═══════════════════
````

> **Heredoc note:** the first line of the heredoc opens the top banner's code fence. Because the example begins with a fenced banner, the file reads `cat <<'EOF'` then a line of ```` ``` ```` (already the heredoc's first content line is the `═══` band — the opening fence ```` ``` ```` precedes it). To avoid confusion, the exact heredoc content, line for line, is: opening fence ```` ``` ````, the `═══ b o n k . i t … ═══` band, closing fence ```` ``` ````, blank line, `## ↺ START OVER …`, and so on through the closing `END · DRIFT CHECK` band wrapped in its own ```` ``` ```` fences. Mirror the structure shown in the it.md skeleton exactly.

- [ ] **Step 4: Rewrite the `continue_example` heredoc in `preview-report.sh`**

Replace the body of the `continue_example` heredoc (current lines 72–103) so its content is exactly:

````text
═══════════  b o n k . i t  ·  ▸ DRIFT CHECK  ═══════════
```

## ▸ KEEP GOING — the plan holds, fixing one thing in place

> The overall plan is sound — no restart needed. I'm dropping the wrong assumption below and continuing right here.

**What's wrong** — assumed the cache TTL is 60s; it's actually 600s (`config/cache.yaml`).
**The fix** — recompute the expiry window with 600s and carry on.

### ▌Load-bearing problems

|  | Assumption | Source | Why shaky → what flips it |
|---|---|---|---|
| `◐` | Cache TTL is 60 seconds | `inferred` | Read the default, not the env override → flips if the config file says otherwise (it's 600s) |

`○` low · `◐` med · `●` high confidence

`✓ solid` (from-user) invalidate on write · (from-file) Redis-backed cache in deps

### ▌Context

**Goal** — add write-through caching to the profile endpoint
**Divergence** — used the 60s default instead of the 600s override when sizing the window
**Artifacts** — clean; nothing to undo

```
══════════════════════  END · DRIFT CHECK  ═══════════════════
````

- [ ] **Step 5: Replace the `markers` array in `test-report-format-drift.sh`**

In `plugins/bonk/scripts/test-report-format-drift.sh`, replace the `markers=( … )` array (current lines 16–31) with:

```bash
markers=(
  "b o n k . i t"
  "DRIFT CHECK"
  "END · DRIFT CHECK"
  "START OVER"
  "KEEP GOING"
  "What's wrong"
  "The fix"
  "Restart path"
  "Load-bearing problems"
  "flips if"
  "✓ solid"
  "Context"
  "↺"
  "▸"
  "○"
  "◐"
  "●"
  "high confidence"
)
```

- [ ] **Step 6: Run the drift guard — expect all markers in both files**

Run: `bash plugins/bonk/scripts/test-report-format-drift.sh; echo "exit=$?"`
Expected: every line `PASS: in both: '<marker>'` and `exit=0`. If any line says `in it.md but NOT preview-report.sh` (or vice-versa), the two files disagree on that marker — fix the lagging file and re-run.

- [ ] **Step 7: Run the preview smoke test — expect it still runs**

Run: `bash plugins/bonk/scripts/test-preview-report.sh; echo "exit=$?"`
Expected: `PASS: both → 0 + output`, `PASS: restart → exit 0`, `PASS: continue → exit 0`, `PASS: bogus arg → exit 2`, `exit=0`. A failure here means a heredoc syntax error (e.g. an unbalanced quote) — recheck Steps 3–4.

- [ ] **Step 8: Eyeball the rendered samples**

Run: `bash plugins/bonk/scripts/preview-report.sh both`
Expected: two reports, each opening with a `═══ b o n k . i t … ═══` band and closing with `═══ END · DRIFT CHECK ═══`, restart using `↺`/START OVER and continue using `▸`/KEEP GOING. (No markdown viewer is installed here, so this prints raw markdown — that's the expected fallback path.)

- [ ] **Step 9: Run shellcheck and the full suite**

Run: `shellcheck --severity=warning plugins/bonk/scripts/*.sh && bash plugins/bonk/scripts/test.sh; echo "exit=$?"`
Expected: no shellcheck output (clean), every `test-*.sh` section passes, `exit=0`.

- [ ] **Step 10: Commit**

```bash
git add plugins/bonk/commands/it.md plugins/bonk/scripts/preview-report.sh plugins/bonk/scripts/test-report-format-drift.sh
git commit -m "feat: restyle Drift Check report (banners, monochrome icons, grid)"
```

---

### Task 2: Bump to v0.5.0 and update README

A reviewer could approve the format change but want to hold the release; this is the separate "ship it" deliverable.

**Files:**
- Modify: `plugins/bonk/.claude-plugin/plugin.json` (`"version"`)
- Modify: `.claude-plugin/marketplace.json` (`"version"`)
- Modify: `README.md` (Status line + spec link, current lines 79–82)
- Test: `plugins/bonk/scripts/test-check-version-sync.sh`, `plugins/bonk/scripts/test-manifests.sh`

**Interfaces:**
- Consumes: the new spec file path and format vocabulary from Task 1 / the design spec.
- Produces: nothing downstream.

- [ ] **Step 1: Bump the plugin manifest version**

In `plugins/bonk/.claude-plugin/plugin.json`, change:

```json
  "version": "0.4.1",
```

to:

```json
  "version": "0.5.0",
```

- [ ] **Step 2: Bump the marketplace manifest version**

In `.claude-plugin/marketplace.json`, change the plugin entry's:

```json
      "version": "0.4.1",
```

to:

```json
      "version": "0.5.0",
```

- [ ] **Step 3: Verify the two manifests agree**

Run: `bash plugins/bonk/scripts/check-version-sync.sh; echo "exit=$?"`
Expected: prints `0.5.0` and `exit=0`. Exit 5 means the two versions disagree — recheck Steps 1–2.

- [ ] **Step 4: Update the README Status line and add the spec link**

In `README.md`, replace the Status paragraph (current lines 79–82):

```text
v0.4.1 shipped. See [the design spec](docs/superpowers/specs/2026-06-16-bonk-design.md)
for the full design and [the plan](docs/superpowers/plans/2026-06-16-bonk-v1.md)
for how it was built; the [report-format redesign](docs/superpowers/specs/2026-06-16-report-format-redesign-design.md)
covers the current Drift-check report.
```

with:

```text
v0.5.0 shipped. See [the design spec](docs/superpowers/specs/2026-06-16-bonk-design.md)
for the full design and [the plan](docs/superpowers/plans/2026-06-16-bonk-v1.md)
for how it was built; the [report-format redesign](docs/superpowers/specs/2026-06-16-report-format-redesign-design.md)
and the [visual redesign](docs/superpowers/specs/2026-06-23-report-visual-redesign-design.md)
(banners, monochrome icons, grid) cover the current Drift-check report.
```

- [ ] **Step 5: Run the manifest and version-sync tests, then the full suite**

Run: `bash plugins/bonk/scripts/test-manifests.sh && bash plugins/bonk/scripts/test-check-version-sync.sh && bash plugins/bonk/scripts/test.sh; echo "exit=$?"`
Expected: all sections pass (including `PASS: repo manifests in sync (0.5.0)`), `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add plugins/bonk/.claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "chore: bump version to 0.5.0"
```

---

## Self-Review

**Spec coverage:**
- Bounding banners (§1) → Task 1 Steps 1, 3, 4 (top/bottom `═══` bands with wordmark + verdict glyph).
- Monochrome icon system (§2) → Task 1 Step 1 (glyph table in instructions) + Global Constraints (pinned codepoints).
- Body layout: verdict block / grid problems / context rows (§3) → Task 1 Steps 1, 3, 4.
- Components changed table (spec) → Task 1 (it.md, preview, drift guard) + Task 2 (manifests, README).
- Version bump 0.4.1 → 0.5.0 (spec) → Task 2 Steps 1–2.
- Testing (spec) → Task 1 Steps 6–9, Task 2 Steps 3, 5.
- Out of scope (themed glow, brief/resume changes, browser) → not touched; clean-brief template (it.md Step 3b lines 132+) deliberately left alone, only the glyph reference at line 125 changes.

**Placeholder scan:** The `<...>` tokens inside the it.md skeleton are intentional template slots that ship in the prompt verbatim (the model fills them at runtime) — not plan placeholders. All bash/JSON/markdown edit steps contain the literal final content. No TBD/TODO.

**Type/marker consistency:** The 18 marker strings in Task 1 Step 5 each appear verbatim in both the it.md replacement (Step 1) and at least one preview heredoc (Steps 3–4): `↺`/`START OVER`/`Restart path` in the restart sample, `▸`/`KEEP GOING` in the continue sample, `●`/`high confidence` in both legends, and `b o n k . i t`/`DRIFT CHECK`/`END · DRIFT CHECK`/`What's wrong`/`The fix`/`Load-bearing problems`/`flips if`/`✓ solid`/`Context`/`○`/`◐` in both. Removed stale markers (`# 🧭 Drift check`, `**Cause —**`, `How the restart happens`, `*flips:*`, `**Solid**`, `📋 Context`, `🔴`, `🟡`) no longer appear in either file. Version string `0.5.0` is identical across plugin.json, marketplace.json, and README.
