using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Git version. Runs <c>git describe --tags</c> to obtain
/// the latest tag-based version and exposes it as <c>{{ .Full }}</c>.
/// </summary>
public sealed class GitVersionSegmentProvider : CommandSegmentProvider
{
    public GitVersionSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "gitversion",
            DisplayName = "Git Version",
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

        if (!IsCommandAvailable("git"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "git command not available"));
        }

        var output = RunCommand("git", new[] { "describe", "--tags" },
            Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "git describe --tags produced no output"));
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
