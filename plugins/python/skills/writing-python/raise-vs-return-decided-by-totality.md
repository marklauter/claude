---
title: Raise vs. return is decided by totality, not expectation
summary: Whether a Python operation returns a value or raises is settled structurally by its codomain — modeled outcomes are values, substrate failures are exceptions. The usual "is it expected / can the caller recover" framings can't draw the line; totality can.
tags: [note, python, design, errors, functional]
status: evolving
---

Model every operation as a total function and ask one structural question: is this outcome in the function's codomain, or is it the substrate the function assumes failing? That question — not "is it expected," not "can the caller recover" — decides whether you return a value (`T | None` / `Result[T, E]`) or raise.

## Why the usual framings can't draw the line

The common heuristics all test *capability* or *expectation*, and both are orthogonal to the decision:

- "Is it expected?" Everything is expected to someone. `httpx` raises on connection errors, yet anyone who has used the internet expects connection errors. Expectation doesn't distinguish.
- "Can the caller branch on it?" You can always branch — `except ConnectionError` / `except TimeoutError` branch on exceptions as readily as `match` branches on a returned value. The mechanism is not the semantics.
- "Can the caller do something other than log-and-crash?" `httpx` raises and the caller can still retry, fall back, or degrade. Recoverability doesn't distinguish either.

These questions produce endless case-by-case argument. Python, like most languages, offers exceptions as the path of least resistance, but it could carry outcomes in return values (as Go does, as C did with none at all). The fix is to stop asking about the caller's *options* and ask about the function's *structure*.

## The line: codomain vs. substrate

- In the codomain → return a value (`T | None` for plain absence, `Result[T, E]` where the error vocabulary is richer). These are the *modeled* outcomes: success and every failure the operation's own logic produces — a parse rejecting input, a withdrawal exceeding balance, a lookup finding nothing. The function is total: every input maps to a modeled outcome, nothing escapes out-of-band. `match` to handle; don't reach past the container blindly.
- Outside the codomain → raise. Not an outcome of the operation — the machinery it *assumes* (memory, network, disk, configuration, correct calling code) failing. An exception is the honest signal precisely because the event is not part of the function's total mapping.

An exception is out-of-band and lies about totality; a returned value is in-band and, under `pyright` strict with exhaustive `match`, forces every outcome to be handled. That — not "you can't branch on exceptions" — is why modeled outcomes belong in the return type.

## Where this meets invariants

Make invalid states unrepresentable, and the domain interior becomes total for free: a value that exists is valid by construction (a frozen dataclass whose `__post_init__` guards its invariant), so a pure domain function operating on valid values *cannot* produce an invariant violation. The interior therefore never mints a domain error and never raises.

So a modeled failure is born in only two places:

1. At the boundary, parsing representable-invalid external input into a domain type — the one place invalid states are still representable, so the one place a domain invariant can fail to hold. (Parse, don't validate.)
2. As a genuine business branch-point expressed as a sum type — `withdraw(amount)` returning `Success | InsufficientFunds` (sibling frozen dataclasses). Not an invalid state; a decision, expressed as a value. The function is still total.

Both are in-band values. Neither is an exception.

## Raising has exactly three causes

Everything outside the codomain is one of:

- Transient infrastructure fault — effectively 100% of network/partition/timeout states. Liveness is undecidable (you can never *know* a database is "down"; you can only decide to stop waiting), so it can never be a modeled outcome. Retry (e.g. tenacity); on budget exhaustion, propagate.
- Permanent infrastructure fault — configuration only. The thing that, wrong at startup, stops the system from running: an IAM error on a resource you need, a missing connection string. Fail fast, loud, at boot.
- A bug — a partiality the type system didn't remove: a violated precondition (an explicit guard raising `ValueError`/`TypeError` at a public boundary against callers you don't control), API misuse (`RuntimeError`), a broken assertion. You fix these; you don't handle them. Ideally the type hints delete most of them first.

Cancellation (`asyncio.CancelledError`, `KeyboardInterrupt`) is raised, not returned — cooperative control flow, not an outcome of the operation. Let it propagate; never swallow it in a bare `except`.

## The boundary reconciles the two channels

Adapters (the I/O layer below the domain) are *allowed* to raise. At the edge they translate: the substrate faults that map to a modeled outcome (a query's row-not-found → a `None` or a `NotFound` variant) become return values; genuine substrate failures (the connection dropped) stay exceptions and propagate to the host's outermost handler. The pure core never sees a raw `OperationalError`.

This is also why `httpx` raising is *correct*, not a counterexample: it is an infrastructure adapter, a connection fault is its substrate failing, and raising is the right channel for something outside the codomain of "send request, get response." Your `except` at that adapter is the translation site — the boundary doing its job.

Domain is relative to layer. Within `httpx`'s own internals, the socket was the author's domain and might be modeled differently; from *your* layer, `httpx` is infrastructure and its exceptions are the substrate-fault channel. The rule applies per layer: each layer's pure core is total; its adapters raise.

## Doing this in Python

Python gives you exceptions as the default, so the discipline is to treat the domain as value-first: the codomain speaks in `T | None` / `Result[T, E]` / sum-type variants, and the exception model is quarantined to two edges — the infrastructure boundary (transient/permanent faults) and the bug channel (guards). Exceptions never carry a modeled domain outcome, and every `raise` inside an `except` keeps the chain with `from`.

## The decision, in one line

If it is an outcome of the operation, return it; if it is the substrate failing or the code being wrong, raise it.
