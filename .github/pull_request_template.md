## Linked issue

Closes #<!-- issue number -->

<!--
Changes should start from an approved issue (see CONTRIBUTING.md). Typo-only,
CI-only, or docs-only fixes by a maintainer are the usual exceptions.
-->

## What & why

<!-- 1-3 sentences. Why this change, not what (the diff shows that). -->

## Test plan

<!-- How you verified this. Include commands if relevant. -->

## Checklist

- [ ] Branch name follows `<type>/issue-<N>-<slug>` (e.g. `fix/issue-7-subdir-path`).
- [ ] `shellcheck --severity=warning plugins/bonk/scripts/*.sh` is clean.
- [ ] `bash plugins/bonk/scripts/test.sh` passes.
- [ ] Tests added/updated where reasonable (incl. the report-format drift test if the format changed).
- [ ] No AI attribution in commits or this PR body.
