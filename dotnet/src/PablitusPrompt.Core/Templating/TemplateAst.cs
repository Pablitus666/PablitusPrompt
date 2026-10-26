using System.Text;

namespace PablitusPrompt.Core.Templating;

internal abstract class TemplateNode
{
    public abstract void Render(StringBuilder builder, object? context);
}

internal sealed class TemplateRootNode
{
    public TemplateRootNode(IReadOnlyList<TemplateNode> children)
    {
        Children = children;
    }

    public IReadOnlyList<TemplateNode> Children { get; }

    public void Render(StringBuilder builder, object? context)
    {
        foreach (var child in Children)
        {
            child.Render(builder, context);
        }
    }
}

internal sealed class TextNode : TemplateNode
{
    private readonly string _text;

    public TextNode(string text)
    {
        _text = text;
    }

    public override void Render(StringBuilder builder, object? context) => builder.Append(_text);
}

internal sealed class ExpressionNode : TemplateNode
{
    private readonly TemplateExpression _expression;

    public ExpressionNode(TemplateExpression expression)
    {
        _expression = expression;
    }

    public override void Render(StringBuilder builder, object? context) =>
        builder.Append(TemplateValue.Format(_expression.Evaluate(context)));
}

internal sealed class IfNode : TemplateNode
{
    private readonly TemplateExpression _condition;
    private readonly IReadOnlyList<TemplateNode> _then;
    private readonly IReadOnlyList<TemplateNode> _else;

    public IfNode(
        TemplateExpression condition,
        IReadOnlyList<TemplateNode> thenNodes,
        IReadOnlyList<TemplateNode>? elseNodes)
    {
        _condition = condition;
        _then = thenNodes;
        _else = elseNodes ?? Array.Empty<TemplateNode>();
    }

    public override void Render(StringBuilder builder, object? context)
    {
        var nodes = TemplateValue.IsTruthy(_condition.Evaluate(context)) ? _then : _else;
        foreach (var node in nodes)
        {
            node.Render(builder, context);
        }
    }
}

internal abstract class TemplateExpression
{
    public abstract object? Evaluate(object? context);
}

internal sealed class LiteralExpression : TemplateExpression
{
    private readonly object? _value;

    public LiteralExpression(object? value)
    {
        _value = value;
    }

    public override object? Evaluate(object? context) => _value;
}

internal sealed class PathExpression : TemplateExpression
{
    private readonly string _path;

    public PathExpression(string path)
    {
        _path = path;
    }

    public override object? Evaluate(object? context) => TemplateValue.ResolvePath(context, _path);
}

internal sealed class FunctionExpression : TemplateExpression
{
    private readonly string _name;
    private readonly IReadOnlyList<TemplateExpression> _arguments;
    private readonly int _position;

    public FunctionExpression(string name, IReadOnlyList<TemplateExpression> arguments, int position)
    {
        _name = name;
        _arguments = arguments;
        _position = position;
    }

    public string Name => _name;

    public IReadOnlyList<TemplateExpression> Arguments => _arguments;

    public int Position => _position;

    public override object? Evaluate(object? context) =>
        TemplateExpressionEvaluator.EvaluateFunction(_name, _arguments, context, _position);
}
