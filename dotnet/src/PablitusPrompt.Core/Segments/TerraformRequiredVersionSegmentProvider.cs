using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Terraform required version segment provider. Reads <c>required_version</c>
/// from <c>.tf</c> files without running any external command.
/// </summary>
public sealed class TerraformRequiredVersionSegmentProvider : TemplateSegmentProvider
{
    private static readonly Regex RequiredVersionRegex = new(
        @"required_version\s*=\s*[""'](?<version>[^""']+)[""']",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);

    public TerraformRequiredVersionSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "terraform_required_version",
            DisplayName = "Terraform Required Version",
            DefaultTemplate = " {{ .Full }} ",
            DefaultTimeoutMs = 2000,
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
        if (!HasTerraformFiles(workingDirectory))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "No Terraform files detected.");
        }

        var requiredVersion = ReadRequiredVersion(workingDirectory);
        if (string.IsNullOrEmpty(requiredVersion))
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Skipped, "required_version not found.");
        }

        var contextData = new
        {
            Full = requiredVersion,
            Version = requiredVersion,
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

    private static bool HasTerraformFiles(string? workingDirectory)
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
                if (directory.EnumerateFiles("*.tf").Any() || directory.EnumerateFiles("*.tfvars").Any())
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

    private static string? ReadRequiredVersion(string? workingDirectory)
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
                foreach (var tfFile in directory.EnumerateFiles("*.tf"))
                {
                    try
                    {
                        var content = File.ReadAllText(tfFile.FullName);
                        var match = RequiredVersionRegex.Match(content);
                        if (match.Success)
                        {
                            var version = match.Groups["version"].Value.Trim();
                            if (version.Length > 0)
                            {
                                return version;
                            }
                        }
                    }
                    catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
                    {
                        // Skip this file and continue.
                    }
                }

                directory = directory.Parent;
            }
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            // Ignore and fall through.
        }

        return null;
    }
}
