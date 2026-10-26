using System.Globalization;

namespace PablitusPrompt.Core.Templating;

/// <summary>
/// Recursive-descent parser for the supported template subset. The parser builds
/// an AST once; rendering then walks the AST without re-interpreting the source.
/// </summary>
internal sealed class TemplateParser
{
    private readonly string _source;
    private readonly IReadOnlyList<TemplateToken> _tokens;
    private int _index;

    private TemplateParser(string source)
    {
        _source = source;
        _tokens = TemplateLexer.Tokenize(source);
    }

    public static TemplateRootNode Parse(string source)
    {
        ArgumentNullException.ThrowIfNull(source);
        return new TemplateParser(source).ParseDocument();
    }

    private TemplateRootNode ParseDocument()
    {
        var nodes = ParseNodes(stopAtIfTerminator: false);
        Expect(TemplateTokenKind.EndOfTemplate);
        return new TemplateRootNode(nodes);
    }

    private List<TemplateNode> ParseNodes(bool stopAtIfTerminator)
    {
        var nodes = new List<TemplateNode>();

        while (true)
        {
            var token = Peek();
            switch (token.Kind)
            {
                case TemplateTokenKind.EndOfTemplate:
                    if (stopAtIfTerminator)
                    {
                        throw Error("Unterminated 'if': expected 'end' before end of template.", token.Position, 0);
                    }

                    return nodes;

                case TemplateTokenKind.Text:
                    Next();
                    nodes.Add(new TextNode(token.Value));
                    continue;

                case TemplateTokenKind.ActionStart:
                {
                    var keyword = LookaheadKeyword();
                    if (keyword is "else" or "end")
                    {
                        if (stopAtIfTerminator)
                        {
                            return nodes;
                        }

                        throw Error($"Unexpected '{keyword}' action outside an 'if' block.", token.Position, 2);
                    }

                    if (keyword == "if")
                    {
                        nodes.Add(ParseIf());
                        continue;
                    }

                    Next();
                    var expression = ParseExpression();
                    Expect(TemplateTokenKind.ActionEnd);
                    nodes.Add(new ExpressionNode(expression));
                    continue;
                }

                default:
                    throw Error($"Unexpected token '{token.Value}'.", token.Position, token.Length);
            }
        }
    }

    private TemplateNode ParseIf()
    {
        Expect(TemplateTokenKind.ActionStart);
        var keyword = Expect(TemplateTokenKind.Identifier);
        if (!keyword.Value.Equals("if", StringComparison.OrdinalIgnoreCase))
        {
            throw Error($"Expected 'if' but found '{keyword.Value}'.", keyword.Position, keyword.Length);
        }

        return ParseIfBody();
    }

    private TemplateNode ParseIfBody()
    {
        var condition = ParseExpression();
        Expect(TemplateTokenKind.ActionEnd);

        var thenNodes = ParseNodes(stopAtIfTerminator: true);
        var terminator = ConsumeIfTerminator();

        List<TemplateNode>? elseNodes = null;
        switch (terminator)
        {
            case IfTerminator.End:
                break;

            case IfTerminator.Else:
                elseNodes = ParseNodes(stopAtIfTerminator: true);
                var end = ConsumeIfTerminator();
                if (end != IfTerminator.End)
                {
                    var token = Peek();
                    throw Error("Expected 'end' after 'else' block.", token.Position, token.Length);
                }

                break;

            case IfTerminator.ElseIf:
                elseNodes = new List<TemplateNode> { ParseElseIfBody() };
                break;
        }

        return new IfNode(condition, thenNodes, elseNodes);
    }

    private TemplateNode ParseElseIfBody()
    {
        // ConsumeIfTerminator leaves the 'if' identifier for this method.
        var ifToken = Expect(TemplateTokenKind.Identifier);
        if (!ifToken.Value.Equals("if", StringComparison.OrdinalIgnoreCase))
        {
            throw Error($"Expected 'if' after 'else' but found '{ifToken.Value}'.", ifToken.Position, ifToken.Length);
        }

        return ParseIfBody();
    }

    private IfTerminator ConsumeIfTerminator()
    {
        var start = Expect(TemplateTokenKind.ActionStart);
        var keyword = Expect(TemplateTokenKind.Identifier);
        switch (keyword.Value.ToLowerInvariant())
        {
            case "end":
                Expect(TemplateTokenKind.ActionEnd);
                return IfTerminator.End;

            case "else":
                if (Peek().Kind == TemplateTokenKind.Identifier &&
                    Peek().Value.Equals("if", StringComparison.OrdinalIgnoreCase))
                {
                    return IfTerminator.ElseIf;
                }

                Expect(TemplateTokenKind.ActionEnd);
                return IfTerminator.Else;

            default:
                throw Error(
                    $"Expected 'else' or 'end' but found '{keyword.Value}'.",
                    start.Position,
                    keyword.Position + keyword.Length - start.Position);
        }
    }

    private TemplateExpression ParseExpression()
    {
        var token = Peek();
        switch (token.Kind)
        {
            case TemplateTokenKind.OpenParen:
            {
                Next();
                var inner = ParseExpression();
                Expect(TemplateTokenKind.CloseParen);
                return inner;
            }

            case TemplateTokenKind.String:
                Next();
                return new LiteralExpression(token.Value);

            case TemplateTokenKind.Number:
                Next();
                return new LiteralExpression(ParseNumber(token));

            case TemplateTokenKind.True:
                Next();
                return new LiteralExpression(true);

            case TemplateTokenKind.False:
                Next();
                return new LiteralExpression(false);

            case TemplateTokenKind.Null:
                Next();
                return new LiteralExpression(null);

            case TemplateTokenKind.DotPath:
                Next();
                return new PathExpression(token.Value);

            case TemplateTokenKind.Identifier:
                Next();
                return ParseFunction(token);

            default:
                throw Error("Expected a value, property path or function call.", token.Position, token.Length);
        }
    }

    private TemplateExpression ParseFunction(TemplateToken nameToken)
    {
        if (!TemplateExpressionEvaluator.IsKnownFunction(nameToken.Value))
        {
            throw Error($"Unknown template function '{nameToken.Value}'.", nameToken.Position, nameToken.Length);
        }

        var arguments = new List<TemplateExpression>();
        while (true)
        {
            var token = Peek();
            if (token.Kind is TemplateTokenKind.ActionEnd or TemplateTokenKind.CloseParen)
            {
                break;
            }

            if (token.Kind == TemplateTokenKind.EndOfTemplate)
            {
                throw Error("Unterminated function call: expected '}}'.", token.Position, 0);
            }

            arguments.Add(ParseArgument());
        }

        if (!TemplateExpressionEvaluator.TryGetSignature(nameToken.Value, out var min, out var max))
        {
            throw Error($"Unknown template function '{nameToken.Value}'.", nameToken.Position, nameToken.Length);
        }

        if (arguments.Count < min || arguments.Count > max)
        {
            var expected = max == int.MaxValue
                ? $"at least {min}"
                : min == max
                    ? min.ToString(CultureInfo.InvariantCulture)
                    : $"{min}-{max}";
            throw Error(
                $"Function '{nameToken.Value}' expects {expected} argument(s) but got {arguments.Count}.",
                nameToken.Position,
                nameToken.Length);
        }

        return new FunctionExpression(nameToken.Value, arguments, nameToken.Position);
    }

    private TemplateExpression ParseArgument()
    {
        var token = Peek();
        switch (token.Kind)
        {
            case TemplateTokenKind.OpenParen:
                Next();
                var inner = ParseExpression();
                Expect(TemplateTokenKind.CloseParen);
                return inner;

            case TemplateTokenKind.String:
                Next();
                return new LiteralExpression(token.Value);

            case TemplateTokenKind.Number:
                Next();
                return new LiteralExpression(ParseNumber(token));

            case TemplateTokenKind.True:
                Next();
                return new LiteralExpression(true);

            case TemplateTokenKind.False:
                Next();
                return new LiteralExpression(false);

            case TemplateTokenKind.Null:
                Next();
                return new LiteralExpression(null);

            case TemplateTokenKind.DotPath:
                Next();
                return new PathExpression(token.Value);

            case TemplateTokenKind.Identifier:
                throw Error(
                    $"Function calls used as arguments must be wrapped in parentheses: '{token.Value}'.",
                    token.Position,
                    token.Length);

            default:
                throw Error("Expected an argument value.", token.Position, token.Length);
        }
    }

    private static object ParseNumber(TemplateToken token)
    {
        if (token.Value.Contains('.', StringComparison.Ordinal))
        {
            if (decimal.TryParse(token.Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var decimalValue))
            {
                return decimalValue;
            }
        }
        else if (long.TryParse(token.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var integerValue))
        {
            return integerValue;
        }

        return decimal.TryParse(token.Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var fallback)
            ? fallback
            : 0m;
    }

    private string? LookaheadKeyword()
    {
        if (Peek().Kind != TemplateTokenKind.ActionStart)
        {
            return null;
        }

        var next = Peek(1);
        return next.Kind == TemplateTokenKind.Identifier
            ? next.Value.ToLowerInvariant()
            : null;
    }

    private TemplateToken Peek(int offset = 0)
    {
        var position = _index + offset;
        return position >= 0 && position < _tokens.Count
            ? _tokens[position]
            : _tokens[^1];
    }

    private TemplateToken Next()
    {
        var token = Peek();
        if (token.Kind != TemplateTokenKind.EndOfTemplate)
        {
            _index++;
        }

        return token;
    }

    private TemplateToken Expect(TemplateTokenKind kind)
    {
        var token = Peek();
        if (token.Kind != kind)
        {
            throw Error(
                $"Expected {Describe(kind)} but found {Describe(token.Kind)}.",
                token.Position,
                token.Length);
        }

        return Next();
    }

    private static string Describe(TemplateTokenKind kind) =>
        kind switch
        {
            TemplateTokenKind.ActionEnd => "'}}'",
            TemplateTokenKind.ActionStart => "'{{'",
            TemplateTokenKind.EndOfTemplate => "end of template",
            TemplateTokenKind.Identifier => "an identifier",
            TemplateTokenKind.OpenParen => "'('",
            TemplateTokenKind.CloseParen => "')'",
            _ => kind.ToString(),
        };

    private TemplateParseException Error(string message, int position, int length)
    {
        var (line, column) = GetLineColumn(position);
        return new TemplateParseException(message, position, length, line, column);
    }

    private (int Line, int Column) GetLineColumn(int position)
    {
        var line = 1;
        var column = 1;
        var limit = Math.Clamp(position, 0, _source.Length);
        for (var i = 0; i < limit; i++)
        {
            if (_source[i] == '\n')
            {
                line++;
                column = 1;
            }
            else
            {
                column++;
            }
        }

        return (line, column);
    }

    private enum IfTerminator
    {
        End,
        Else,
        ElseIf,
    }
}
