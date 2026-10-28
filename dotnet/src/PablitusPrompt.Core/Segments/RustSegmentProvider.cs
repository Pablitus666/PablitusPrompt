using System.Globalization;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for the Rust language. Runs <c>rustc --version</c> and
/// renders the detected compiler version. Hidden when Rust is not installed.
/// </summary>
public sealed class RustSegmentProvider : CommandSegmentProvider
{
    private static readonly Regex VersionRegex = new(
        @"\d+\.\d+(?:\.\d+)?",
        RegexOptions.None,
        TimeSpan.FromMilliseconds(500));

    public RustSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "rust",
            DisplayName = "Rust",
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

        if (!IsCommandAvailable("rustc"))
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "rustc command is not available in PATH");
        }

        var timeout = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand("rustc", new[] { "--version" }, timeout, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "rustc --version did not produce output");
        }

        var version = ExtractVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Skipped,
                "could not parse rustc version");
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
