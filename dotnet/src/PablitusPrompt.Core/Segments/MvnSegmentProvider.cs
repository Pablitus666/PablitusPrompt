using System.Diagnostics;
using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Maven segment provider. Detects Maven version by running <c>mvn --version</c>
/// when a <c>pom.xml</c> file is present.
/// </summary>
public sealed class MvnSegmentProvider : CommandSegmentProvider
{
    public MvnSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "mvn",
            DisplayName = "Maven",
            DefaultTemplate = " {{ .Full }} ",
            DefaultTimeoutMs = 5000,
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

        var workingDirectory = context.Path.Current;
        if (!HasPomXml(workingDirectory))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "No Maven project detected.");
        }

        if (!IsCommandAvailable("mvn"))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Maven command not found.");
        }

        var timeoutMs = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand("mvn", new[] { "--version" }, timeoutMs, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Failed to get Maven version.");
        }

        var version = ParseVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Could not parse Maven version.");
        }

        var contextData = new
        {
            Full = version,
            Version = version,
        };

        var template = segment.Template ?? Definition.DefaultTemplate;
        var text = string.IsNullOrEmpty(template) ? string.Empty : _templates.Render(template, contextData);

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

    private static bool HasPomXml(string? workingDirectory)
    {
        if (string.IsNullOrEmpty(workingDirectory))
        {
            return false;
        }

        try
        {
            var directory = new DirectoryInfo(workingDirectory);
            while (directory is not null)
            {
                if (File.Exists(Path.Combine(directory.FullName, "pom.xml")))
                {
                    return true;
                }

                directory = directory.Parent;
            }
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            // Ignore and fall through.
        }

        return false;
    }

    private static string? ParseVersion(string output)
    {
        if (string.IsNullOrEmpty(output))
        {
            return null;
        }

        // Maven --version output contains lines like "Apache Maven 3.9.4"
        foreach (var line in output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
        {
            var trimmed = line.Trim();
            if (!trimmed.StartsWith("Apache Maven ", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var version = trimmed["Apache Maven ".Length..].Trim();
            if (version.Length > 0)
            {
                return version;
            }
        }

        return null;
    }
}
