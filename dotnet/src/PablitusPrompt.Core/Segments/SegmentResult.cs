namespace PablitusPrompt.Core.Segments;

public enum SegmentStatus
{
    Success,
    Failed,
    TimedOut,
    Cancelled,
    Skipped,
}

/// <summary>
/// Result of running one segment. Partial results are intentional: a failure or
/// timeout never prevents the remaining segments from rendering.
/// </summary>
public sealed class SegmentResult
{
    public string Name { get; init; } = string.Empty;

    public string Type { get; init; } = string.Empty;

    public string Text { get; set; } = string.Empty;

    public string? Icon { get; set; }

    public string? Foreground { get; set; }

    public string? Background { get; set; }

    public string Style { get; set; } = "plain";

    public string? LeadingDiamond { get; set; }

    public string? TrailingDiamond { get; set; }

    public bool Visible { get; set; } = true;

    public SegmentStatus Status { get; set; } = SegmentStatus.Success;

    public TimeSpan Duration { get; set; }

    public string? Error { get; set; }

    public bool IsVisible => Visible && !string.IsNullOrEmpty(Text);

    public static SegmentResult ErrorResult(PromptSegment segment, SegmentStatus status, string error) =>
        new()
        {
            Name = segment.Name,
            Type = segment.Type,
            Style = segment.Style,
            Foreground = segment.Foreground,
            Background = segment.Background,
            Icon = segment.Icon,
            LeadingDiamond = segment.LeadingDiamond,
            TrailingDiamond = segment.TrailingDiamond,
            Visible = false,
            Status = status,
            Error = error,
        };
}
