namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Provider registration metadata: the type name used by configuration and the
/// defaults applied when a segment does not override them.
/// </summary>
public sealed class SegmentDefinition
{
    public required string Type { get; init; }

    public string DisplayName { get; init; } = string.Empty;

    public string? DefaultTemplate { get; init; }

    public int DefaultTimeoutMs { get; init; } = 2000;
}
