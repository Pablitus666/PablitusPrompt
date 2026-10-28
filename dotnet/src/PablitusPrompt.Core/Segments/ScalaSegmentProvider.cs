using System.Globalization;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for the Scala language. Runs <c>scala --version</c> (or
/// <c>scalac --version</c> as a fallback) and renders the detected version.
/// Hidden when neither command is available.
/// </summary>
public sealed class ScalaSegmentProvider : CommandSegmentProvider
{
    private static readonly Regex VersionRegex = new(
        @"\d+\.\d+(?:\.\d+)?",
        RegexOptions.None,
        TimeSpan.FromMilliseconds(500));

    private static readonly string[] ScalaCommands = { "scala", "scalac" };

    public ScalaSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "scala",
            DisplayName = "Scala",
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

        var timeout = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;

        foreach (var command in ScalaCommands)
        {
            if (!IsCommandAvailable(command))
            {
                continue;
            }

            var output = RunCommand(command, new[] { "--version" }, timeout, cancellationToken);
            if (output is null)
            {
                continue;
            }

            var version = ExtractVersion(output);
            if (string.IsNullOrEmpty(version))
            {
                continue;
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

        return SegmentResult.ErrorResult(
            segment,
            SegmentStatus.Skipped,
            "scala/scalac command is not available in PATH");
    }

    private static string? ExtractVersion(string output)
    {
        var match = VersionRegex.Match(output);
        return match.Success ? match.Value : null;
    }
}
