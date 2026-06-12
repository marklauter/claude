[![claude code](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic)](https://docs.claude.com/en/docs/claude-code/plugins)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

![MSL Armory](https://raw.githubusercontent.com/marklauter/claude/main/images/msl.armory.small.png "MSL Armory")

# MSL Armory

A Claude Code marketplace shipping one plugin, `armory` — agent-facing writing and reviewing skills.

The Hoplite knowledge graph (MCP server plus its note-taking and journaling skills) lives in its own repo now: [marklauter/hoplite](https://github.com/marklauter/hoplite).

## Install

From inside Claude Code, with `<repo>` as the absolute path to your clone (the directory holding `.claude-plugin/marketplace.json`):

```text
/plugin marketplace add <repo>
/plugin install armory@msl.armory
```

After source changes, run `/plugin uninstall armory@msl.armory` followed by `/plugin install armory@msl.armory` to refresh the cached SKILL.md and components.

## What you get

Writing skills:

- `writing-prose` — editorial foundation for markdown artifacts: rhetorical context, density, structure, formatting.
- `writing-wiki` — software-project wikis; sections own audience and tone, pages inherit. Loads alongside `writing-prose`.
- `writing-csharp` — C#/.NET idioms: type-driven design, immutability, Result-type error handling.
- `writing-python` — pragmatic-functional Python: frozen dataclasses, pattern matching, Protocol-based typing, modern tooling.

Reviewing skills:

- `reviewing-prose` — review local markdown diffs; findings classified by severity and lens under `.findings/`.
- `reviewing-wiki` — same shape, scoped to wiki corpora; self-contained rubric.
- `reviewing-csharp` — review local C# diffs; findings under `.findings/`.
- `triaging-findings` — walk the `.findings/` queue and decide disposition: fix, file, drop, or defer.
- `managing-github-issues` — list, search, dedupe, file, triage, label, close.

## Quick start

1. Make some edits to markdown or C# in a git working tree.
2. Ask the agent to review the diff — it loads the matching reviewing skill and writes one file per finding under `.findings/`.
3. Ask the agent to triage — `triaging-findings` walks the queue in severity order and dispositions each finding.

## Development

Layout:

- `plugins/armory/skills/` — skill bodies. One subdirectory per skill, each with a `SKILL.md`.
- `plugins/armory/components/` — composable markdown fragments injected into skill bodies via shell expansion.
- `plugins/armory/scripts/` — shared bash scripts (finding readers and writers).
- `plugins/armory/tests/` — bash test runner and tests for the shared scripts.

Running tests:

```bash
bash plugins/armory/tests/run-tests.sh
```

Adding a skill: create `plugins/armory/skills/<skill-name>/SKILL.md`, then `/plugin uninstall` + `/plugin install` to refresh the cache.

## Troubleshooting

Claude Code's cache of SKILL.md and `components/` only refreshes on `/plugin install`. If the agent loads stale skill prose after a source change, run:

```text
/plugin uninstall armory@msl.armory
/plugin install armory@msl.armory
```
