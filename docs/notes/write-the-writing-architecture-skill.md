---
title: Write the writing-architecture skill
summary: A language-agnostic architecture skill — bounded contexts, hexagonal boundaries, dependency direction, integration patterns — sitting beside the per-language writing skills.
tags: [note, skills, architecture]
created: 2026-05-25
status: evolving
---

## Idea

Architecture-scale decisions are a separate concern from idiomatic language use: the architect (or the agent) devises the plan; the developer follows it. That argues for a self-contained `writing-architecture` skill distinct from the per-language `writing-*` skills.

`writing-csharp` already carries the C#-facing surface of this in its Design section — model the domain not the database, bounded contexts, aggregates, an immutable core, effects at the edge through ports and adapters. `writing-architecture` would be the language-agnostic elaboration a `writing-*` skill can assume without restating:

- Persistence ignorance fully drawn out — port/adapter boundaries, mapper/DTO conventions, repository placement.
- Dependency direction — hexagonal / onion, the dependency rule.
- Bounded contexts and anti-corruption layers.
- Integration patterns — sync vs async, choreography vs orchestration.
- Deployment topology where it shapes the code — service boundaries, shared databases.

## Shape

Self-contained, per `how-to-build-skills.md`: comprehended architecture philosophy reduced to trigger→action, its discipline inlined — not composed on another skill, no shared fragments. The per-language skills reference it by concept, not by loading it. Scope it to what `writing-csharp`'s Design section does *not* already cover, so the two don't duplicate.

## Open

Whether it earns its own skill or stays folded into each `writing-*` skill's Design section. `writing-csharp` absorbing the DDD core weakens the standalone case; decide once a second language skill (`writing-python`) needs the same architecture rules and would otherwise restate them.
