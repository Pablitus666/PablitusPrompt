namespace PablitusPrompt.Core.Templating;

internal enum TemplateTokenKind
{
    Text,
    ActionStart,
    ActionEnd,
    Identifier,
    DotPath,
    String,
    Number,
    True,
    False,
    Null,
    OpenParen,
    CloseParen,
    EndOfTemplate,
}

internal readonly record struct TemplateToken(
    TemplateTokenKind Kind,
    string Value,
    int Position,
    int Length);
