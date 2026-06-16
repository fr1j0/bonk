# Security Policy

## Reporting a vulnerability

Please report security issues **privately**. Do not open a public issue.

**Preferred channel:** [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) — on this repo's **Security** tab, click **Report a vulnerability**. This opens a private draft advisory only the maintainer can see.

**Fallback:** if private reporting isn't available, email the address listed on the [maintainer's GitHub profile](https://github.com/fr1j0) with the subject line `bonk: security`.

When reporting, include:

- the affected file(s) and a brief reproducer (a minimal clean brief, working-tree state, or command transcript is enough);
- the impact you observed (e.g. validator bypass, agent-instruction injection, command injection from a file path or brief body);
- any suggested fix, if you have one.

## What we mean by "in scope"

The security surface of this repo is small and specific. The following classes count:

- **Shell scripts under `plugins/bonk/scripts/`** — `brief-validate.sh`, `artifact-inventory.sh`, `lib.sh`, and `preview-report.sh`. Bugs that let a malformed brief slip past the validator, or that allow command injection from a brief body, a file path, or a working-tree filename, qualify.
- **Command instruction files (`plugins/bonk/commands/*.md`)** — `it.md` and `resume.md` are agent-executed instructions. A change that would let untrusted content the agent reads — the contents of `.bonk/clean-brief.md`, a working-tree filename surfaced by the artifact inventory, or a `$ARGUMENTS` hint — hijack agent behaviour (classic prompt injection / instruction poisoning) qualifies.
- **GitHub Actions workflows** under `.github/workflows/` — if/when workflow automation is added, anything enabling workflow-injection, untrusted code execution in the target token's context, or unintended privilege escalation qualifies.

## What we mean by "out of scope"

- The user's own git repository contents and any side effects of `git` commands run outside this plugin's scripts.
- Downstream Claude Code installations, the `~/.claude/` configuration, or harness behaviour outside this repo's source.
- Third-party tools the scripts shell out to or render through (e.g. `glow`, `mdcat`, `bat`) — report those to their respective maintainers.
- Anything that requires a maintainer-level GitHub token to exploit.

## Supported versions

Only the latest commit on `main` is supported. There are no LTS branches; security fixes ship forward, not backward.
