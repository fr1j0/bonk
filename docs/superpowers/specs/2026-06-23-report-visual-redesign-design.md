# Drift Check report — visual redesign (v0.5.0)

**Status:** approved design, pre-implementation
**Date:** 2026-06-23
**Supersedes the visual layer of:** [2026-06-16-report-format-redesign-design.md](2026-06-16-report-format-redesign-design.md)

## Problem

The `/bonk:it` Drift check report is functional but its visual treatment undercuts
its job. The report exists to deliver a credible, *earned* judgement (START OVER vs
KEEP GOING), yet the current emoji-heavy styling (🧭 🛑 ⚖️ 📋 🔴 🟡 🟢 ✅) reads as
decorative and playful — it makes the verdict feel *less* trustworthy. Two concrete
gaps:

1. **Credibility.** Colourful emoji look cheap next to a report asking the user to
   throw away work. The look should read as a serious instrument readout.
2. **Findability.** When `/bonk:it` fires in the middle of a long terminal session,
   the report has no clear boundaries — it drowns in surrounding log output. The
   user can't quickly find where the verdict starts and ends.

## Constraints (what the medium actually allows)

The *real* report is emitted by the model as a markdown **message** and drawn by
**Claude Code's own terminal renderer**. The plugin does **not** pipe it through
`glow`/`mdcat`/`bat` at runtime — that fallback chain exists only in
`preview-report.sh` for dev-time eyeballing. Therefore:

- **No runtime theming.** Colours/borders/fonts are Claude Code's to decide, not the
  plugin's. The only styling levers the plugin owns are the markdown constructs
  themselves (headings, blockquotes, tables, bold, rules, code spans) and the
  literal characters inside them.
- **No images.** An "icon" can only be a font glyph (a character).
- **No tool/font dependency.** The target machine has none of glow/mdcat/bat
  installed, and shipped plugin users can't be assumed to have a Nerd Font. The
  design must look right using only universally-available characters. Nerd Fonts
  were considered and rejected as a default for this reason (they render as tofu
  without the patched font).

These constraints were validated during design: the chosen direction is "improve the
structure and the character palette," not "theme the renderer."

## Design

### 1. Bounding banners (begin/end delimiters)

The report opens and closes with a **fenced code-block band** so the characters
render literally and monospace, forming unmistakable scroll-stops:

````
```
═══════════════════  ↺  BONK · DRIFT CHECK  ═══════════════════
```
````

…report body…

````
```
══════════════════════  END · DRIFT CHECK  ═══════════════════
```
````

- The leading glyph in the top band **encodes the verdict** (`↺` START OVER /
  `▸` KEEP GOING), so the banner alone carries the headline.
- Band width is nominal (~60 chars). Exact width is not load-bearing; if a narrow
  terminal wraps it, it still reads as a boundary. Instructions tell the model to
  keep it on one line and not pad to terminal width.

### 2. Monochrome icon system

All color emoji are replaced by **text-default Unicode glyphs**. Pinned codepoints
(chosen because they default to text presentation, so they will not flip to colour
emoji on macOS):

| Role | Glyph | Codepoint |
|---|---|---|
| Verdict — restart | `↺` | U+21BA |
| Verdict — continue | `▸` | U+25B8 |
| Confidence — low | `○` | U+25CB |
| Confidence — medium | `◐` | U+25D0 |
| Confidence — high | `●` | U+25CF |
| Solid / confirmed | `✓` | U+2713 |
| Wrong | `✗` | U+2717 |
| Section bar | `▌` | U+258C |
| Banner rule | `═` | U+2550 |

`⚠` (U+26A0) and other emoji-default glyphs are deliberately avoided. Confidence is a
monochrome **fill scale** (empty → half → full), which reads as a rating instrument
rather than a sticker.

### 3. Body layout

**Verdict block** (decision first):

```
## ↺ START OVER — <one plain-language headline>

> <2–3 plain sentences: the call and why. No jargon.>

**What's wrong** — <load-bearing bad assumption, plainly>
**The fix** — <corrective action>
**Restart path** — save confirmed facts + corrected plan to a file → `/clear` → `/bonk:resume`.
```

On **KEEP GOING**: header becomes `## ▸ KEEP GOING — <headline>`, the `Restart path`
line is dropped, and `The fix` is the in-place correction.

**Load-bearing problems** — a scannable grid, worst-first (`○` before `◐`), numbered
by row order:

```
### ▌Load-bearing problems

|  | Assumption | Source | Why shaky → what flips it |
|---|---|---|---|
| `○` | <assumption, terse> | `guessed` | <one line> → flips if <evidence> |
| `◐` | <assumption, terse> | `inferred` | <one line> → flips if <evidence> |

`○` low · `◐` med · `●` high confidence

`✓ solid` (from user) <fact> · (from file) <fact>
```

- The one-line **confidence legend** under the table removes any ambiguity about the
  bare glyphs.
- Cells must stay terse — this is enforced in the `it.md` instructions and is the
  mitigation for the table's narrow-terminal tradeoff (see Tradeoffs).
- If nothing is both load-bearing and shaky, the model says so plainly instead of
  rendering an empty grid (unchanged from current behaviour).

**Context** — compact labeled rows, omit any row with no information:

```
### ▌Context

**Goal** — <one sentence; prefix "drift:" only if it drifted from the ask>
**Divergence** — <the one turn/decision that introduced the wrong fork>
**Dismissed** — <2–3 alternatives never seriously considered, "·"-separated>
**Artifacts** — clean; nothing to undo
```

`Artifacts` expands to the file list + undo guidance only when wrong-path residue
exists (unchanged behaviour, restyled).

## Components changed

| File | Change |
|---|---|
| `plugins/bonk/commands/it.md` | Rewrite the Step 2 report skeleton and skeleton rules to the new format (banners, monochrome glyphs, grid problems, legend). Behavioural logic (verdict rule, Step 3a/3b, brief flow) is unchanged. |
| `plugins/bonk/scripts/preview-report.sh` | Update both golden samples (restart + continue) to the new format so the preview matches `it.md`. |
| `plugins/bonk/scripts/test-report-format-drift.sh` | Update the structural markers it greps for in both files (banner band, `↺`/`▸`, `○`/`◐`/`●`, `▌`, grid header, confidence legend). |
| `README.md` | Bump version; the report sample is referenced via the preview script, not embedded, so no inline sample to edit. Link this spec. |
| `plugins/bonk/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md` | Version bump 0.4.1 → 0.5.0 (shipped report format changes). |

## Data flow (unchanged)

The redesign is purely the *presentation* of Step 2. The control flow —
artifact-inventory → audit → verdict (RESTART/CONTINUE) → Step 3a (continue) or
Step 3b (clean seed → subagent → delta → draft brief → write) — is untouched. The
clean-brief template consumed by `/bonk:resume` is **not** part of this change.

## Testing

- `bash plugins/bonk/scripts/test-report-format-drift.sh` — updated markers keep
  `it.md` and `preview-report.sh` in lockstep; fails if either drifts.
- `bash plugins/bonk/scripts/preview-report.sh [restart|continue|both]` — manual
  eyeball. Works without a markdown viewer installed (raw-markdown fallback), which
  is the path this machine actually uses.
- Existing manifest/version guards (`test-*.sh`) must stay green after the version
  bump.

## Tradeoffs

- **Grid vs. cards for problems.** The grid is the most scannable with 1–3 problems
  but can cramp on very narrow terminals or with long cell text. Accepted, with
  terse-cell enforcement in `it.md` as mitigation. Stacked cards were the runner-up
  and remain a fallback if the grid proves cramped in practice.
- **Monochrome vs. Nerd Font icons.** Nerd Fonts look crisper but require a patched
  font; rejected as a default for portability. A Nerd-Font-enhanced variant is out
  of scope for v0.5.0 and could be revisited as an opt-in later.
- **Preview fidelity.** The preview renderer (glow/raw) is not identical to Claude
  Code's renderer, so the preview remains an approximation. The design leans on
  constructs that degrade gracefully (banners are literal code blocks; tables are
  standard markdown).

## Out of scope

- Themed/`glow` runtime rendering and any new runtime dependency.
- Changes to the clean-brief format or the `/bonk:resume` flow.
- Browser/HTML rendering.
