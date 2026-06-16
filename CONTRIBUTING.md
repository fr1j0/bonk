# Contributing to bonk

Thanks for your interest! `bonk` is small and intentionally tightly scoped — a
pattern-interrupt + context re-grounding tool, not a general agent framework. To
keep that scope clean, **every change starts as an issue.**

## The flow

1. **Open an issue.** Describe the bug, feature, or question:
   - [Bug report](https://github.com/fr1j0/bonk/issues/new?labels=bug) — what you
     did, what happened, what you expected.
   - [Feature request](https://github.com/fr1j0/bonk/issues/new?labels=enhancement)
     — the problem first, then the proposed change.
   - [Question](https://github.com/fr1j0/bonk/issues/new?labels=question).
2. **Wait for triage.** Every new issue is auto-labeled `needs-triage`. A maintainer
   reviews and either closes it, asks for more info, or applies `ready-for-dev` once
   it's approved to work on. This saves you from writing code that's out of scope
   (see below).
3. **Branch and code.** Create a topic branch named `<type>/issue-<N>-<slug>`
   (e.g. `feat/issue-12-brief-history`, `fix/issue-7-subdir-path`) **off `main`**.
   Never push to `main` directly.
4. **Open a PR.** Include `Closes #<N>` in the PR body and describe what changed
   and how you verified it. An automated **issue gate** checks the link.

## The issue gate

A PR must trace to an issue. The `Issue gate` workflow posts a sticky pass/fail
comment and enforces:

- **External contributors** — the linked issue must carry `ready-for-dev`, applied
  by the repo owner. An un-triaged (`needs-triage`) issue isn't enough on its own.
- **The repo owner's own PRs** — pass with *any* linked issue (e.g. just
  `needs-triage`); the creator doesn't self-approve via `ready-for-dev`.
- **Maintainer escape hatch** — an owner-applied `skip-issue-check` label bypasses
  the gate entirely, for typo / CI / docs-only fixes with no issue.

## Why issue-first?

`bonk` does one thing: stop a wrong path, audit the assumptions, and (when context
is too far gone) restart from a clean, verified brief. Things like task tracking,
multi-brief history, automatic interruption, or broader "agent supervision"
workflows are deliberately out of scope unless an issue establishes a strong case.
Triaging first means you don't sink effort into a change that won't be accepted.

## Branching rules

- Branch off `main`. Never push to `main` directly.
- Branch name: `<type>/issue-<N>-<slug>`. `<type>` is one of `feat`, `fix`,
  `chore`, `docs`, `refactor`, `test`.
- Squash-merge is the default. Keep commit messages descriptive but don't
  over-engineer the history — squash collapses it.
- Do **not** add AI attribution to commits or PR bodies (no `Co-Authored-By` bot
  trailers, no "Generated with …" footers).

## What's in the plugin

Everything that ships lives under `plugins/bonk/`:

- `commands/it.md`, `commands/resume.md` — the agent-executed slash-command
  instructions (`/bonk:it`, `/bonk:resume`). These are the heart of the tool; the
  report format is defined here as prose, not code.
- `scripts/*.sh` — small deterministic helpers (`artifact-inventory.sh`,
  `brief-validate.sh`, `lib.sh`) plus `preview-report.sh` for eyeballing the
  report format. Each helper is read-only or writes only under `.bonk/`.
- `scripts/test-*.sh` — one self-reporting test suite per script, plus
  `test-report-format-drift.sh`, which keeps `commands/it.md` and the
  `preview-report.sh` golden sample in sync.

If you change the report format in `commands/it.md`, update the matching example
in `scripts/preview-report.sh` (and the marker list in
`scripts/test-report-format-drift.sh` if you add a load-bearing element) or the
drift test will fail.

## Local checks

CI runs ShellCheck and the test suite on every PR (ubuntu + macOS). To match it
locally before pushing:

```bash
# One-time: install ShellCheck
brew install shellcheck          # macOS
# apt install shellcheck         # Debian/Ubuntu

# Lint the shell scripts
shellcheck --severity=warning plugins/bonk/scripts/*.sh

# Run the full test suite (each test self-reports PASS/FAIL)
bash plugins/bonk/scripts/test.sh
```

`test.sh` exits non-zero if any suite fails — a clean run is the bar for a PR.

## Code of Conduct

Be kind. Assume good faith. If something feels off, open an issue or reach out to a
maintainer.

## License

By contributing, you agree your work is licensed under the [MIT License](LICENSE).
