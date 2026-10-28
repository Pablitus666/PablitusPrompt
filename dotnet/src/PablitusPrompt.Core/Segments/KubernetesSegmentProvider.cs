using System.Globalization;
using System.IO;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment provider for Kubernetes. Reads <c>~/.kube/config</c> to obtain the
/// current context and namespace, exposing them as <c>{{ .Context }}</c> and
/// <c>{{ .Namespace }}</c>.
/// </summary>
public sealed class KubernetesSegmentProvider : TemplateSegmentProvider
{
    private const string DefaultConfigFileName = ".kube/config";

    public KubernetesSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "kubernetes",
            DisplayName = "Kubernetes",
            DefaultTemplate = "{{ .Context }}{{ if .Namespace }} :: {{ .Namespace }}{{ end }} ",
            DefaultTimeoutMs = 2000,
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

        var configPath = GetKubeConfigPath();
        if (configPath is null || !File.Exists(configPath))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "kubeconfig not found"));
        }

        var currentContext = ReadCurrentContext(configPath);
        if (string.IsNullOrEmpty(currentContext))
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "no current context in kubeconfig"));
        }

        var ns = ReadNamespaceForContext(configPath, currentContext);

        var template = GetTemplate(segment);
        var text = _templates.Render(template, new
        {
            Context = currentContext,
            Namespace = ns,
        });

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

    private static string? GetKubeConfigPath()
    {
        try
        {
            var env = Environment.GetEnvironmentVariable("KUBECONFIG");
            if (!string.IsNullOrEmpty(env))
            {
                return env;
            }

            var home = Environment.GetEnvironmentVariable("HOME");
            if (string.IsNullOrEmpty(home))
            {
                home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            }

            if (string.IsNullOrEmpty(home))
            {
                return null;
            }

            return Path.Combine(home, DefaultConfigFileName);
        }
        catch
        {
            return null;
        }
    }

    private static string? ReadCurrentContext(string configPath)
    {
        try
        {
            string? currentContext = null;
            foreach (var line in File.ReadLines(configPath))
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("current-context:", StringComparison.OrdinalIgnoreCase))
                {
                    var value = trimmed.Substring("current-context:".Length).Trim();
                    currentContext = Unquote(value);
                    break;
                }
            }

            return currentContext;
        }
        catch
        {
            return null;
        }
    }

    private static string? ReadNamespaceForContext(string configPath, string contextName)
    {
        try
        {
            bool inContexts = false;
            bool inTargetContext = false;
            string? currentNamespace = null;

            foreach (var line in File.ReadLines(configPath))
            {
                var trimmed = line.Trim();

                if (trimmed.StartsWith("contexts:", StringComparison.OrdinalIgnoreCase))
                {
                    inContexts = true;
                    continue;
                }

                if (inContexts && trimmed.StartsWith("- name:", StringComparison.OrdinalIgnoreCase))
                {
                    var name = trimmed.Substring("- name:".Length).Trim();
                    inTargetContext = string.Equals(name, contextName, StringComparison.Ordinal);
                    currentNamespace = null;
                    continue;
                }

                if (inTargetContext)
                {
                    if (trimmed.StartsWith("namespace:", StringComparison.OrdinalIgnoreCase))
                    {
                        currentNamespace = Unquote(trimmed.Substring("namespace:".Length).Trim());
                    }
                    else if (trimmed.StartsWith("- name:", StringComparison.OrdinalIgnoreCase) ||
                             trimmed.StartsWith("current-context:", StringComparison.OrdinalIgnoreCase) ||
                             trimmed.StartsWith("clusters:", StringComparison.OrdinalIgnoreCase) ||
                             trimmed.StartsWith("users:", StringComparison.OrdinalIgnoreCase))
                    {
                        break;
                    }
                }
            }

            return currentNamespace;
        }
        catch
        {
            return null;
        }
    }

    private static string Unquote(string value)
    {
        if (value.Length >= 2)
        {
            if ((value.StartsWith('"') && value.EndsWith('"')) ||
                (value.StartsWith('\'') && value.EndsWith('\'')))
            {
                return value[1..^1];
            }
        }

        return value;
    }
}
