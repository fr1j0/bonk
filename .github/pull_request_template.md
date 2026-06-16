## Linked issue

Closes #<!-- issue number -->

<!--
A linked issue is required — the Issue gate workflow checks it (see CONTRIBUTING.md).
External PRs need the issue labeled `ready-for-dev` by the owner; the owner's own
PRs pass with any linked issue. Typo/CI/docs-only fixes can use `skip-issue-check`.
-->

## What & why

<!-- 1-3 sentences. Why this change, not what (the diff shows that). -->

## Test plan

<!-- How you verified this. Include commands if relevant. -->

## Checklist

- [ ] Linked to an issue (or carries owner-applied `skip-issue-check`).
- [ ] Branch name follows `<type>/issue-<N>-<slug>` (e.g. `fix/issue-7-subdir-path`).
- [ ] `shellcheck --severity=warning plugins/bonk/scripts/*.sh` is clean.
- [ ] `bash plugins/bonk/scripts/test.sh` passes.
- [ ] Tests added/updated where reasonable (incl. the report-format drift test if the format changed).
- [ ] No AI attribution in commits or this PR body.
