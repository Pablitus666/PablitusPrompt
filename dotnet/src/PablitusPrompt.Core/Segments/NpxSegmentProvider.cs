using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for npx. Runs <c>npx --version</c> and exposes the version
/// as <c>{{ .Full }}</c>.
/// </summary>
public sealed class NpxSegmentProvider : CommandSegmentProvider
{
    public NpxSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "npx",
            DisplayName = "npx",
            DefaultTemplate = " {{ .Full }} ",
            DefaultTimeoutMs = 3000,
        })
    {
    }

    public override Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        if (!IsCommandAvailable("npx"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "npx command not available"));
        }

        var output = RunCommand("npx", new[] { "--version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "npx --version produced no output"));
        }

        var template = GetTemplate(segment);
        var text = _templates.Render(template, new { Full = output.Trim() });

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
            Visible = text.Length > 0,
            Status = SegmentStatus.Success,
        });
    }
}
