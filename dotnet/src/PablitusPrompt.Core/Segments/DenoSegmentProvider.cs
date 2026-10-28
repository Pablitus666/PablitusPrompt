using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Deno. Runs <c>deno --version</c> and exposes the Deno
/// version as <c>{{ .Full }}</c>.
/// </summary>
public sealed class DenoSegmentProvider : CommandSegmentProvider
{
    public DenoSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "deno",
            DisplayName = "Deno",
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

        if (!IsCommandAvailable("deno"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "deno command not available"));
        }

        var output = RunCommand("deno", new[] { "--version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "deno --version produced no output"));
        }

        // deno --version prints multiple lines; take the first line (deno version).
        var firstLine = output.Split('\n', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
        var version = firstLine?.Split(' ', StringSplitOptions.RemoveEmptyEntries).LastOrDefault() ?? output.Trim();

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
