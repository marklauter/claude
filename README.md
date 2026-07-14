[![claude code](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic)](https://docs.claude.com/en/docs/claude-code/plugins)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

![MSL Armory](https://raw.githubusercontent.com/marklauter/claude/main/images/msl.armory.small.png "MSL Armory")

# MSL Armory

A Claude Code marketplace (`msl-armory`) shipping several small, single-concern plugins of agent-facing skills. Each plugin is one coherent family; install only the ones your repo needs.

The Hoplite knowledge graph (MCP server plus its note-taking and journaling skills) lives in its own repo now: [marklauter/hoplite](https://github.com/marklauter/hoplite).

## Plugins

- `documentation` — writing and reviewing markdown prose and project wikis.
- `csharp` — writing and scaffolding C# / .NET (ships a `dotnet new` solution template).
- `python` — writing Python.
- `workflow` — findings triage and GitHub issue management.

## Install

From inside Claude Code, with `<repo>` as the absolute path to your clone (the directory holding `.claude-plugin/marketplace.json`):

```text
/plugin marketplace add <repo>
/plugin install documentation@msl-armory
/plugin install csharp@msl-armory
```

Install each plugin you want by name — `<plugin>@msl-armory`. After source changes, run `/plugin uninstall <plugin>@msl-armory` followed by `/plugin install <plugin>@msl-armory` to refresh the cached `SKILL.md` and components.

## Development

Layout — each plugin is self-contained under `plugins/<plugin>/`:

- `plugins/<plugin>/.claude-plugin/plugin.json` — the plugin manifest.
- `plugins/<plugin>/skills/<skill>/SKILL.md` — skill bodies, one subdirectory per skill.
- `plugins/<plugin>/skills/<skill>/scripts/` — scripts owned by that skill.
- `plugins/<plugin>/components/` — markdown fragments for that plugin's skills.

Plugins carry no build step and share nothing across plugin boundaries: a skill inlines its own discipline and references shared canonical docs by plain path.

Running the workflow plugin's tests:

```bash
bash plugins/workflow/tests/run-tests.sh
```

Adding a skill: create `plugins/<plugin>/skills/<skill-name>/SKILL.md`, then `/plugin uninstall` + `/plugin install` to refresh the cache.

## Troubleshooting

Claude Code's cache of `SKILL.md` and `components/` only refreshes on `/plugin install`. If the agent loads stale skill prose after a source change, run:

```text
/plugin uninstall <plugin>@msl-armory
/plugin install <plugin>@msl-armory
```
