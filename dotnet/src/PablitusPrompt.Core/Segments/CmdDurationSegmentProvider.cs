using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for command duration. Displays how long the previous command took to
/// execute. Reads the start timestamp from <see cref="PromptContext.Properties"/>
/// (key <c>CommandStartTime</c>) and compares it against
/// <see cref="PromptContext.Timestamp"/>. If no start time is recorded, the
/// segment returns an empty (invisible) result.
/// </summary>
public sealed class CmdDurationSegmentProvider : TemplateSegmentProvider
{
    private const string CommandStartTimeKey = "CommandStartTime";

    private readonly TemplateEngine _templates;

    public CmdDurationSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "cmd_duration",
            DisplayName = "Command Duration",
            DefaultTemplate = "{{ .Duration }}",
            DefaultTimeoutMs = 2000,
        })
    {
        _templates = templates;
    }

    public override Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        var duration = TimeSpan.Zero;
        var hasStartTime = false;

        if (context.Properties is not null
            && context.Properties.TryGetValue(CommandStartTimeKey, out var startTimeValue)
            && startTimeValue is DateTimeOffset startTime)
        {
            hasStartTime = true;
            duration = context.Timestamp - startTime;
            if (duration < TimeSpan.Zero)
            {
                duration = TimeSpan.Zero;
            }
        }

        if (!hasStartTime)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "No command start time recorded in context properties."));
        }

        var durationText = duration.TotalSeconds < 1
            ? $"{(int)duration.TotalMilliseconds}ms"
            : duration.TotalSeconds < 60
                ? $"{duration.TotalSeconds.ToString("0.##", CultureInfo.InvariantCulture)}s"
                : $"{duration.Minutes}m {duration.Seconds}s";

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Duration"] = durationText,
            ["ExitCode"] = context.ExitCode,
        };

        var template = GetTemplate(segment);
        var text = string.IsNullOrEmpty(template)
            ? string.Empty
            : _templates.Render(template, contextData);

        return Task.FromResult(new SegmentResult
        {
            Name = segment.Name,
            Type = segment.Type,
            Text = text,
            Icon = segment.Icon,
            Foreground = segment.Foreground,
            Background = segment.Background,
            Style = segment.Style,
            LeadingDiamond = segment.LeadingDiamond,
            TrailingDiamond = segment.TrailingDiamond,
            Visible = !string.IsNullOrWhiteSpace(text),
            Status = SegmentStatus.Success,
        });
    }
}
