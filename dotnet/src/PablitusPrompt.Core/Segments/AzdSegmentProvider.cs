using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for the Azure Developer CLI (<c>azd</c>). Verifies that the
/// <c>azd</c> command is available. Inspired by the Oh My Posh <c>azd</c> segment.
/// </summary>
public sealed class AzdSegmentProvider : CommandSegmentProvider
{
    private readonly TemplateEngine _templates;

    public AzdSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "azd",
            DisplayName = "Azure Developer CLI",
            DefaultTemplate = "{{ .Environment }}",
            DefaultTimeoutMs = 3000,
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

        if (!IsCommandAvailable("azd"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Azure Developer CLI (azd) is not available in PATH."));
        }

        var environment = GetEnvironmentVariable("AZD_ENVIRONMENT")
            ?? GetEnvironmentVariable("AZURE_ENVIRONMENT");

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Environment"] = environment,
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
