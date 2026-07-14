---
name: writing-csharp
description: Use when writing or refactoring C# / .NET. A pure functional core modeled as a DDD domain — immutable business core, effects at the edge via ports/adapters, `Result`/`Either`/`IValue` types, type-driven design, and modern-C# idioms, enforced by analyzer-strict build gates. Applies to new code without exception; existing code is brought to match when touched.
---

# Writing C#

Write a functional core and model it as a domain — pure and immutable, effects pushed to the edge, spoken in `Result`/`Either`/`IValue` and Evans' aggregates and bounded contexts. Such a core is more robust, more stable, and less brittle than the imperative alternative.

Each rule below is a default, not a suggestion — deviating takes a reason written at the deviation site.

## Design

- Model the domain, not the database. Bounded contexts, each with its own ubiquitous language; aggregates as consistency boundaries that own their invariants. The domain is a pure, immutable business core — no persistence or serialization attributes on domain types (`[Table]`, `[Column]`, `[Key]`, `[JsonPropertyName]`, `[DataMember]`). If a reader can reverse-engineer the database or wire format from a domain type, that's a leak; mapping lives in the adapter.
- Make invalid states unrepresentable. Construction is where invariants land; once a value exists it is trusted and never re-checked. Validation lives in a `Result`-returning `static Result<T> Parse(...)` at untrusted boundaries — it owns every check; a trusted `static T Create(TValue)` wraps an already-valid value and never validates (its misuse is the caller's defect). `required`/`init` members, never `set`. Discriminated unions (abstract base record + sealed per-state records) for state machines; pattern-match to handle. Parse, don't validate.
- Wrap primitives that carry meaning. A `readonly record struct` value type via `IValue` — `FilePath` over `string`, `Percent` over `decimal` — so the type states the constraint and a bare `string` or `decimal` can't stand in for a checked value.
- Immutable by default. Mutation is a carve-out justified by a measured hot path or a domain concept that genuinely changes in place. Records with `with` for non-destructive update; `IReadOnlyList<T>`/`IReadOnlyDictionary<TK,TV>` on return and field types; `ImmutableArray<T>` for shared snapshots; `readonly` on fields and structs. A `set;` in domain code is a smell.
- Compose with expressions. Expressions over statements; `map`/`bind`/`Match` and LINQ pipelines over `for` loops and hand-rolled branching; thread `Result<T>`/`Either<L, R>` through `bind` instead of unwrapping and re-checking.
- Push effects to the edge. I/O — console, file, network, database, clock — lives at the boundary through ports and adapters; the core takes data in and returns data out. Static pure transforms (tokenize, normalize, parse, format): no state, no I/O, no logging. Inject `TimeProvider` over `DateTime.UtcNow`. A test that needs mocks or async setup means the function isn't pure.

## Idiom

- Inference over annotation. `var` when the right-hand side names the type; target-typed `new(...)` where the target is declared; collection expressions `[]` over `new List<T>()`/`Array.Empty<T>()`. Method return types stay explicit — they're the contract. Clarity comes from names, not restated types.
- Modern vocabulary is the default, not the opt-in. Primary constructors for services and DI dependencies; records for data carriers; file-scoped namespaces; raw string literals for multi-line text/JSON/SQL; property, list, and relational patterns in `switch` expressions. Nullable reference types enabled — `string` means non-null, `string?` is the explicit opt-in for absence, carried through helpers with `NotNullWhen`/`MemberNotNull`.
- Minimal visibility. `internal sealed` records and classes by default; `public` only for exported contract; a `public interface` over an `internal sealed` implementation. Widening is deliberate — a `public` type is a commitment, not a default.
- Performance where measured. Hot paths get `Span<T>`/`ReadOnlySpan<T>`, `ArrayPool<T>`, `ValueTask<T>`, `readonly record struct` — when a BenchmarkDotNet number says so. Cold paths stay readable.
- One source of truth. Central Package Management — versions declared once in `Directory.Packages.props`, `.csproj` references by name only, transitive pinning on. Solution-wide compiler flags in `Directory.Build.props`. Constants and configuration each declared once (`IOptions<T>` or injected immutable records). Duplicated knowledge is a defect.
- The first slice sets the pattern. The first implementation of any pattern becomes the example the next ten copy. Invest disproportionate care in it, and encode the invariant it establishes as an ArchUnitNET test so drift trips the build.
- The easy path is the correct path. Primary constructors make declaring a dependency the same act as capturing it immutably. Fluent `WithX()` builders make the right configuration a chain and deviation a custom builder. Structural rules encoded as ArchUnit tests make compliance easier than violation.

## Results, errors, and exceptions

The channel is decided by totality: a modeled outcome is a value, a substrate failure is an exception (full reasoning: `${CLAUDE_PLUGIN_ROOT}/skills/writing-csharp/throw-vs-return-decided-by-totality.md`).

- Model every operation as a total function; its codomain picks the channel. Modeled outcomes — success and every failure the operation's own logic produces (a parse rejecting input, a withdrawal exceeding balance, a lookup finding nothing) — are values: return `Result<T>` / `Either<L, R>`, `Match` to handle, never unwrap `.Value`. Name the variants the domain acts on — `NotFound`, `Conflict`, `Gone`, `Validation` — each carrying its context. The pure core is total: invalid states are unrepresentable, so it never mints an invariant violation and never throws. Results are born at the boundary, parsing representable-invalid input into a domain type.
- Throw only for what's outside the codomain — the substrate failing or the code being wrong. Infrastructure faults are two kinds: transient (every partition/timeout state — retry, then propagate; liveness is undecidable, so never a modeled outcome) and permanent (configuration only — fail fast at startup). Bugs are the third — a partiality the types didn't remove: `ArgumentNullException.ThrowIfNull(param)` at public boundaries against callers you don't control, `InvalidOperationException` for misuse. Use the exception type that names what failed; never a catch-all. A domain signature returning `T` that throws for a domain failure is a defect.
- Adapters throw the substrate faults and translate at the boundary. The ones that map to a modeled outcome (row-not-found → `NotFound`) become Results; genuine infrastructure failures propagate to the host's outermost handler. The pure core never sees a raw `SqlException`.

## Build

Warnings, analyzers, nullability, and tests are the ground truth between sessions — fix what fires, don't silence it. Configure once in `Directory.Build.props`: `TreatWarningsAsErrors`, `Nullable=enable`, `AnalysisMode=All`, `AnalysisLevel=latest-all`, analyzer packs via `GlobalPackageReference`, a coverage ratchet locked at the current value and moved only forward. ArchUnitNET tests encode architectural invariants (sealed concretes, no public instance fields, layer dependencies, persistence-ignorance) as xUnit tests.

Validate with the canonical script at `${CLAUDE_PLUGIN_ROOT}/skills/writing-csharp/scripts/build-gate.sh` — format, build, test, each running only when the prior is green, one exit code as the gate. It verifies only (`dotnet format --verify-no-changes`); it never edits.

- `build-gate.sh` — solution-wide format, build, test.
- `build-gate.sh <test-target>` — solution-wide format, then scoped test (build is implicit in `dotnet test`).
- `build-gate.sh <build-target> <test-target>` — scoped build and test when the pairing isn't the conventional `<X>.Tests` ↔ `<X>`.
- `build-gate.sh --filter <expr>` — forward an xUnit trait filter to every test run: `--filter "Category=Unit"`, `--filter "Category!=Integration"`, `--filter "FullyQualifiedName~Parser"`. Composes with any target. Tag classes with `[Trait("Category", "…")]` to select them.

Each target is anything `dotnet` accepts — project name, `.csproj`, or `.slnx`.

When a gate fires, fix the cause; suppression is the last resort (see below). To clear a format violation, run a *scoped* `dotnet format` (`--diagnostics <ID> --include <path>`, or a `whitespace`/`style`/`analyzers` subcommand) — never bare `dotnet format`. Exclude from coverage only generated or trivial code, with a comment naming why; hand-written logic is tested.

## Suppression

### When to suppress

Only as a last resort, after fixing the cause fails and the diagnostic is a genuine false positive or a deliberate, justified deviation from a rule — never to quiet a real defect. Every suppression states why in its `Justification` or comment; an error, not merely a warning, carries a tracking ticket on top of the justification.

### How to suppress

Reach for the narrowest, most structured mechanism the suppression's true scope allows:

- One member or type → the attribute. `[SuppressMessage("Design", "CA1034:Nested types should not be visible", Justification = "…")]` on the declaration the diagnostic fires on. First choice: scoped to a single site and self-documenting.
- A rule that fights a codebase-wide convention → `<NoWarn>`, at the narrowest level matching its scope. Append to `$(NoWarn)` (never overwrite it), one `<!-- CODE short-desc : why -->` comment per code. Gate test-only carve-outs behind the test-project `Condition` so a test suppression never loosens production. A project-specific suppression stays in that project's `.csproj` or its `GlobalSuppressions.cs` (`[assembly: SuppressMessage]`) when it is truly project-wide; the solution-wide `Directory.Build.props` is only for suppressions every project genuinely shares.
- A file-local compiler or style warning no attribute can target → `#pragma warning disable`/`restore <CODE>` around the minimal span, restored immediately. Last resort.

## Acceptance

Code is done when:

- `build-gate.sh` is green — format, build, test, and the coverage ratchet all pass, with no surviving warnings and no unjustified suppressions.
- The diff survives the greps: `set;` in domain code; persistence/serialization attributes on domain types; `throw` in a domain signature that returns `T`; a `for` loop where a LINQ pipeline reads clean; explicit types where `var` reads clean; `catch (Exception)` without re-throw outside the host's outermost handler.
- Every new pattern's first instance carries its ArchUnit test in the same change set.
