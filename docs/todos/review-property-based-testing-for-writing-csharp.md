---
title: Review property-based testing for inclusion in writing-csharp
summary: Evaluate property-based testing (CsCheck) as a default expectation for total functions in the writing-csharp skill; Mark wants to explore the concept first.
tags: [todo, csharp, testing, skills]
created: 2026-07-20
status: open
priority: medium
effort: medium
---

# Review property-based testing for inclusion in writing-csharp

Surfaced during the testing-philosophy design interview for `plugins/csharp/skills/writing-csharp/SKILL.md`. First exposure to the concept — explore it before committing skill content.

## The concept

A property test states a law that must hold for *every* input; the framework generates hundreds of random inputs trying to falsify it, and shrinks any failure to a minimal counterexample. Instead of `Parse("42%") == Percent(42)` plus forty-nine more hand-picked examples, you write `∀ valid p: Parse(Format(p)) == p` once. Example tests don't go away — they stay for specific documented cases; properties cover the space between them and find the edge case nobody thought to pick.

## What it would mean for our tests

The codebase discipline is unusually well-shaped for this: totality means each function's contract *is* a law over its whole domain.

- Round-trip laws for `Parse`/`Format` pairs: `Parse(Format(x)) == x`.
- Invariant preservation for `IValue` wrapper types: any constructed value satisfies its constraint — the generator hammers `Parse` with arbitrary input and asserts no invalid value ever escapes.
- Algebraic laws on the home-grown `Result`/`Either`: `map` identity/composition, `bind` associativity — the laws these types claim to obey, checked instead of assumed.

One property replaces a pile of examples for these cases.

## Tooling

CsCheck recommended over FsCheck: pure C#, no F# dependency, fast, shrinks well.

## Proposed skill stance (pending review)

Default for the well-shaped cases (round-trips, `IValue` invariants, `Result`/`Either` laws), silence elsewhere — so it doesn't metastasize into forced properties on code with no natural law.

## Acceptance

Decide include/decline; if included, land the bullet in the writing-csharp Testing section and note the tool choice.
