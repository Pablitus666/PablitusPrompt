using System.Text;

namespace PablitusPrompt.Core.Templating;

/// <summary>
/// A parsed template that can be rendered repeatedly with different contexts.
/// </summary>
public sealed class CompiledTemplate
{
    private readonly TemplateRootNode _root;
    private readonly int _estimatedLength;

    internal CompiledTemplate(TemplateRootNode root, string source)
    {
        _root = root;
        _estimatedLength = source.Length;
    }

    public string Render(object? context)
    {
        var builder = new StringBuilder(_estimatedLength);
        _root.Render(builder, context);
        return builder.ToString();
    }
}
