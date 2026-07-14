namespace MyProject;

/// <summary>Web application entry point.</summary>
internal static class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        var app = builder.Build();

        _ = app.MapGet("/", () => "Hello from MyProject.");

        app.Run();
    }
}
