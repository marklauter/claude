---
title: Reduce the prose skills next
summary: The documentation-plugin prose skills — reviewing-prose, reviewing-wiki, and the writing-prose family — still carry dead finding-script refs and old lens/register framing; they are next for reduction to self-contained trigger→action.
tags: [todo, skills, documentation, prose]
created: 2026-07-13
status: open
---

The C# skills (`writing-csharp`, `scaffolding-csharp`) are done. The documentation-plugin prose skills are the next agenda item — they still carry the old world:

- **`reviewing-prose` and `reviewing-wiki`** describe the deleted finding-scripts (`changes.sh`, `report-finding.sh`, `list-findings.sh`, `query.sh`, `summarize.sh`) and the `.findings/` workflow in their prose — dead refs since commit `420125b`. `reviewing-prose` also still says "shared with reviewing-csharp," a skill that no longer exists.
- The **lens / register / audit-mode** machinery (six review lenses, rhetorical-context slots, `_conventions.md`) is the pre-standalone framing. `writing-wiki` was already cut over to a four-reader spine; `reviewing-wiki` and the `writing-prose` family have not.

The work, per `how-to-build-skills.md`: reduce each to comprehended philosophy → trigger→action, self-contained (no shared fragments, no composition), purge every dead script reference, and put agent-native review in place of what the deleted scripts used to do. Two open notes feed this: `apply-mechanical-vs-judgment-split-to-reviewing-prose-line-and-copy-lens.md` (compress the mechanical lens signals once a prose linter lands) and `lazy-accuracy-depends-on-wiki-citation-hygiene.md` (the accuracy-coverage principle).
