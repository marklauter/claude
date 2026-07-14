---
name: writing-python
description: Use when writing or refactoring Python. A pragmatic-functional core — immutable records, small pure functions, effects at the edge, sum types via frozen dataclasses and `match`, modeled failures returned as values — with ruff, pyright, and pytest as the gate. Applies to new code without exception; existing code is brought to match when touched.
---

# Writing Python

Write a pragmatic-functional core — small pure functions over immutable records, effects pushed to the edge, sum types dispatched with `match`, modeled failures carried as values. Pragmatic, not pure: Python rewards the functional discipline that reads as Python, and fights F# or Haskell transliterated onto a fixed-depth stack and single-expression lambdas. Such a core is more robust and less brittle than the imperative alternative.

Each rule below is a default, not a suggestion — deviating takes a reason written at the deviation site.

## Design

- Model with types; make invalid states unrepresentable. `@dataclass(frozen=True, slots=True)` for records — `frozen` blocks reassignment, `slots` cuts memory and rejects ad-hoc attributes. `NewType` for primitives that carry meaning (`UserId = NewType("UserId", int)`), `Literal` for narrow constants, `StrEnum`/`Enum` for closed sets. Validate at construction — a classmethod that returns the record or raises — so downstream code trusts the value and never re-checks. Parse, don't validate.
- Sum types as sibling frozen dataclasses; the union is `Foo | Bar | Baz`; dispatch with `match`, never an `isinstance` chain. `Protocol` for structural contracts — any type of the right shape satisfies it, no inheritance required.
- Immutable by default. Mutation is a carve-out justified by a measured hot path or a domain concept that changes in place. Frozen records, `dataclasses.replace()` for non-destructive update, `tuple`/`frozenset` and `Mapping`/`Sequence` return types over their mutable kin. A reassigned attribute in domain code is a smell.
- Small pure functions at the core, I/O at the boundary. Console, file, network, database, clock live at the entry point; the core takes data in and returns data out. A function that needs fixtures or fakes to test isn't pure — that ceremony is the design asking to be purer. Inject the clock and the connection; don't reach for `datetime.now()` or a module-level client inside a transform.
- Persistence ignorance. Domain types describe meaning; storage, serialization, and wire formats live behind adapter layers. No ORM columns or JSON field names on domain shapes.

## Idiom

- Type hints on every signature, `pyright` strict as the enforcer. `T | None` over `Optional[T]`; the `type` statement (3.12+) or `TypeAlias` for named complex types; `Final` for module-level constants. Return types are the contract — always explicit, never inferred away.
- Comprehensions for the common transform (`[f(x) for x in xs if pred(x)]`), generator expressions for lazy streams (`sum(x * x for x in xs)` allocates nothing), `itertools` (`chain`, `groupby`, `takewhile`, `accumulate`) for streaming pipelines, `functools` (`reduce` for folds, `partial`, `cache`/`lru_cache`) and `operator` (`itemgetter`, `add`) for the function forms. A `for` loop where a comprehension reads clean is a rewrite.
- `match` over `isinstance` chains — structural destructure, attribute and list patterns, guards. Replace deep recursion with `while` or `reduce`; Python has no TCO.
- Keyword-only for flags: `def fetch(*, force: bool = False)` reads `fetch(force=True)` at the call site. Resolve mutable defaults in the body (`items = items or []`), never in the signature. Context managers (`with`, `contextlib.contextmanager`) for anything that opens and closes.
- Naming: `snake_case` for functions, variables, and modules; `PascalCase` for classes; `UPPER_SNAKE` for constants; `_leading` for internal names. Single-character names only inside a comprehension or lambda where one line fixes the meaning. `ruff` orders imports (stdlib / third-party / local) and formats — don't hand-tune what it owns.

## Results, errors, and exceptions

The channel is decided by totality: a modeled outcome is a value, a substrate failure is an exception (full reasoning: `docs/notes/throw-vs-return-decided-by-totality.md`).

- Modeled outcomes are values. Success and every failure the operation's own logic produces — a parse rejecting input, a lookup finding nothing — ride in a carrier: `T | None` for plain absence, a `Result[T, E]` from `returns` or `expression` where the error vocabulary is richer, like parser chains and multi-step pipelines with cascading failure. The pure core is total, so it mints these at the boundary parsing representable-invalid input into a domain type; it never raises for them.
- Raise only for what's outside the codomain — the substrate failing or the code being wrong. Transient infrastructure faults (every partition/timeout state) are caught, retried, then propagated; liveness is undecidable, so never a modeled outcome. Bugs are a partiality the types didn't remove. Use the specific built-in — `ValueError`, `KeyError`, `RuntimeError` — never a bare `Exception`; custom exceptions inherit the closest built-in (`class ParseError(ValueError): ...`). Fail loud: when a bad state slips prevention, crash immediately over corrupting silently.
- Catch the specific type at the boundary that can act on it; a catch-all belongs only at the outermost host. EAFP — try the operation, handle the failure (`try: x.foo()` over `if hasattr(x, "foo")`). Every `raise` inside `except` carries `from` so the chain stays intact: `raise ParseError("bad input") from exc`.

## Build

- One source of truth in `pyproject.toml` at the root: `[build-system]`, `[project]`, dev dependencies as an extra (`dev = [...]`, installed with `uv pip install -e .[dev]`), and the `[tool.ruff]` / `[tool.pyright]` / `[tool.pytest.ini_options]` config. `src/<package>/` for code, `tests/` peer to it and mirroring the layout (`src/pkg/parser.py` ↔ `tests/test_parser.py`), `__init__.py` in every package directory, an `if __name__ == "__main__":` guard so imports stay side-effect-free. `uv` manages dependencies (resolver plus lockfile, replaces pip/pip-tools/virtualenv); `ruff` is lint and format in one (replaces black/flake8/isort/pyupgrade); `pyright` types in strict mode; `pytest` runs the tests.
- Test the units you own — frameworks, ORMs, and libraries carry their own suites. Plain `assert` (pytest rewrites for rich diffs), `@pytest.fixture` requested by parameter name and scoped to lifetime, `@pytest.mark.parametrize` for table-driven cases, `hypothesis` for parsers/serializers/round-trips, `syrupy` when the output shape is the contract, `pytest-asyncio` with `asyncio_mode = "auto"` so `async def test_*` runs without per-test decoration.
- Validate with the canonical script at `${CLAUDE_PLUGIN_ROOT}/skills/writing-python/scripts/build-gate.sh` — format check, lint, type check, test, each running only when the prior is green, one exit code as the gate. It verifies only; it never edits.
  - `build-gate.sh` — project-wide format, lint, type, test.
  - `build-gate.sh <pytest-target>` — project-wide format/lint/type, then scoped test. The target is anything pytest accepts: a path, a node id, or a `-k` expression.
- When a gate fires, fix the cause. Suppression is a last resort, pinned to a specific rule code with a reason on the same line — `# noqa: E501` (never bare, which silences every check at the site), `# type: ignore[arg-type]`. Project-wide ignores live in `pyproject.toml` (`[tool.ruff.lint] ignore = [...]`, `[tool.pyright] reportFoo = "none"`), one comment per rule naming why.

## Acceptance

Code is done when:

- `build-gate.sh` is green — format, lint, types, and tests all pass, with no bare `# noqa` and no unjustified project-wide ignore.
- The diff survives the greps: a mutable default in a signature; a bare `except:` or `except Exception` without re-raise outside the host boundary; a `raise` inside `except` missing `from`; `Optional[T]` where `T | None` reads; an `isinstance` chain where `match` reads clean; a reassigned attribute on a frozen-intent record; a `for` loop where a comprehension reads clean; deep recursion where `while` or `reduce` belongs.
- Every new signature carries type hints and `pyright` strict is clean.
