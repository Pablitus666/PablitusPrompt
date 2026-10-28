using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for kubectl. Runs <c>kubectl config current-context</c> to
/// obtain the current cluster context, exposing it as <c>{{ .Context }}</c>.
/// </summary>
public sealed class KubectlSegmentProvider : CommandSegmentProvider
{
    public KubectlSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "kubectl",
            DisplayName = "kubectl",
            DefaultTemplate = " {{ .Context }} ",
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

        if (!IsCommandAvailable("kubectl"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "kubectl command not available"));
        }

        var output = RunCommand("kubectl", new[] { "config", "current-context" },
            Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "kubectl config current-context produced no output"));
        }

        var template = GetTemplate(segment);
        var text = _templates.Render(template, new { Context = output.Trim() });

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
