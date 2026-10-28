using System.Diagnostics;
using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Gradle segment provider. Detects Gradle version by running
/// <c>gradle --version</c> when Gradle build files are present.
/// </summary>
public sealed class GradleSegmentProvider : CommandSegmentProvider
{
    public GradleSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "gradle",
            DisplayName = "Gradle",
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
        if (!IsGradleProject(workingDirectory))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "No Gradle project detected.");
        }

        if (!IsCommandAvailable("gradle"))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Gradle command not found.");
        }

        var timeoutMs = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand("gradle", new[] { "--version" }, timeoutMs, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Failed to get Gradle version.");
        }

        var version = ParseVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Could not parse Gradle version.");
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

    private static bool IsGradleProject(string? workingDirectory)
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
                if (File.Exists(Path.Combine(directory.FullName, "build.gradle")) ||
                    File.Exists(Path.Combine(directory.FullName, "build.gradle.kts")) ||
                    File.Exists(Path.Combine(directory.FullName, "settings.gradle")) ||
                    File.Exists(Path.Combine(directory.FullName, "settings.gradle.kts")) ||
                    File.Exists(Path.Combine(directory.FullName, "gradlew")))
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

        // Gradle --version output contains lines like "Gradle 8.5"
        foreach (var line in output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
        {
            var trimmed = line.Trim();
            if (!trimmed.StartsWith("Gradle ", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var version = trimmed["Gradle ".Length..].Trim();
            if (version.Length > 0)
            {
                return version;
            }
        }

        return null;
    }
}
