---
title: Testing philosophy — tests pin the observable contract of code you own
summary: The kernel behind the writing-csharp Testing section — coverage as signal, ownership boundary, contract-level pinning, red-first bug fixes, flaky as defect, the cost gradient.
tags: [note, csharp, testing, skills]
created: 2026-07-20
status: evolving
informs: "[[review-property-based-testing-for-writing-csharp]]"
---

# Testing philosophy for writing-csharp

Kernel: **tests pin the observable contract of code you own.** Everything below is that sentence unpacked.

- Coverage is a quantitative signal of test quality, not the goal. Zero coverage is zero quality; 100% coverage is not 100% quality. Quality tests cover the unit's functional cases, edge cases, and failure cases, and pin behavior against regression — the score rises as a side effect. The ratchet is a regression gate: it prevents new code arriving without new tests.
- The ownership boundary — the golden rule: don't test what you don't own. A test proving the framework or a library does its job verifies someone else's contract and breaks on their upgrades. Corollary: don't mock what you don't own; wrap the foreign type in a port and mock the port.
- Pinning happens at the contract, not the implementation. This dissolves into the kernel — "observable contract" already says it — so it carries no bullet of its own in the skill.
- Over-specification is the dual of under-coverage, and it pairs with ownership (adjacent, not merged): don't test outside the contract. Asserting more than the contract promises — call counts, exact wording, internal ordering — manufactures false failures on refactor.
- A bug fix starts red. Write the test that reproduces the defect, prove it fails, fix, watch it pass — that is the bug pinned against regression. A fix without the red test isn't pinned.
- Flaky, defined: a test whose verdict depends on anything other than the code under test — wall clock, network, filesystem state, execution order, unseeded randomness, sleeps and timeouts. A flaky test is a defect in the test, fixed immediately; rerunning until green is suppression without the justification.
- The cost gradient: pure core gets many cheap data-in/data-out tests; ports get fakes; the real substrate gets thin integration tests tagged `Category=Integration`.
- Property-based testing deferred — see the linked todo. Candidate stance: default for round-trips, `IValue` invariants, and `Result`/`Either` laws; silence elsewhere.
