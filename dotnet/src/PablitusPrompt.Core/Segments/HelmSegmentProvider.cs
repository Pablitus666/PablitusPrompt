using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Helm. Runs <c>helm version</c> and exposes the version
/// as <c>{{ .Full }}</c>.
/// </summary>
public sealed class HelmSegmentProvider : CommandSegmentProvider
{
    public HelmSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "helm",
            DisplayName = "Helm",
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

        if (!IsCommandAvailable("helm"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "helm command not available"));
        }

        var output = RunCommand("helm", new[] { "version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "helm version produced no output"));
        }

        var version = ExtractVersion(output);
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

    private static string ExtractVersion(string output)
    {
        // helm version output may contain "Version: v2.x.x" or "v3.x.x" etc.
        foreach (var line in output.Split('\n', StringSplitOptions.RemoveEmptyEntries))
        {
            var trimmed = line.Trim();
            foreach (var token in trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries))
            {
                var candidate = token;
                if (candidate.StartsWith("v", StringComparison.OrdinalIgnoreCase) && candidate.Length > 1)
                {
                    candidate = candidate[1..];
                }

                if (candidate.Length > 0 && char.IsDigit(candidate[0]))
                {
                    return candidate;
                }
            }
        }

        return output.Trim();
    }
}
