using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for the Azure CLI (<c>az</c>). Verifies that the <c>az</c> command
/// is available and reads Azure-related environment variables. Inspired by the
/// Oh My Posh <c>az</c> segment.
/// </summary>
public sealed class AzSegmentProvider : CommandSegmentProvider
{
    private readonly TemplateEngine _templates;

    public AzSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "az",
            DisplayName = "Azure CLI",
            DefaultTemplate = "{{ .Subscription }}{{ if .Region }}@{{ .Region }}{{ end }}",
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

        if (!IsCommandAvailable("az"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Azure CLI (az) is not available in PATH."));
        }

        var subscription = GetEnvironmentVariable("AZURE_SUBSCRIPTION")
            ?? GetEnvironmentVariable("AZURE_DEFAULT_SUBSCRIPTION");
        var region = GetEnvironmentVariable("AZURE_REGION")
            ?? GetEnvironmentVariable("AZURE_DEFAULT_REGION");

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Subscription"] = subscription,
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
