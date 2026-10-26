using PablitusPrompt.Core.Configuration;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Normalized segment instance consumed by providers and the scheduler. It is
/// derived from <see cref="SegmentConfig"/> but has no JSON dependency.
/// </summary>
public sealed class PromptSegment
{
    public string Name { get; init; } = string.Empty;

    public string Type { get; init; } = string.Empty;

    public string Style { get; init; } = "plain";

    public string? Foreground { get; init; }

    public string? Background { get; init; }

    public string? Icon { get; init; }

    public string? Template { get; init; }

    public string? LeadingDiamond { get; init; }

    public string? TrailingDiamond { get; init; }

    public bool Enabled { get; init; } = true;

    public int? TimeoutMs { get; init; }

    public int? CacheTtlSeconds { get; init; }

    public IReadOnlyDictionary<string, object?> Properties { get; init; } =
        new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);

    public static PromptSegment FromConfig(SegmentConfig config, int blockIndex, int segmentIndex)
    {
        ArgumentNullException.ThrowIfNull(config);

        var type = config.Type?.Trim() ?? string.Empty;
        var name = string.IsNullOrWhiteSpace(config.Name)
            ? $"{type}:{blockIndex}.{segmentIndex}"
            : config.Name!;

        return new PromptSegment
        {
            Name = name,
            Type = type,
            Style = string.IsNullOrWhiteSpace(config.Style) ? "plain" : config.Style,
            Foreground = config.Foreground,
            Background = config.Background,
            Icon = config.Icon,
            Template = config.Template,
            LeadingDiamond = config.LeadingDiamond,
            TrailingDiamond = config.TrailingDiamond,
            Enabled = config.Enabled,
            TimeoutMs = config.TimeoutMs,
            CacheTtlSeconds = config.CacheTtlSeconds,
            Properties = new Dictionary<string, object?>(
                config.Properties ?? new Dictionary<string, object?>(),
                StringComparer.OrdinalIgnoreCase),
        };
    }
}
