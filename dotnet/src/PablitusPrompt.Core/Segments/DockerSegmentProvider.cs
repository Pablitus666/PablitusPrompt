using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for Docker. Runs <c>docker context show</c> to determine the active
/// Docker context. Verifies that the <c>docker</c> command is available.
/// Inspired by the Oh My Posh <c>docker</c> segment.
/// </summary>
public sealed class DockerSegmentProvider : CommandSegmentProvider
{
    private readonly TemplateEngine _templates;

    public DockerSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "docker",
            DisplayName = "Docker",
            DefaultTemplate = "{{ .Context }}",
            DefaultTimeoutMs = 3000,
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

        if (!IsCommandAvailable("docker"))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Docker is not available in PATH."));
        }

        var contextName = RunCommand("docker", new[] { "context", "show" }, 3000, cancellationToken);

        if (string.IsNullOrWhiteSpace(contextName))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Could not determine the active Docker context."));
        }

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Context"] = contextName,
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
