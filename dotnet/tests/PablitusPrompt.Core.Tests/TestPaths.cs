namespace PablitusPrompt.Core.Tests;

internal static class TestPaths
{
    public static string RepoRoot { get; } = FindRepoRoot();

    public static string OmpTheme => Path.Combine(RepoRoot, "src", "Themes", "Pablitus.omp.json");

    public static string ExamplesDirectory => Path.Combine(RepoRoot, "examples", "dotnet");

    public static string NordTheme => Path.Combine(ExamplesDirectory, "theme.nord.ppf.json");

    public static string ExampleConfig => Path.Combine(ExamplesDirectory, "config.ppf.json");

    public static string ExampleOmpTheme => Path.Combine(ExamplesDirectory, "theme.omp.json");

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "src", "Themes", "Pablitus.omp.json")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        throw new InvalidOperationException("Could not locate the Pablitus Prompt repository root from the test output directory.");
    }
}
