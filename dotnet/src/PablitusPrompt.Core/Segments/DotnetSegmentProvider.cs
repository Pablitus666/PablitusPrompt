using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for .NET. Runs <c>dotnet --version</c> and detects .NET
/// projects (.csproj, .sln) in the current directory. Exposes the version as
/// <c>{{ .Full }}</c>.
/// </summary>
public sealed class DotnetSegmentProvider : CommandSegmentProvider
{
    public DotnetSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "dotnet",
            DisplayName = ".NET",
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

        // Only show when there is a .NET project in the current directory.
        var currentPath = context.Path.Current;
        if (!HasDotnetProject(currentPath))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "no .NET project found in current directory"));
        }

        if (!IsCommandAvailable("dotnet"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "dotnet command not available"));
        }

        var output = RunCommand("dotnet", new[] { "--version" }, Definition.DefaultTimeoutMs, cancellationToken);
        if (output is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "dotnet --version produced no output"));
        }

        var template = GetTemplate(segment);
        var text = _templates.Render(template, new { Full = output.Trim() });

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

    private static bool HasDotnetProject(string? path)
    {
        if (string.IsNullOrEmpty(path))
        {
            return false;
        }

        try
        {
            foreach (var file in Directory.EnumerateFiles(path))
            {
                var extension = Path.GetExtension(file);
                if (string.Equals(extension, ".csproj", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(extension, ".sln", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(extension, ".global.json", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
        }
        catch
        {
            // Ignore directory access errors.
        }

        return false;
    }
}
