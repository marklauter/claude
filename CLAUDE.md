# CLAUDE.md

Claude Code marketplace (`msl-armory`) shipping several small, single-concern plugins under `plugins/`, each a self-contained collection of agent-facing skills:

- `documentation/` — writing and reviewing prose and project wikis.
- `csharp/` — writing and reviewing C# / .NET.
- `python/` — writing Python.
- `workflow/` — findings triage and GitHub issue management.

A plugin is one coherent artifact-class family; skills that fire in the same repo travel together, and families that don't co-occur (C# vs Python) ship as separate plugins so a consumer installs only what its repo needs. Plugins are **self-contained** — no build step, no mail-merge, no cross-plugin shared scripts or components. A skill inlines its own discipline and references shared canonical docs by plain path. The README covers install.

## Script-location trap

Scripts a skill uses live under that skill's own directory: `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/`. A SKILL.md that names a script without anchoring its path leaves the agent looking in the wrong place, finding nothing, and reporting "scripts not installed." Every script reference in a SKILL.md needs an explicit `${CLAUDE_PLUGIN_ROOT}/...` path.
