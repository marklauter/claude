---
name: scaffolding-csharp
description: Use when standing up a new C# solution or project — library, NuGet package, or ASP.NET Core web API. Installs and runs a folder-based `dotnet new` template that lays down the analyzer-strict build gate (Directory.Build.props/targets, Central Package Management, coverage ratchet), a shared ArchUnitNET base, and a wired solution, then hands off to writing-csharp for the code.
---

# Scaffolding C#

Generate the skeleton from the template; write the code under writing-csharp. The template encodes the build gate, CPM, doc-gen, InternalsVisibleTo, and the shared arch-test base so a new solution starts green and analyzer-strict.

## Generate

Install the folder template once per machine, then invoke it per solution:

```
dotnet new install ${CLAUDE_PLUGIN_ROOT}/skills/scaffolding-csharp/template
dotnet new msl-csharp -n <Name> -t <library|package|webapi>
```

The project-type flag is `-t` (long form `--param:type`); dotnet-new reserves `--type` for its own template filter, so it is not available.

- `-t library` — in-solution library or app. Not packable. CA1062 off (nullable reference types are the null contract; no runtime re-checks).
- `-t package` — published NuGet package. Packable, SourceLink, doc-gen. CA1062 on (external callers can pass null past the compiler; `ArgumentNullException.ThrowIfNull` at every public boundary).
- `-t webapi` — ASP.NET Core web API. Adds a security-analyzer floor and a commented PumaScan hook. CA1062 on. Not packable.

`<Name>` substitutes across folders, files, namespaces, the `.csproj`s, and the `.slnx` (e.g. `Acme.Widgets`). Update the template in place by re-running `dotnet new install` with `--force`.

## Finish what can't be templated

Three steps the generator can't do — do them once the first real code lands:

1. **Set the coverage floor.** The ratchet in `Directory.Build.props` is seeded at `0,0,0`. After the first green `build-gate.sh` run, raise `<Threshold>` to the measured line,branch,method. Never lower it.
2. **Add each project's arch bans, and re-tighten the base.** The derived `ArchitectureTests` inherits the universal rules and ships one commented example. Encode each project-specific invariant (a forbidden dependency, a factory-only constructor) as a `[Fact]` the first time it matters. The base rules ship with `WithoutRequiringPositiveResults()` so an empty scaffold stays green; once real types exist, drop it from the rules that should always have subjects (`AllTypesResideInRootNamespace`, `ConcreteClassesAreSealed`) so they can't pass vacuously.
3. **Justify suppressions as they arise.** Every `<NoWarn>` carries a `<!-- CODE desc : why -->` comment per code; every inline suppression carries a `Justification`. Add them at the suppression site when a real one appears — don't pre-populate.

For the webapi type, confirm the current PumaScan package id/version on nuget.org and uncomment the `GlobalPackageReference` in `Directory.Packages.props`.

## Hand-off

- **writing-csharp** governs the code you write into the skeleton — type-driven design, immutability, Result-based errors, persistence ignorance.
- Validate with the canonical gate at `${CLAUDE_PLUGIN_ROOT}/skills/writing-csharp/scripts/build-gate.sh` (same csharp plugin) — format, build, test, one exit code as the gate.
