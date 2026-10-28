using System.Diagnostics;
using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Python segment provider. Detects Python version by running <c>python --version</c>
/// (or <c>python3 --version</c>) when Python files or a virtual environment are present.
/// </summary>
public sealed class PythonSegmentProvider : CommandSegmentProvider
{
    private static readonly string[] PythonCommands = { "python3", "python" };

    public PythonSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "python",
            DisplayName = "Python",
            DefaultTemplate = " {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} ",
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

        var workingDirectory = context.Path.Current;
        if (!IsPythonProject(workingDirectory))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "No Python project detected.");
        }

        var command = FindPythonCommand();
        if (command is null)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Python command not found.");
        }

        var timeoutMs = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand(command, new[] { "--version" }, timeoutMs, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Failed to get Python version.");
        }

        var version = ParseVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Could not parse Python version.");
        }

        var venv = DetectVenv(workingDirectory);
        var contextData = new
        {
            Full = version,
            Version = version,
            Venv = venv,
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

    private static bool IsPythonProject(string? workingDirectory)
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
                if (directory.EnumerateFiles("*.py").Any())
                {
                    return true;
                }

                if (File.Exists(Path.Combine(directory.FullName, "pyproject.toml")))
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

    private static string? FindPythonCommand()
    {
        foreach (var command in PythonCommands)
        {
            if (IsCommandAvailable(command))
            {
                return command;
            }
        }

        return null;
    }

    private static string? ParseVersion(string output)
    {
        if (string.IsNullOrEmpty(output))
        {
            return null;
        }

        // Output examples: "Python 3.11.4", "Python 3.12.0rc1"
        foreach (var line in output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
        {
            var trimmed = line.Trim();
            var pythonMarker = "Python ";
            var index = trimmed.IndexOf(pythonMarker, StringComparison.OrdinalIgnoreCase);
            if (index < 0)
            {
                continue;
            }

            var start = index + pythonMarker.Length;
            var version = trimmed[start..].Trim();
            if (version.Length > 0)
            {
                return version;
            }
        }

        return null;
    }

    private static string? DetectVenv(string? workingDirectory)
    {
        if (string.IsNullOrEmpty(workingDirectory))
        {
            return null;
        }

        try
        {
            var directory = new DirectoryInfo(workingDirectory);
            while (directory is not null)
            {
                var venvPath = Path.Combine(directory.FullName, ".venv");
                if (Directory.Exists(venvPath))
                {
                    return ".venv";
                }

                directory = directory.Parent;
            }
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            // Ignore.
        }

        return null;
    }
}
