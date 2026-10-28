using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for Google Cloud Platform (GCP). Reads the active project from
/// environment variables. Inspired by the Oh My Posh <c>gcp</c> segment.
/// </summary>
public sealed class GcpSegmentProvider : TemplateSegmentProvider
{
    private readonly TemplateEngine _templates;

    public GcpSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "gcp",
            DisplayName = "Google Cloud Platform",
            DefaultTemplate = "{{ .Project }}",
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

        var project = Environment.GetEnvironmentVariable("GOOGLE_CLOUD_PROJECT")
            ?? Environment.GetEnvironmentVariable("CLOUDSDK_CORE_PROJECT");

        if (string.IsNullOrWhiteSpace(project))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "No GCP project found in environment variables."));
        }

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Project"] = project,
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
