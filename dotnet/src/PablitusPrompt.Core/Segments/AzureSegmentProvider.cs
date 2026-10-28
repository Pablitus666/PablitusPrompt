using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for Azure (generic). Checks Azure CLI availability and environment
/// variables. Similar to <see cref="AzSegmentProvider"/> but registered under
/// the <c>azure</c> type name for broader compatibility.
/// </summary>
public sealed class AzureSegmentProvider : CommandSegmentProvider
{
    private readonly TemplateEngine _templates;

    public AzureSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "azure",
            DisplayName = "Azure",
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
