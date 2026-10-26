namespace PablitusPrompt.Core.Templating;

/// <summary>
/// Parse error with an absolute character position and a one-based line/column.
/// The message always contains the position so callers that only log
/// <see cref="Exception.Message"/> still get actionable information.
/// </summary>
public sealed class TemplateParseException : Exception
{
    public TemplateParseException(string message, int position, int length, int line, int column)
        : base($"{message} (line {line}, column {column}, index {position})")
    {
        Position = position;
        Length = length;
        Line = line;
        Column = column;
    }

    public int Position { get; }

    public int Length { get; }

    public int Line { get; }

    public int Column { get; }
}
