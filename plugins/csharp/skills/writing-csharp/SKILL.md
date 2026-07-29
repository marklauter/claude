---
name: writing-csharp
description: Use when writing or refactoring C# / .NET. A pure functional core modeled as a DDD domain — immutable business core, effects at the edge via ports/adapters, `Result`/`Either`/`IValueType` types, type-driven design, and modern-C# idioms, enforced by analyzer-strict build gates. Applies to new code without exception; existing code is brought to match when touched.
---

# Writing C#

Write a functional core and model it as a domain: pure and immutable, effects pushed to the edge, expressed with `Result`/`Either`/`IValueType` types, Evans' aggregates, and bounded contexts. Pure functions are referentially transparent, so a call reduces to its value and reasoning stays local. Immutability makes the core thread-safe by construction.

Each rule below is a default; deviating requires a reason written at the deviation site.

## Design

- Model the domain, not the database. Bounded contexts, each with its own ubiquitous language; aggregates as consistency boundaries that own their invariants. The domain is a pure, immutable business core — no persistence or serialization attributes on domain types (`[Table]`, `[Column]`, `[Key]`, `[JsonPropertyName]`, `[DataMember]`). If a reader can reverse-engineer the database or wire format from a domain type, that's a leak; mapping lives in the adapter.
- Make invalid states unrepresentable. Invariants are established at construction; once a value exists it is trusted and never re-checked. `required`/`init` members, never `set`.
- Parse, don't validate. `Parse` is the fallible lift `string → Result<TSelf>`, and validation lives there and only there. `Unchecked` is the total embedding `TValue → TSelf`: pure assignment, no validation, no normalization, lawful only on the valid subset the caller vouches for, so misuse is the caller's defect. The BCL `bool`-plus-`out` `TryParse` shape stays out of the domain contract — it is a REST-binding concern, opted into through `ITryParse<TSelf>` by the types that cross the ASP.NET boundary.
- Model state as a sum type. A closed hierarchy — an abstract base record whose sealed per-state records are its only inhabitants — for state machines. Prefer virtual dispatch over a `switch`: declare the operation abstract on the base and implement it in each inhabitant. Exhaustiveness is then a compile-time fact, because adding an inhabitant fails to compile until it implements the member, where a `switch` expression only warns (CS8509). Pattern-match where the operation can't live on the type.
- Wrap primitives that carry meaning. A `readonly record struct` implementing `IValueType<TSelf, TValue>` — `FilePath` over `string`, `Percent` over `decimal` — self-referential (CRTP) so the static abstract members resolve through the type parameter at every call site. Two arrows in, `Parse` and `Unchecked`; one arrow out, the `Value` projection back to the primitive. Wrappers also implement `IComparable<TSelf>`, `IEquatable<TSelf>`, and `IComparisonOperators<TSelf, TSelf, bool>`, so they sort and compare like the primitive. A bare `string` or `decimal` is then no longer assignment-compatible with a checked value.
- Immutable by default. Mutation is an exception justified by a measured hot path or a domain concept that genuinely changes in place. Records with `with` for non-destructive update; `IReadOnlyList<T>`/`IReadOnlyDictionary<TK,TV>` on return and field types; `ImmutableArray<T>` for shared snapshots; `readonly` on fields and structs. A `set;` in domain code is a smell.
- Compose with expressions. Expressions over statements; `Map`/`Bind`/`Match` and LINQ pipelines over `for` loops and hand-rolled branching; compose `Result<T>`/`Either<L, R>` with `Bind` instead of unwrapping and re-checking at each step.
- Push effects to the edge (functional core, imperative shell). I/O — console, file, network, database, clock — lives at the boundary through ports and adapters; the core takes data in and returns data out. Static pure transforms (tokenize, normalize, parse, format): no state, no I/O, no logging. Inject `TimeProvider` over `DateTime.UtcNow`. A test that needs test doubles or async setup means the function isn't pure.

## Idiom

- Inference over annotation. `var` when the right-hand side names the type; target-typed `new(...)` where the target is declared; collection expressions `[]` over `new List<T>()`/`Array.Empty<T>()`. Method return types stay explicit — they're the contract.
- Modern vocabulary is the default. Primary constructors for services and DI dependencies; records for data carriers; file-scoped namespaces; raw string literals for multi-line text/JSON/SQL; property, list, and relational patterns in `switch` expressions. Nullable reference types enabled — `string` means non-null, `string?` is the explicit opt-in for absence, carried through helpers with the flow-analysis attributes `NotNullWhen`/`MemberNotNull`.
- Minimal accessibility. `internal sealed` records and classes by default; `public` only for exported contract; a `public interface` over an `internal sealed` implementation. Widening is deliberate — `public` puts the type in the API surface, where narrowing it again is a breaking change.
- Performance where measured. Hot paths get `Span<T>`/`ReadOnlySpan<T>`, `ArrayPool<T>`, `ValueTask<T>`, `readonly record struct` — when a BenchmarkDotNet number says so. Cold paths stay readable.
- One source of truth. Central Package Management — versions declared once in `Directory.Packages.props`, `.csproj` references by name only, transitive pinning on. Solution-wide compiler flags in `Directory.Build.props`. Constants and configuration each declared once (`IOptions<T>` or injected immutable records). Duplicated knowledge is a defect.
- The first slice sets the pattern. The first implementation of any pattern becomes the example the next ten copy, so its cost is amortized over all of them. Get it right, then encode the invariant it establishes as an ArchUnitNET test so drift fails the build.
- The easy path is the correct path. Primary constructors make declaring a dependency the same act as capturing it immutably. Fluent `WithX()` builders make the right configuration a chain and deviation a custom builder. Structural rules encoded as ArchUnitNET tests make compliance easier than violation.

## Results, errors, and exceptions

The channel is decided by totality: a modeled outcome is a value, a substrate failure is an exception (full reasoning: `${CLAUDE_PLUGIN_ROOT}/skills/writing-csharp/throw-vs-return-decided-by-totality.md`).

- Model every operation as a total function; its codomain picks the channel. Modeled outcomes are values: success and every failure the operation's own logic produces (a parse rejecting input, a withdrawal exceeding balance, a lookup finding nothing). Return `Result<T>` / `Either<L, R>`, `Match` to handle, never unwrap `.Value`. Name the variants the domain acts on — `NotFound`, `Conflict`, `Gone`, `Validation` — each carrying its context. The pure core is total: invalid states are unrepresentable, so it cannot produce an invariant violation and never throws. Results originate at the boundary, parsing representable-invalid input into a domain type.
- Throw only for what's outside the codomain: the substrate failing or the code being wrong. Exactly three causes qualify. A transient infrastructure fault is every partition and timeout state; retry, then propagate, because liveness is undecidable and can never be a modeled outcome. A permanent infrastructure fault is configuration only; fail fast at startup. A bug is a partiality the types didn't remove: `ArgumentNullException.ThrowIfNull(param)` at public boundaries against callers you don't control, `InvalidOperationException` for misuse. Use the exception type that names what failed; never a catch-all. A domain signature returning `T` that throws for a domain failure is a defect.
- Adapters throw the substrate faults and translate at the boundary. The ones that map to a modeled outcome (row-not-found → `NotFound`) become Results; genuine infrastructure failures propagate to the host's outermost handler. The pure core never sees a raw `SqlException`.

## Build

Warnings, analyzers, nullability, and tests are the ground truth between sessions; fix what fires, don't silence it. Configure once in `Directory.Build.props`: `TreatWarningsAsErrors`, `Nullable=enable`, `AnalysisMode=All`, `AnalysisLevel=latest-all`, analyzer packs via `GlobalPackageReference`, and a monotonic coverage ratchet whose threshold is set to the measured value and only ever raised. ArchUnitNET tests encode architectural invariants (sealed concretes, no public instance fields, layer dependencies, persistence-ignorance) as xUnit tests.

Validate with the canonical script at `${CLAUDE_PLUGIN_ROOT}/skills/writing-csharp/scripts/build-gate.sh` — fail-fast format, build, test: each step runs only when the prior is green, and one exit code is the gate. It verifies only (`dotnet format --verify-no-changes`). By default it runs solution-wide; it also takes scoped build and test targets and an xUnit trait filter. Run `build-gate.sh --help` for the invocations and the target-resolution rules.

When a check fires, fix the cause; suppression is the last resort (see below). To clear a format violation, run a *scoped* `dotnet format` (`--diagnostics <ID> --include <path>`, or a `whitespace`/`style`/`analyzers` subcommand) — never bare `dotnet format`.

## Testing

Tests pin the observable contract of code you own. Coverage is a proxy metric, not the objective: testing the cases is the goal, and coverage only signals that cases are missing. An uncovered line names a case nobody wrote. A covered line proves only that some test executed it, so 100% coverage says nothing about whether the real cases are tested, and raising the number without adding cases is gaming it. Cover the cases and the number follows. Reaching 100% is not a signal to stop writing tests. The number also won't always reach 100%, because the compiler emits branches no input can hit. The case list says when a unit is covered, not the report; don't chase a branch no case can reach. The ratchet is a regression gate: no new code lands without new tests. Exclude from coverage only generated or trivial code, with a comment naming why; hand-written logic is tested.

- Cover the unit's contract whole: one case per equivalence class, the boundary values on each side of every limit, and every failure case, asserted through the public surface.
- Don't test what you don't own. Never write a test proving a framework or library does its job — that EF Core saves, that `System.Text.Json` round-trips — that's their contract, not your logic. A test that needs a framework type mocked to isolate the code under test is reporting a design defect: the core is calling the substrate directly. Fix it at the boundary — a port with the adapter behind it — not in the test.
- Don't test outside the contract. Asserting more than the contract promises — call counts, exact message wording, internal ordering — couples the test to the implementation, so a behavior-preserving refactor still fails it.
- A bug fix starts red. Write the test that reproduces the defect, prove it fails, then fix; the passing test is the bug pinned against regression.
- Flaky is a defect. A test is deterministic or it is broken: an outcome that depends on anything other than the code under test — wall clock, network, filesystem state, execution order, unseeded randomness, sleeps — is a defect to fix now. Rerunning until green is suppression without the justification.
- Follow the cost gradient: the pure core gets many cheap data-in/data-out tests; ports get fakes; the real substrate gets thin integration tests tagged `[Trait("Category", "Integration")]`.
- Test the adapter's translation, and know what that test proves. The adapter is the one place a foreign type gets substituted directly: inject the vendor's client or `DbConnection` and drive it, because a `503`, a malformed payload, and a permission error are the cases you can't provoke on demand. That test proves the mapping is right *given* your beliefs about the substrate — the status codes it returns, the exceptions it throws. It cannot prove the beliefs. Only the integration test behind it does, so a substituted adapter test standing alone is an assumption nobody checked.

## Suppression

### When to suppress

Only as a last resort, after fixing the cause fails and the diagnostic is a genuine false positive or a deliberate, justified deviation from a rule — never to quiet a real defect. Every suppression states why in its `Justification` or comment; an error, not merely a warning, carries a tracking ticket on top of the justification.

### How to suppress

Match the mechanism to the suppression's actual scope, preferring the narrowest that covers it:

- One member or type → the attribute. `[SuppressMessage("Design", "CA1034:Nested types should not be visible", Justification = "…")]` on the declaration the diagnostic fires on. First choice: scoped to a single site and self-documenting.
- A rule that fights a codebase-wide convention → `<NoWarn>`, at the narrowest level matching its scope. Append to `$(NoWarn)` (never overwrite it), one `<!-- CODE short-desc : why -->` comment per code. Gate test-only suppressions behind the test-project `Condition` so a test suppression never loosens production. A project-specific suppression stays in that project's `.csproj` or its `GlobalSuppressions.cs` (`[assembly: SuppressMessage]`) when it is truly project-wide; the solution-wide `Directory.Build.props` is only for suppressions every project genuinely shares.
- A file-local compiler or style warning no attribute can target → `#pragma warning disable`/`restore <CODE>` around the minimal span, restored immediately. Last resort.

## Acceptance

Code is done when:

- `build-gate.sh` is green — format, build, test, and the coverage ratchet all pass, with no surviving warnings and no unjustified suppressions.
- The diff survives the greps: `set;` in domain code; persistence/serialization attributes on domain types; `throw` in a domain signature that returns `T`; a `for` loop where a LINQ pipeline reads clean; explicit types where `var` reads clean; `catch (Exception)` without re-throw outside the host's outermost handler; a mocked framework type in a test outside an adapter, where a port belongs.
- Every new pattern's first instance carries its ArchUnitNET test in the same change set.
