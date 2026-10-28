using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Node.js. Runs <c>node --version</c> and exposes the
/// version as <c>{{ .Full }}</c>.
/// </summary>
public sealed class NodeSegmentProvider : CommandSegmentProvider
{
    public NodeSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "node",
            DisplayName = "Node.js",
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

        if (!IsCommandAvailable("node"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "node command not available"));
        }

        var output = RunCommand("node", new[] { "--version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "node --version produced no output"));
        }

        var version = output.TrimStart('v');
        var template = GetTemplate(segment);
        var text = _templates.Render(template, new { Full = version });

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
