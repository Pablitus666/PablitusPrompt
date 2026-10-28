using System.Globalization;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for the PHP dependency manager Composer. Runs
/// <c>composer --version</c> and renders the detected version. Hidden when
/// Composer is not installed.
/// </summary>
public sealed class ComposerSegmentProvider : CommandSegmentProvider
{
    private static readonly Regex VersionRegex = new(
        @"\d+\.\d+(?:\.\d+)?",
        RegexOptions.None,
        TimeSpan.FromMilliseconds(500));

    public ComposerSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "composer",
            DisplayName = "Composer",
            DefaultTemplate = " {{ .Full }} ",
            DefaultTimeoutMs = 3000,
        })
    {
    }

    public override async Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        if (!IsCommandAvailable("composer"))
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "composer command is not available in PATH");
        }

        var timeout = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand("composer", new[] { "--version" }, timeout, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "composer --version did not produce output");
        }

        var version = ExtractVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "could not parse composer version");
        }

        var template = GetTemplate(segment);
        var text = string.IsNullOrEmpty(template)
            ? string.Empty
            : _templates.Render(template, new { Full = version });

        return new SegmentResult
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
        };
    }

    private static string? ExtractVersion(string output)
    {
        var match = VersionRegex.Match(output);
        return match.Success ? match.Value : null;
    }
}
