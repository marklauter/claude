---
name: writing-python
description: Use when writing or refactoring Python. A pragmatic-functional core modeled as a DDD domain — immutable frozen-dataclass records, effects at the edge via Protocol ports, sum types as unions of sibling records, modeled failures returned as values — enforced by ruff, pyright strict, and pytest as the gate. Applies to new code without exception; existing code is brought to match when touched.
---

# Writing Python

Write a functional core and model it as a domain: pure and immutable, effects pushed to the edge, expressed with `Result` types, Evans' aggregates, and bounded contexts. Pure functions are referentially transparent, so a call reduces to its value and reasoning stays local. Immutability removes the shared mutable state that makes concurrent code unsafe.

Pragmatic, not pure. Python rewards the functional discipline that reads as Python and fights Haskell transliterated onto a recursion limit and single-expression lambdas; where the two conflict, the Python form wins.

Each rule below is a default; deviating requires a reason written at the deviation site.

## Design

- Model the domain, not the database. Bounded contexts, each with its own ubiquitous language; aggregates as consistency boundaries that own their invariants. Keep persistence and serialization off domain types: no `__tablename__`, no SQLAlchemy `Mapped[...]`/`Column`, no Pydantic `Field(alias=...)`, no `to_dict`/`to_json` members. If a reader can reconstruct the schema or the wire format from a domain type, that's a leak; mapping lives in the adapter.
- Make invalid states unrepresentable. `@dataclass(frozen=True, slots=True, kw_only=True)` for records: `frozen` blocks reassignment, `slots` rejects attributes nobody declared, `kw_only` names every field at the call site. Enforce the invariant in `__post_init__` and raise there, because Python has no private constructor to hide an unchecked path behind.
- Parse, don't validate. A `parse` classmethod at each untrusted boundary is the fallible lift `str → Result[Self, Error]`, and it is the only place external input becomes a domain value. It catches what `__post_init__` raises and returns that as a value. Nothing downstream re-checks: a value that exists is valid.
- Model state as a sum type. Sibling frozen dataclasses under a union alias — `type Job = Queued | Running | Done`. Prefer a method on each variant over a `match` at the call site, so a new variant that omits the method is a pyright error at every use. Where the operation can't live on the type, `match` on it and close the fallthrough with `assert_never(x)`, which makes pyright fail when a variant is added.
- Wrap primitives that carry meaning. `NewType("UserId", int)` when the wrapper only needs to be a distinct name: zero runtime cost, but erased, so only pyright rejects a bare `int`. A frozen single-field dataclass when the constraint must hold at runtime or the type needs behavior, since it can carry `parse` and its own methods. `Literal` for narrow constants, `StrEnum` for a closed set of names.
- Immutable by default. Mutation is an exception justified by a measured hot path or a domain concept that changes in place. `dataclasses.replace()` for non-destructive update; `tuple`/`frozenset` inside records; `Sequence`/`Mapping` on parameters and return types so a caller can't mutate through them. A reassigned attribute in domain code is a smell.
- Compose with expressions. Comprehensions for the common transform, generator expressions for lazy streams, `itertools` (`chain`, `groupby`, `takewhile`, `accumulate`) for pipelines, `functools` (`reduce`, `partial`, `cache`) and `operator` (`itemgetter`, `add`) for the function forms. Chain `Result` with `map`/`bind` instead of unwrapping and re-checking at each step. Replace deep recursion with a loop or a fold; Python eliminates no tail calls.
- Push effects to the edge (functional core, imperative shell). I/O — console, file, network, database, clock — lives at the boundary behind a `Protocol` port; the core takes data in and returns data out. Inject the clock and the connection; never call `datetime.now()` or reach for a module-level client inside a transform. Keep import time free of side effects and guard entry points with `if __name__ == "__main__":`. A function that needs a test double or async setup isn't pure.

## Idiom

- Annotate the contract, infer the locals. Every signature carries hints, return types always explicit, `pyright` strict as the enforcer. Don't restate what the right-hand side already says — `count: int = 0` is noise.
- Modern vocabulary is the default. `T | None` over `Optional[T]`; the `type` statement over `TypeAlias`; `Self` for returns of the same type; `@override` on every override; `StrEnum` over string constants; `match` over `isinstance` chains; `pathlib` over `os.path`; f-strings over `%` and `.format()`; `tomllib` for TOML; `Final` for module-level constants. Keyword-only for flags — `def fetch(*, force: bool = False)` reads `fetch(force=True)` at the call site. Resolve mutable defaults in the body, never in the signature.
- Minimal accessibility. A leading underscore marks everything outside the contract, `__all__` declares what a module exports, `@final` closes a concrete class, and a `Protocol` carries the contract others depend on. Never import another package's `_name`. Widening is deliberate: a public name is a commitment, where narrowing it again is a breaking change.
- Performance where measured. `__slots__`, generators over materialized lists, `memoryview` over copies, `functools.cache` on hot pure functions — when a `pytest-benchmark` or `timeit` number says so. Cold paths stay readable.
- One source of truth. `pyproject.toml` holds `[build-system]`, `[project]`, dev dependencies as an extra, and the `[tool.ruff]`/`[tool.pyright]`/`[tool.pytest.ini_options]`/`[tool.coverage]` config. Constants declared once with `Final`; configuration as one frozen dataclass parsed at the edge, never `os.environ` reads scattered through the core. Duplicated knowledge is a defect.
- The first slice sets the pattern. The first implementation of any pattern becomes the example the next ten copy, so its cost is amortized over all of them. Get it right, then encode the invariant it establishes as an `import-linter` contract or a ruff rule so drift fails the build.
- The easy path is the correct path. `@dataclass(frozen=True, slots=True)` makes the immutable record the shortest thing to declare. A `Protocol` port makes a hand-written fake shorter than a mock. Structural rules in `pyproject.toml` make compliance automatic and deviation the thing you have to type.

## Results, errors, and exceptions

The channel is decided by totality: a modeled outcome is a value, a substrate failure is an exception (full reasoning: `${CLAUDE_PLUGIN_ROOT}/skills/writing-python/raise-vs-return-decided-by-totality.md`).

- Model every operation as a total function; its codomain picks the channel. Modeled outcomes are values: success and every failure the operation's own logic produces (a parse rejecting input, a withdrawal exceeding balance, a lookup finding nothing). Carry them in `T | None` for plain absence, or a `Result[T, E]` from `returns` or `expression` where the error vocabulary is richer. Name the variants the domain acts on — `NotFound`, `Conflict`, `Validation` — each carrying its context. The pure core is total: invalid states are unrepresentable, so it cannot produce an invariant violation and never raises. Results originate at the boundary, parsing representable-invalid input into a domain type.
- Raise only for what's outside the codomain: the substrate failing or the code being wrong. Exactly three causes qualify. A transient infrastructure fault is every partition and timeout state; retry with `tenacity`, then propagate, because liveness is undecidable and can never be a modeled outcome. A permanent infrastructure fault is configuration only; fail fast at import or startup. A bug is a partiality the types didn't remove: an explicit guard raising `ValueError`/`TypeError` at a public boundary against callers you don't control, `RuntimeError` for misuse. Use the specific built-in, never a bare `Exception`, and let a custom exception inherit the closest one (`class ParseError(ValueError)`). A domain signature returning `T` that raises for a domain failure is a defect.
- Adapters raise the substrate faults and translate at the boundary. Prefer EAFP: attempt the operation and handle the failure rather than testing for permission first. Catch the specific type where you can act on it — the ones that map to a modeled outcome (`NoResultFound` → `NotFound`) become values, and genuine infrastructure failures propagate to the host's outermost handler. Every `raise` inside `except` carries `from` so the chain stays intact. Never swallow `CancelledError` or `KeyboardInterrupt`; they are cooperative control flow, not outcomes. The pure core never sees a raw `OperationalError`.

## Build

Lint, types, and tests are the ground truth between sessions; fix what fires, don't silence it. Configure once in `pyproject.toml`: `ruff` for lint and format (it replaces black, flake8, isort, and pyupgrade), `pyright` in strict mode, `pytest` for tests, `uv` for dependencies and the lockfile. Put the coverage ratchet in `addopts` — `--cov=src --cov-branch --cov-fail-under=<N>` — so a bare `pytest` enforces it; the threshold is monotonic, set to the measured value and only ever raised. Encode architectural invariants (layer dependencies, persistence ignorance, no adapter import reaching into the core) as `import-linter` contracts asserted by a test, so they run inside the same pytest step that runs everything else.

`src/<package>/` for code, `tests/` mirroring it (`src/pkg/parser.py` ↔ `tests/test_parser.py`), `__init__.py` in every package directory.

Validate with the canonical script at `${CLAUDE_PLUGIN_ROOT}/skills/writing-python/scripts/build-gate.sh` — fail-fast format, lint, types, test: each step runs only when the prior is green, and one exit code is the gate. It verifies only; it never edits. By default it runs project-wide; it also takes a scoped pytest target. Run `build-gate.sh --help` for the invocations.

When a check fires, fix the cause; suppression is the last resort (see below). To clear a violation, run a *scoped* fix — `ruff format <path>` or `ruff check --fix <path>` on the file that fired, never a project-wide rewrite that buries the diff.

## Testing

Tests pin the observable contract of code you own. Coverage is a proxy metric, not the objective: testing the cases is the goal, and coverage only signals that cases are missing. An uncovered line names a case nobody wrote. A covered line proves only that some test executed it, so 100% coverage says nothing about whether the real cases are tested, and raising the number without adding cases is gaming it. Cover the cases and the number follows. Reaching 100% is not a signal to stop writing tests. The number also won't always reach 100%, because `if TYPE_CHECKING:` blocks, `@overload` stubs, and `Protocol` method bodies never execute; exclude those in `[tool.coverage.report] exclude_also` rather than lowering the threshold. The ratchet is a regression gate: no new code lands without new tests.

- Cover the unit's contract whole: one case per equivalence class, the boundary values on each side of every limit, and every failure case, asserted through the public surface. `@pytest.mark.parametrize` for the table; `hypothesis` for parsers, serializers, and round-trips, where the property holds over a whole domain instead of the cases you happened to list.
- Don't test what you don't own. Never write a test proving a library does its job — that SQLAlchemy persists, that `json` round-trips — that's their contract, not your logic. Don't mock what you don't own either: wrap the foreign type in a `Protocol` port and substitute a fake for the port.
- Don't test outside the contract. Asserting more than the contract promises — call counts, exact message wording, internal ordering — couples the test to the implementation, so a behavior-preserving refactor still fails it. This is the concrete reason a hand-written fake beats `unittest.mock`: `Mock` makes the call-count assertion the easiest thing to write.
- A bug fix starts red. Write the test that reproduces the defect, prove it fails, then fix; the passing test is the bug pinned against regression.
- Flaky is a defect. A test is deterministic or it is broken: an outcome that depends on anything other than the code under test — wall clock, network, filesystem state, execution order, unseeded randomness, `sleep` — is a defect to fix now. Seed `random` and `hypothesis`, take `tmp_path` over a shared directory, and never disable test-order randomization to hide an ordering bug.
- Follow the cost gradient: the pure core gets many cheap data-in/data-out tests; ports get fakes; the real substrate gets thin integration tests marked `@pytest.mark.integration` and registered under `[tool.pytest.ini_options] markers`, so `-m "not integration"` selects the fast set.
- Write tests as plain `assert` (pytest rewrites it for rich diffs), fixtures requested by parameter name and scoped to their lifetime, `syrupy` when the output shape itself is the contract, and `pytest-asyncio` with `asyncio_mode = "auto"` so `async def test_*` needs no decoration.

## Suppression

### When to suppress

Only as a last resort, after fixing the cause fails and the diagnostic is a genuine false positive or a deliberate, justified deviation from a rule — never to quiet a real defect. Every suppression names the rule and states why at the site.

### How to suppress

Match the mechanism to the suppression's actual scope, preferring the narrowest that covers it:

- One line → the coded inline comment. `# noqa: E501 - vendored URL, cannot wrap` or `# type: ignore[arg-type] - upstream stub is wrong`. First choice: scoped to a single site and self-documenting. Never bare `# noqa` or bare `# type: ignore`, which silence every check at the site.
- A rule that fights a convention in one area → `[tool.ruff.lint.per-file-ignores]`, keyed to the narrowest glob that covers it, one comment per code naming why. Keep test carve-outs under `tests/**` so a test suppression never loosens `src/`.
- A rule that fights a codebase-wide convention → `[tool.ruff.lint] ignore` or `[tool.pyright] reportFoo = "none"`. Last resort: it applies everywhere, so it needs the strongest justification and a tracking ticket when it silences an error rather than a warning.

## Acceptance

Code is done when:

- `build-gate.sh` is green — format, lint, types, tests, and the coverage ratchet all pass, with no bare `# noqa`, no bare `# type: ignore`, and no unjustified project-wide ignore.
- The diff survives the greps: a mutable default in a signature; `except:` or `except Exception` without re-raise outside the host boundary; a `raise` inside `except` missing `from`; `Optional[T]` where `T | None` reads; an `isinstance` chain where a method on the variant belongs; a reassigned attribute on a frozen-intent record; a `for` loop where a comprehension reads clean; `datetime.now()` or a module-level client inside a transform; `unittest.mock` where a fake port belongs.
- Every new pattern's first instance carries its `import-linter` contract or ruff rule in the same change set.
