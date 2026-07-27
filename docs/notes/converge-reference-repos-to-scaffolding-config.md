---
title: Converge the four reference repos to the canonical scaffolding config
summary: plumber, pool, kingo, and dynamodblite all sit at "moderate drift" from the scaffolding-csharp template — the build-gate core is aligned everywhere; the drift is stale .editorconfigs, missing centralization conventions, and a few gate/version settings. One branch per repo, each its own PR. The .editorconfig sweep is DONE (2026-07-14) — all four now match the template byte-for-byte; MSBuild-layer drift remains.
tags: [todo, csharp, scaffolding, convergence]
created: 2026-07-14
status: open
---

Bring the four reference repos onto the canonical scaffolding config so a repo scaffolded today and one that predates the template are indistinguishable at the build layer. Canonical baseline: `plugins/csharp/skills/scaffolding-csharp/template/`. One branch per repo, each pushed as its own PR (the repos are independent).

## What's already aligned everywhere

Don't touch these — all four match: `.slnx` solution format, Central Package Management (`ManagePackageVersionsCentrally` + `CentralPackageTransitivePinningEnabled`), the analyzer-strict core (`net10.0`, `Nullable`, `AnalysisMode=All`, `AnalysisLevel=latest-all`, `TreatWarningsAsErrors`, `EnforceCodeStyleInBuild`), `IDisposableAnalyzers` as the mandatory global analyzer, ArchUnitNET arch tests present, `.gitignore` present, symbols/SourceLink props. Every repo is at **moderate drift**, not major — this is tightening, not rebuilding.

## Cross-cutting drift (fix in every repo)

1. ~~**`.editorconfig` is stale in all four**~~ — **DONE 2026-07-14.** All four now carry the template's `.editorconfig` verbatim (plumber #31, pool #12, dynamodblite #98 merged; kingo copied into the working tree on `reboot`, uncommitted, per active WIP there). Swept across all 17 first-party C# repos, not just these four. What the sweep taught, in "Settled by the sweep" below.
2. **MTP2 migration TODO comment missing** in all four (`Directory.Packages.props`).
3. **Test `NoWarn` list incomplete** in all four — canonical is `CA1707;CA1515;CA1812;IDE1006;IDE0079`; each repo covers only a subset (see per-repo).

## Per-repo findings

### plumber — 4 NuGet packages + Sample.Cli (Exe) + Architecture.Testing base. Effort: M
- Zero shared-package version drift. Arch-test base present. `global.json` aligned.
- `.editorconfig` conflicts: `csharp_style_expression_bodied_constructors` → template `true:suggestion` vs repo **`false:silent`** (contradicts the expression-bodied preference); `csharp_prefer_braces` → `false` vs **`true`** (opposite); `csharp_style_namespace_declarations` → `file_scoped:warning` vs **`block_scoped:silent`**.
- `Directory.Build.targets` doc-gen drops the `and '$(IsPackable)' != 'false'` guard (generates XML docs for non-packable libs too).
- Test config done piecemeal per-csproj: `ExcludeByFile=**/obj/**/*.g.cs` missing; test NoWarn covers only `CA1515;CA1812` (missing CA1707, IDE1006, IDE0079).
- Keep as-is: per-csproj `InternalsVisibleTo` (needs an extra `.Testing` grant the centralized item can't express); solution-wide `NoWarn CA1308;CA2007` (justified repo policy).

### pool — Pool NuGet package + Smtp.Pool samples. Effort: M
- **Missing `Directory.Build.targets` entirely** (hardcodes `GenerateDocumentationFile` in Pool.csproj instead).
- Arch tests inlined in the single test project — correct (a shared base earns nothing with one consumer), but the inlined set **omits two rules** the template's base carries: `PublicTypesAreNotNested` and `AsyncMethodsHaveAsyncSuffix`. Add those rules; don't extract a base.
- `LangVersion` unpinned; CI `ContinuousIntegrationBuild` group missing; universal `InternalsVisibleTo` + centralized test refs missing (per-csproj instead).
- Coverage `ThresholdStat` → **`total`** (aggregate) vs canonical `minimum` (per-class floor) — a single uncovered class can't fail the build.
- `global.json` → `10.0.102` / **`latestPatch`** (vs `10.0.100` / `latestFeature`). Package drift: `Microsoft.NET.Test.Sdk` 18.6.0 → 18.7.0. Test NoWarn missing `CA1812`.
- Keep as-is: security-rule severities + `[tests/**]` editorconfig carve-out (deliberate).

### kingo — in-solution libraries only (Kingo, Kingo.Pdl, Results, Values, Serialization…). Effort: M
- **Real bug, not drift: `Kingo.Pdl` and `Kingo.Pdl.Tests` exist on disk with full arch tests but are absent from `Kingo.slnx`** — they don't build or test with the solution. Add them.
- Arch-test base present (`Kingo.Testing`), CI-independent build gate intact.
- `.editorconfig` philosophy divergence: `block_scoped:silent` namespaces (vs `file_scoped:warning`), `csharp_prefer_braces=true` (vs `false`), `expression_bodied_constructors=false:silent` (again contradicts the stated preference). CA1062 handled via `.editorconfig severity=none` rather than the library NoWarn — functionally equivalent, different mechanism.
- CI `ContinuousIntegrationBuild` missing. Test NoWarn covers only `CA1515;CA1812` (missing CA1707, IDE1006, IDE0079). `Kingo.Testing.csproj` missing `CA1515;CS1591` NoWarn its public base needs.
- Package lag: `coverlet.collector`/`coverlet.msbuild` 10.0.0 → 10.0.1, `Microsoft.NET.Test.Sdk` 18.5.1 → 18.7.0, `TimeProvider.Testing` 10.5.0 → 10.7.0. `global.json` 10.0.203 (newer patch, fine).
- Keep as-is (arguably adopt into the template): per-assembly coverage `<Include>[<SUT>]*</Include>` scoping is an improvement; global `NoWarn CA2225;IDE0011` is deliberate repo policy.

### dynamodblite — DynamoDbLite NuGet package + bench (Exe) + Parity.Tests. Effort: M
- **Missing `Directory.Build.targets`** (hardcodes doc-gen in src csproj).
- **CI `ContinuousIntegrationBuild` missing on a published package** — loses reproducible builds + normalized SourceLink paths in the shipped artifact.
- **Concern: global `NoWarn CA2007` applies to the shipped package**, suppressing the ConfigureAwait analyzer on library code — review whether that's intended for a package.
- `LangVersion` unpinned. Coverage `ThresholdStat` → **`total`** vs canonical `minimum`. `global.json` → `10.0.102` / `latestPatch`. Test NoWarn diverges (`CA1707;CA1051;IDISP026;IDE1006`; drops CA1515/CA1812/IDE0079, adds CA1051/IDISP026 — CA1515/CA1812 silenced via editorconfig `[tests/**]` instead).
- Zero shared-package version drift.
- Keep as-is: arch tests inlined in the single test project (a shared base earns nothing with one consumer — not a divergence); `bench/` relaxed analyzers; `Parity.Tests` `Threshold=0` override; security-pinned SQLitePCLRaw.

## Settled by the .editorconfig sweep (2026-07-14)

- **The `.editorconfig` is pure style; suppressions live in MSBuild.** This is the sweep's main lesson and it settles the suppression half of the centralization question below. The template has no `[tests/**]` section, so adopting it verbatim deletes any test-only carve-out a repo was keeping there. pool hit this hard — its old config held `dotnet_diagnostic.CA2007.severity = none` under `[*.{cs,vb}]` plus six test-only suppressions under `[tests/Pool*.Tests/**.cs]`, and a verbatim copy re-enabled CA2007 across `src/Pool` and `samples/Smtp.Pool`. The fix was to move them to `NoWarn` (`CA2007` solution-wide, `CA1515;CA1812` on the test project) and leave the `.editorconfig` identical to the template. dynamodblite already had that shape, which is the only reason its sweep PR went green on the first try. **Don't add a `[tests/**]` section to the template — route test suppressions through the test project's `NoWarn`.**
- **`expression_bodied_constructors` — template wins.** plumber's sweep PR failed `format` on IDE0021 ×2; the constructors were fixed rather than the setting reverted. Template stays `true:suggestion`.
- **Namespace / braces philosophy — template wins.** plumber's `.editorconfig` is now byte-identical to the template (file-scoped namespaces, `csharp_prefer_braces = false`) and its full gate is green, so the reconciliation carries no hidden cost. Applies to kingo when its WIP settles.
- **A style-only config can't break a build that was already broken.** Three repos' sweep PRs failed for pre-existing reasons (hash-n-chain SCS sarif exit 150; lexi and tello.io NU1605 package downgrades at `Restore`). When a sweep PR goes red, check the failing stage before assuming the config caused it — anything failing at restore or in tooling isn't yours.

## Decisions to make before converging (they recur across repos)

- **`ThresholdStat` minimum vs total**: pool and dynamodblite weakened it to `total`. Adopt `minimum` (per-class floor, the template intent) unless there's a reason to keep aggregate.
- **Centralization vs per-csproj**: the suppression half is settled above (MSBuild `NoWarn`, not editorconfig). Still open: whether to pull `InternalsVisibleTo` and the test `PackageReference`/`Using` set into `Directory.Build.props` everywhere (plumber needs an extra `.Testing` grant that resists centralization).
- **Shared arch-test base is a ≥2-consumer artifact**, not a convergence target. kingo (8 arch-test projects) and plumber earn the base; pool and dynamodblite have a single arch-test consumer and correctly inline — converge the *rules*, never force the base.
- **Backport candidates into the template**: kingo's per-assembly coverage `<Include>` scoping looks strictly better than the template's unscoped default — consider promoting it to canonical before converging, so the repos converge onto the improved version.

## Execution order

1. Resolve the decisions above (they change what "canonical" means for the sweep).
2. Land any agreed template backports first (e.g. per-assembly coverage `Include`), so all four converge to one target.
3. ~~Reconcile `.editorconfig` first~~ — done 2026-07-14. Per repo, on its own branch: MSBuild files (targets, props test block, CI group, versions, NoWarn), then repo-specific fixes (kingo's missing `.slnx` projects, dynamodblite's package `CA2007`). Green `build-gate.sh` on each before PR.
