using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for AWS (Amazon Web Services). Reads the active profile and region
/// from environment variables. Inspired by the Oh My Posh <c>aws</c> segment.
/// </summary>
public sealed class AwsSegmentProvider : TemplateSegmentProvider
{
    private readonly TemplateEngine _templates;

    public AwsSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "aws",
            DisplayName = "AWS",
            DefaultTemplate = "{{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }}",
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

        var profile = Environment.GetEnvironmentVariable("AWS_PROFILE")
            ?? Environment.GetEnvironmentVariable("AWS_DEFAULT_PROFILE")
            ?? Environment.GetEnvironmentVariable("AWS_VAULT");

        if (string.IsNullOrWhiteSpace(profile))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "No AWS profile found in environment variables."));
        }

        var region = Environment.GetEnvironmentVariable("AWS_REGION")
            ?? Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION");

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Profile"] = profile,
            ["Region"] = region,
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
