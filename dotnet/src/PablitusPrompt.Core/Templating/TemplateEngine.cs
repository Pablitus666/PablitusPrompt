using System.Collections.Concurrent;

namespace PablitusPrompt.Core.Templating;

/// <summary>
/// Public entry point for the template subsystem. Compiled templates are cached
/// by source text, which keeps the prompt hot path free of repeated parsing.
/// </summary>
public sealed class TemplateEngine
{
    private readonly ConcurrentDictionary<string, CompiledTemplate> _cache =
        new(StringComparer.Ordinal);

    public CompiledTemplate Compile(string template)
    {
        ArgumentNullException.ThrowIfNull(template);
        return _cache.GetOrAdd(template, static source =>
            new CompiledTemplate(TemplateParser.Parse(source), source));
    }

    public string Render(string template, object? context) =>
        Compile(template).Render(context);

    public bool TryRender(string template, object? context, out string result, out TemplateParseException? error)
    {
        try
        {
            result = Render(template, context);
            error = null;
            return true;
        }
        catch (TemplateParseException exception)
        {
            result = string.Empty;
            error = exception;
            return false;
        }
    }
}
