namespace PablitusPrompt.Core.Configuration;

/// <summary>A single validation problem tied to a JSON field path.</summary>
public sealed record ConfigValidationError(string Path, string Message)
{
    public override string ToString() => $"{Path}: {Message}";
}

/// <summary>Raised when a PPF document cannot be parsed or does not satisfy the schema-level rules.</summary>
public sealed class PpfConfigurationException : Exception
{
    public PpfConfigurationException(string message, IReadOnlyList<ConfigValidationError>? errors = null, string? source = null)
        : base(message)
    {
        Errors = errors ?? Array.Empty<ConfigValidationError>();
        SourceName = source;
    }

    public IReadOnlyList<ConfigValidationError> Errors { get; }

    public string? SourceName { get; }

    public static PpfConfigurationException FromErrors(string? source, IReadOnlyList<ConfigValidationError> errors)
    {
        var label = string.IsNullOrWhiteSpace(source) ? "configuration" : $"'{source}'";
        var message = $"Invalid PPF {label}:{Environment.NewLine}" +
                      string.Join(Environment.NewLine, errors.Select(error => $"  - {error}"));
        return new PpfConfigurationException(message, errors, source);
    }
}
