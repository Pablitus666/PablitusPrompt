using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

public abstract class TemplateSegmentProvider : ISegmentProvider
{
    private readonly TemplateEngine _templates;

    protected TemplateSegmentProvider(TemplateEngine templates, SegmentDefinition definition)
    {
        _templates = templates ?? throw new ArgumentNullException(nameof(templates));
        Definition = definition ?? throw new ArgumentNullException(nameof(definition));
    }

    public SegmentDefinition Definition { get; }

    public virtual Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        var template = GetTemplate(segment);
        var text = string.IsNullOrEmpty(template) ? string.Empty : _templates.Render(template, context);

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

    protected virtual string? GetTemplate(PromptSegment segment) =>
        segment.Template ?? Definition.DefaultTemplate;
}

public sealed class SessionSegmentProvider : TemplateSegmentProvider
{
    public SessionSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "session",
            DisplayName = "Session",
            DefaultTemplate = "{{ .UserName }}@{{ .HostName }}",
        })
    {
    }
}

public sealed class PathSegmentProvider : TemplateSegmentProvider
{
    public PathSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "path",
            DisplayName = "Path",
            DefaultTemplate = "{{ .Path.Current }}",
        })
    {
    }
}

public sealed class GitSegmentProvider : TemplateSegmentProvider
{
    public GitSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "git",
            DisplayName = "Git",
            DefaultTemplate = "{{ .Git.Branch }}",
        })
    {
    }
}

public sealed class TextSegmentProvider : TemplateSegmentProvider
{
    public TextSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "text",
            DisplayName = "Text",
            DefaultTemplate = null,
        })
    {
    }
}

public sealed class TimeSegmentProvider : TemplateSegmentProvider
{
    public TimeSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "time",
            DisplayName = "Time",
            DefaultTemplate = "{{ .Time }}",
        })
    {
    }
}

public sealed class ExitSegmentProvider : TemplateSegmentProvider
{
    public ExitSegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "exit",
            DisplayName = "Exit",
            DefaultTemplate = "{{ if ne .ExitCode 0 }}{{ .ExitCode }}{{ end }}",
        })
    {
    }
}

/// <summary>Registry of segment providers keyed by the configuration type name.</summary>
public sealed class SegmentProviderRegistry
{
    private readonly Dictionary<string, ISegmentProvider> _providers =
        new(StringComparer.OrdinalIgnoreCase);

    public SegmentProviderRegistry Register(ISegmentProvider provider)
    {
        ArgumentNullException.ThrowIfNull(provider);
        ArgumentException.ThrowIfNullOrWhiteSpace(provider.Definition.Type);
        _providers[provider.Definition.Type] = provider;
        return this;
    }

    public bool TryGet(string type, out ISegmentProvider provider) =>
        _providers.TryGetValue(type, out provider!);

    public IReadOnlyList<string> Types => _providers.Keys.OrderBy(key => key, StringComparer.OrdinalIgnoreCase).ToArray();

    public static SegmentProviderRegistry CreateDefault(TemplateEngine? templates = null)
    {
        templates ??= new TemplateEngine();

        return new SegmentProviderRegistry()
            .Register(new SessionSegmentProvider(templates))
            .Register(new PathSegmentProvider(templates))
            .Register(new GitSegmentProvider(templates))
            .Register(new TextSegmentProvider(templates))
            .Register(new TimeSegmentProvider(templates))
            .Register(new ExitSegmentProvider(templates));
    }
}
