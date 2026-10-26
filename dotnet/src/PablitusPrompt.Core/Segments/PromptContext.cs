using System.Globalization;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Data available to every segment template. Property names and nesting mirror
/// the subset used by Oh My Posh (<c>{{ .UserName }}</c>, <c>{{ .Path.Current }}</c>).
/// </summary>
public sealed class PromptContext
{
    public string UserName { get; init; } = string.Empty;

    public string HostName { get; init; } = string.Empty;

    public PathContext Path { get; init; } = new();

    public SessionContext Session { get; init; } = new();

    public GitContext Git { get; init; } = new();

    public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.Now;

    public string Time => Timestamp.ToString("HH:mm:ss", CultureInfo.InvariantCulture);

    public string Date => Timestamp.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    public int ExitCode { get; init; }

    public string Shell { get; init; } = "pwsh";

    /// <summary>Current PSReadLine buffer, when the caller can provide it.</summary>
    public string CommandLine { get; init; } = string.Empty;

    public int TerminalWidth { get; init; }

    /// <summary>Zero-based cursor column used to right-align tooltips.</summary>
    public int Column { get; init; }

    /// <summary>True when the transient prompt replaces an interrupted command.</summary>
    public bool Interrupted { get; init; }

    public IReadOnlyDictionary<string, object?> Properties { get; init; } =
        new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
}

public sealed class PathContext
{
    public string Current { get; init; } = string.Empty;

    public string Display { get; init; } = string.Empty;

    public string Folder { get; init; } = string.Empty;

    public string Separator { get; init; } = System.IO.Path.DirectorySeparatorChar.ToString();

    public bool IsHome { get; init; }

    public override string ToString() => Current;
}

public sealed class SessionContext
{
    public string UserName { get; init; } = string.Empty;

    public string HostName { get; init; } = string.Empty;

    public string Shell { get; init; } = "pwsh";
}

public sealed class GitContext
{
    public string? Branch { get; init; }

    public bool IsDirty { get; init; }

    public int Ahead { get; init; }

    public int Behind { get; init; }

    public bool IsRepository => !string.IsNullOrEmpty(Branch);

    public override string ToString() => Branch ?? string.Empty;
}
