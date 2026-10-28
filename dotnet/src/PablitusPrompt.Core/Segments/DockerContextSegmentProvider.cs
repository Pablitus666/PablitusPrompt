using System.IO;
using System.Text.Json;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for Docker context. Reads the current Docker context from
/// <c>~/.docker/config.json</c>. Inspired by the Oh My Posh
/// <c>docker_context</c> segment.
/// </summary>
public sealed class DockerContextSegmentProvider : TemplateSegmentProvider
{
    private readonly TemplateEngine _templates;

    public DockerContextSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "docker_context",
            DisplayName = "Docker Context",
            DefaultTemplate = "{{ .Context }}",
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

        var configPath = GetDockerConfigPath();
        if (string.IsNullOrEmpty(configPath) || !File.Exists(configPath))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Docker config file not found."));
        }

        string? contextName = null;
        try
        {
            var json = File.ReadAllText(configPath);
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;

            if (root.TryGetProperty("currentContext", out var currentContext))
            {
                contextName = currentContext.GetString();
            }
            else if (root.TryGetProperty("contexts", out var contexts))
            {
                foreach (var ctx in contexts.EnumerateArray())
                {
                    if (ctx.TryGetProperty("Name", out var nameElement))
                    {
                        contextName = nameElement.GetString();
                        break;
                    }
                }
            }
        }
        catch
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Could not parse Docker config file."));
        }

        if (string.IsNullOrWhiteSpace(contextName))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "No Docker context found in config file."));
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

    private static string? GetDockerConfigPath()
    {
        var home = Environment.GetEnvironmentVariable("HOME")
            ?? Environment.GetEnvironmentVariable("USERPROFILE");
        if (string.IsNullOrEmpty(home))
        {
            return null;
        }

        return Path.Combine(home, ".docker", "config.json");
    }
}
