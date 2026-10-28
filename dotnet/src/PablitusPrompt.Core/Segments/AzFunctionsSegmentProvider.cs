using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for Azure Functions. Checks whether the current directory (or a
/// parent directory) contains an Azure Functions project, typically indicated
/// by a <c>local.settings.json</c> or <c>host.json</c> file.
/// </summary>
public sealed class AzFunctionsSegmentProvider : TemplateSegmentProvider
{
    private readonly TemplateEngine _templates;

    public AzFunctionsSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "az_functions",
            DisplayName = "Azure Functions",
            DefaultTemplate = "{{ .Name }}",
            DefaultTimeoutMs = 2000,
        })
    {
        _templates = templates;
    }

    public override Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        var currentPath = context.Path.Current;
        if (string.IsNullOrEmpty(currentPath))
        {
            currentPath = Directory.GetCurrentDirectory();
        }

        var directory = new DirectoryInfo(currentPath);
        var found = false;
        var name = directory.Name;

        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "host.json"))
                || File.Exists(Path.Combine(directory.FullName, "local.settings.json")))
            {
                found = true;
                break;
            }

            var parent = directory.Parent;
            if (parent is null || parent.FullName == directory.FullName)
            {
                break;
            }

            directory = parent;
        }

        if (!found)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "No Azure Functions project found in the current directory."));
        }

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Name"] = name,
        };

        var template = GetTemplate(segment);
        var text = string.IsNullOrEmpty(template)
            ? string.Empty
            : _templates.Render(template, contextData);

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
            Visible = !string.IsNullOrWhiteSpace(text),
            Status = SegmentStatus.Success,
        });
    }
}
