using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Golang. Alias of <see cref="GoSegmentProvider"/>.
/// Runs <c>go version</c> and exposes the version as <c>{{ .Full }}</c>.
/// </summary>
public sealed class GolangSegmentProvider : CommandSegmentProvider
{
    public GolangSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "golang",
            DisplayName = "Golang",
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

        if (!IsCommandAvailable("go"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "go command not available"));
        }

        var output = RunCommand("go", new[] { "version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "go version produced no output"));
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
        foreach (var token in output.Split(' ', StringSplitOptions.RemoveEmptyEntries))
        {
            if (token.StartsWith("go", StringComparison.OrdinalIgnoreCase) && token.Length > 2)
            {
                var candidate = token[2..];
                if (candidate.Length > 0 && char.IsDigit(candidate[0]))
                {
                    return candidate;
                }
            }
        }

        return output.Trim();
    }
}
