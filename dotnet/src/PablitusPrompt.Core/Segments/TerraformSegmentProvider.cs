using System.Diagnostics;
using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Terraform segment provider. Detects Terraform version by running
/// <c>terraform version</c> when Terraform files are present.
/// </summary>
public sealed class TerraformSegmentProvider : CommandSegmentProvider
{
    public TerraformSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "terraform",
            DisplayName = "Terraform",
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

        var workingDirectory = context.Path.Current;
        if (!IsTerraformProject(workingDirectory))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "No Terraform project detected.");
        }

        if (!IsCommandAvailable("terraform"))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Terraform command not found.");
        }

        var timeoutMs = segment.TimeoutMs ?? Definition.DefaultTimeoutMs;
        var output = RunCommand("terraform", new[] { "version" }, timeoutMs, cancellationToken);
        if (output is null)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Failed to get Terraform version.");
        }

        var version = ParseVersion(output);
        if (string.IsNullOrEmpty(version))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "Could not parse Terraform version.");
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

    private static bool IsTerraformProject(string? workingDirectory)
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
                foreach (var pattern in new[] { "*.tf", "*.tfvars" })
                {
                    if (directory.EnumerateFiles(pattern).Any())
                    {
                        return true;
                    }
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

        // Output example: "Terraform v1.5.0" or "Terraform v1.5.0\n..."
        foreach (var line in output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
        {
            var trimmed = line.Trim();
            if (!trimmed.StartsWith("Terraform ", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var version = trimmed["Terraform ".Length..].Trim();
            if (version.StartsWith("v", StringComparison.OrdinalIgnoreCase))
            {
                version = version[1..];
            }

            if (version.Length > 0)
            {
                return version;
            }
        }

        return null;
    }
}
