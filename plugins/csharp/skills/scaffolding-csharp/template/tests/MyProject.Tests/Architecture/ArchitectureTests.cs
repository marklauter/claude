using System.Reflection;

namespace MyProject.Tests.Architecture;

/// <summary>
/// MyProject's architecture rules: the shared invariants from
/// <see cref="global::Architecture.Testing.ArchitectureTestsBase"/> plus any contracts specific to
/// this project's surface. Encode each project-specific invariant the first time it matters so drift
/// trips the build (writing-csharp: "the first slice sets the pattern").
/// </summary>
public sealed class ArchitectureTests : global::Architecture.Testing.ArchitectureTestsBase
{
#if (webapi)
    protected override Assembly TargetAssembly => typeof(Program).Assembly;
#else
    protected override Assembly TargetAssembly => typeof(Class1).Assembly;
#endif

    protected override string RootNamespace => "MyProject";

    // Add project-specific bans as extra [Fact]s. Example — forbid a dependency you never want to creep in.
    // Uncomment and add `using static ArchUnitNET.Fluent.ArchRuleDefinition;` to the usings above:
    //
    // [Fact]
    // public void DoesNotDependOnHttp() =>
    //     Verify(Types()
    //         .Should()
    //         .NotDependOnAnyTypesThat()
    //         .ResideInNamespaceMatching(@"^System\.Net\.Http.*")
    //         .Because("this project is transport-agnostic; an HTTP dependency would tie it to one protocol."));
}
