---
title: Throw vs. return is decided by totality, not expectation
summary: Whether a C# operation returns a Result or throws is settled structurally by its codomain — modeled outcomes are values, substrate failures are exceptions. The usual "is it expected / can the caller recover" framings can't draw the line; totality can.
tags: [note, csharp, design, errors, functional, ddd]
created: 2026-07-13
status: evolving
---

Model every operation as a **total function** and ask one structural question: is this outcome in the function's **codomain**, or is it the **substrate** the function assumes failing? That question — not "is it expected," not "can the caller recover" — decides whether you return a `Result<T>` or throw.

## Why the usual framings can't draw the line

The common heuristics all test *capability* or *expectation*, and both are orthogonal to the decision:

- **"Is it expected?"** Everything is expected to someone. `HttpClient` throws on socket errors, yet anyone who has used the internet expects socket errors. Expectation doesn't distinguish.
- **"Can the caller branch on it?"** You can always branch — `catch` filters (`catch (SpecificEx)` / `catch (LessSpecificEx)`) branch on exceptions as readily as `Match` branches on a `Result`. The mechanism is not the semantics.
- **"Can the caller do something other than log-and-crash?"** `HttpClient` throws and the caller can still retry, fall back, or degrade. Recoverability doesn't distinguish either.

These questions produce endless case-by-case argument. They are an artifact of C# bolting exceptions onto a language that could have used `Result<T>` (as Go does with return values, as C did with none at all). The fix is to stop asking about the caller's *options* and ask about the function's *structure*.

## The line: codomain vs. substrate

- **In the codomain → return a value** (`Result<T>` / `Either<L, R>`). These are the *modeled* outcomes: success and every failure the operation's own logic produces — a parse rejecting input, a withdrawal exceeding balance, a lookup finding nothing. The function is **total**: every input maps to a modeled outcome, nothing escapes out-of-band. `Match` to handle; never unwrap `.Value` blindly.
- **Outside the codomain → throw.** Not an outcome of the operation — the machinery it *assumes* (memory, network, disk, configuration, correct calling code) failing. An exception is the honest signal precisely because the event is not part of the function's total mapping.

An exception is out-of-band and lies about totality; a `Result` is in-band and lets the compiler force exhaustive handling. That — not "you can't branch on exceptions" — is why modeled outcomes belong in the return type.

## Where this meets invariants

Make invalid states unrepresentable, and the domain interior becomes total for free: a value that exists is valid by construction, so a pure domain function operating on valid values *cannot* produce an invariant violation. The interior therefore never mints a domain error and never throws.

So a `Result` is born in only two places:

1. **At the boundary, parsing** representable-invalid external input into a domain type — the one place invalid states are still representable, so the one place a domain invariant can fail to hold. (Parse, don't validate.)
2. **As a genuine business branch-point** expressed as a sum type — `Withdraw(amount)` returning `Success | InsufficientFunds`. Not an invalid state; a decision, expressed as a value. The function is still total.

Both are in-band values. Neither is an exception.

## Throwing has exactly three causes

Everything outside the codomain is one of:

- **Transient infrastructure fault** — effectively 100% of network/partition/timeout states. Liveness is undecidable (you can never *know* a database is "down"; you can only decide to stop waiting), so it can never be a modeled outcome. Retry (e.g. Polly); on budget exhaustion, propagate.
- **Permanent infrastructure fault** — configuration only. The thing that, wrong at startup, stops the system from running: an IAM error on a resource you need, a missing connection string. Fail fast, loud, at boot.
- **A bug** — a partiality the type system didn't remove: a violated precondition (`ArgumentNullException.ThrowIfNull` at a public boundary against callers you don't control), API misuse (`InvalidOperationException`), a broken assertion. You fix these; you don't handle them. Ideally the types delete most of them first.

Cancellation (`OperationCanceledException`) is thrown, not returned — cooperative control flow, not an outcome of the operation.

## The boundary reconciles the two channels

Adapters (port implementations) live below the domain and are *allowed* to throw. At the edge they **translate**: the substrate faults that map to a modeled outcome (a query's `row-not-found` → `NotFound`/`Gone`) become `Result` variants; genuine substrate failures (the connection dropped) stay exceptions and propagate to the host's outermost handler. The pure core never sees a raw `SqlException`.

This is also why `HttpClient` throwing is *correct*, not a counterexample: it is an infrastructure adapter, a socket fault is its substrate failing, and throwing is the right channel for something outside the codomain of "send request, get response." Your `catch` at that adapter is the translation site — the boundary doing its job.

Domain is relative to layer. Within `HttpClient`'s own internals, TCP was the author's domain and might be modeled differently; from *your* layer, `HttpClient` is infrastructure and its exceptions are the substrate-fault channel. The rule applies per layer: each layer's pure core is total; its adapters throw.

## Doing this in C#

C# gives you exceptions whether you want them or not, so the discipline is to treat the language as **Result-first**: the domain codomain speaks in `Result<T>` / `Either<L, R>` / named variants, and the CLR's exception model is quarantined to two edges — the infrastructure boundary (transient/permanent faults) and the bug channel (guards). Exceptions never carry a modeled domain outcome.

## The decision, in one line

**If it is an outcome of the operation, return it; if it is the substrate failing or the code being wrong, throw it.**
