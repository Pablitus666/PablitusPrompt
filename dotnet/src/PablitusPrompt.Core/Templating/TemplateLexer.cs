using System.Text;

namespace PablitusPrompt.Core.Templating;

/// <summary>
/// Real tokenizer for the Oh My Posh compatible template subset. Text and action
/// tokens carry their absolute position so later parser errors can point at the
/// offending character instead of a generic message.
/// </summary>
internal sealed class TemplateLexer
{
    private readonly string _input;
    private readonly List<TemplateToken> _tokens = new();
    private int _index;
    private bool _trimNextText;

    private TemplateLexer(string input)
    {
        _input = input;
    }

    public static IReadOnlyList<TemplateToken> Tokenize(string input)
    {
        ArgumentNullException.ThrowIfNull(input);
        return new TemplateLexer(input).Run();
    }

    private IReadOnlyList<TemplateToken> Run()
    {
        while (_index < _input.Length)
        {
            var open = _input.IndexOf("{{", _index, StringComparison.Ordinal);
            if (open < 0)
            {
                AddText(_index, _input.Length - _index);
                _index = _input.Length;
                break;
            }

            AddText(_index, open - _index);
            LexAction(open);
        }

        _tokens.Add(new TemplateToken(TemplateTokenKind.EndOfTemplate, string.Empty, _input.Length, 0));
        return _tokens;
    }

    private void AddText(int start, int length)
    {
        if (length <= 0)
        {
            return;
        }

        var text = _input.Substring(start, length);
        if (_trimNextText)
        {
            text = text.TrimStart(' ', '\t', '\r', '\n');
            _trimNextText = false;
        }

        if (text.Length > 0)
        {
            _tokens.Add(new TemplateToken(TemplateTokenKind.Text, text, start, length));
        }
    }

    private void LexAction(int open)
    {
        var cursor = open + 2;
        if (cursor < _input.Length && _input[cursor] == '-')
        {
            TrimPreviousText();
            cursor++;
        }

        _tokens.Add(new TemplateToken(TemplateTokenKind.ActionStart, "{{", open, 2));

        var close = FindClose(cursor);
        if (close < 0)
        {
            throw Error("Unterminated template action: missing '}}'.", open, 2);
        }

        var contentEnd = close;
        if (contentEnd > cursor && _input[contentEnd - 1] == '-')
        {
            contentEnd--;
            _trimNextText = true;
        }

        LexActionContent(cursor, contentEnd);
        _tokens.Add(new TemplateToken(TemplateTokenKind.ActionEnd, "}}", close, 2));
        _index = close + 2;
    }

    private int FindClose(int start)
    {
        var inString = false;
        for (var i = start; i < _input.Length - 1; i++)
        {
            var c = _input[i];
            if (inString)
            {
                if (c == '\\')
                {
                    i++;
                    continue;
                }

                if (c == '"')
                {
                    inString = false;
                }

                continue;
            }

            if (c == '"')
            {
                inString = true;
                continue;
            }

            if (c == '}' && _input[i + 1] == '}')
            {
                return i;
            }
        }

        return -1;
    }

    private void TrimPreviousText()
    {
        if (_tokens.Count == 0)
        {
            return;
        }

        var last = _tokens[^1];
        if (last.Kind != TemplateTokenKind.Text)
        {
            return;
        }

        var trimmed = last.Value.TrimEnd(' ', '\t', '\r', '\n');
        if (trimmed.Length == 0)
        {
            _tokens.RemoveAt(_tokens.Count - 1);
            return;
        }

        _tokens[^1] = last with { Value = trimmed };
    }

    private void LexActionContent(int start, int end)
    {
        var i = start;
        while (i < end)
        {
            var c = _input[i];
            if (char.IsWhiteSpace(c))
            {
                i++;
                continue;
            }

            var tokenStart = i;
            switch (c)
            {
                case '(':
                    _tokens.Add(new TemplateToken(TemplateTokenKind.OpenParen, "(", tokenStart, 1));
                    i++;
                    break;

                case ')':
                    _tokens.Add(new TemplateToken(TemplateTokenKind.CloseParen, ")", tokenStart, 1));
                    i++;
                    break;

                case '"':
                    i = LexString(i, end);
                    break;

                case '.':
                    i++;
                    while (i < end && IsPathCharacter(_input[i]))
                    {
                        i++;
                    }

                    _tokens.Add(new TemplateToken(
                        TemplateTokenKind.DotPath,
                        _input.Substring(tokenStart, i - tokenStart),
                        tokenStart,
                        i - tokenStart));
                    break;

                case '-':
                case var _ when char.IsDigit(c):
                    i = LexNumber(i, end);
                    break;

                default:
                    if (IsIdentifierStart(c))
                    {
                        i = LexIdentifier(i, end);
                        break;
                    }

                    throw Error($"Unexpected character '{c}' in template action.", i, 1);
            }
        }
    }

    private int LexString(int start, int end)
    {
        var builder = new StringBuilder();
        var i = start + 1;
        var closed = false;

        while (i < end)
        {
            var c = _input[i];
            if (c == '\\')
            {
                if (i + 1 >= end)
                {
                    throw Error("Unterminated escape sequence in string literal.", i, 1);
                }

                var escaped = _input[i + 1];
                switch (escaped)
                {
                    case '"':
                        builder.Append('"');
                        break;
                    case '\\':
                        builder.Append('\\');
                        break;
                    case 'n':
                        builder.Append('\n');
                        break;
                    case 'r':
                        builder.Append('\r');
                        break;
                    case 't':
                        builder.Append('\t');
                        break;
                    case 'u':
                        if (i + 5 >= end ||
                            !int.TryParse(_input.AsSpan(i + 2, 4), System.Globalization.NumberStyles.HexNumber, null, out var codePoint))
                        {
                            throw Error("Invalid unicode escape sequence.", i, 2);
                        }

                        builder.Append((char)codePoint);
                        i += 4;
                        break;
                    default:
                        builder.Append(escaped);
                        break;
                }

                i += 2;
                continue;
            }

            if (c == '"')
            {
                closed = true;
                i++;
                break;
            }

            builder.Append(c);
            i++;
        }

        if (!closed)
        {
            throw Error("Unterminated string literal.", start, Math.Max(1, i - start));
        }

        _tokens.Add(new TemplateToken(
            TemplateTokenKind.String,
            builder.ToString(),
            start,
            i - start));
        return i;
    }

    private int LexNumber(int start, int end)
    {
        var i = start;
        if (_input[i] == '-')
        {
            i++;
        }

        var digits = 0;
        while (i < end && char.IsDigit(_input[i]))
        {
            i++;
            digits++;
        }

        if (i < end && _input[i] == '.')
        {
            i++;
            while (i < end && char.IsDigit(_input[i]))
            {
                i++;
                digits++;
            }
        }

        if (digits == 0)
        {
            throw Error("Invalid numeric literal.", start, Math.Max(1, i - start));
        }

        _tokens.Add(new TemplateToken(
            TemplateTokenKind.Number,
            _input.Substring(start, i - start),
            start,
            i - start));
        return i;
    }

    private int LexIdentifier(int start, int end)
    {
        var i = start + 1;
        while (i < end && IsIdentifierPart(_input[i]))
        {
            i++;
        }

        var value = _input.Substring(start, i - start);
        var kind = value.ToLowerInvariant() switch
        {
            "true" => TemplateTokenKind.True,
            "false" => TemplateTokenKind.False,
            "nil" or "null" => TemplateTokenKind.Null,
            _ => TemplateTokenKind.Identifier,
        };

        _tokens.Add(new TemplateToken(kind, value, start, i - start));
        return i;
    }

    private static bool IsIdentifierStart(char c) =>
        char.IsLetter(c) || c == '_';

    private static bool IsIdentifierPart(char c) =>
        char.IsLetterOrDigit(c) || c == '_' || c == '-';

    private static bool IsPathCharacter(char c) =>
        char.IsLetterOrDigit(c) || c == '_' || c == '-' || c == '.';

    private TemplateParseException Error(string message, int position, int length)
    {
        var (line, column) = GetLineColumn(position);
        return new TemplateParseException(message, position, length, line, column);
    }

    private (int Line, int Column) GetLineColumn(int position)
    {
        var line = 1;
        var column = 1;
        var limit = Math.Clamp(position, 0, _input.Length);
        for (var i = 0; i < limit; i++)
        {
            if (_input[i] == '\n')
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
}
