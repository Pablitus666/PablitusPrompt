using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace PablitusPrompt.Core.Rendering;

/// <summary>
/// Pure layout helpers for right prompts, tooltips and transient prompts. Widths
/// are measured without ANSI escapes so alignment is deterministic and testable.
/// </summary>
public static class PromptLayout
{
    private const string SaveCursor = "\u001b[s";
    private const string RestoreCursor = "\u001b[u";

    private static readonly Regex AnsiPattern = new(
        @"\u001b\[[0-9;?]*[ -/]*[@-~]|\u001b\][^\u0007]*(?:\u0007|\u001b\\)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    /// <summary>Returns the display width of the last line in <paramref name="text"/>.</summary>
    public static int MeasureLastLine(string? text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return 0;
        }

        var clean = StripAnsi(text);
        var newline = clean.LastIndexOf('\n');
        return Measure(clean[(newline + 1)..]);
    }

    /// <summary>Returns the display width of <paramref name="text"/> without ANSI escapes.</summary>
    public static int Measure(string? text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return 0;
        }

        var width = 0;
        foreach (var rune in StripAnsi(text).EnumerateRunes())
        {
            width += RuneWidth(rune);
        }

        return width;
    }

    public static string StripAnsi(string? text) =>
        string.IsNullOrEmpty(text) ? string.Empty : AnsiPattern.Replace(text, string.Empty);

    /// <summary>
    /// Combines the left prompt and right prompt. A filler is written between
    /// both while the cursor is restored to the left prompt afterwards. Without
    /// a filler the right prompt is placed with an absolute cursor move.
    /// </summary>
    public static string Compose(
        string left,
        string right,
        int terminalWidth,
        string? overflow,
        Func<int, string>? fillerFactory,
        bool useAnsi)
    {
        ArgumentNullException.ThrowIfNull(left);
        ArgumentNullException.ThrowIfNull(right);

        if (string.IsNullOrEmpty(right) || terminalWidth <= 0)
        {
            return left;
        }

        var leftWidth = MeasureLastLine(left);
        var rightWidth = Measure(right);
        var available = terminalWidth - leftWidth - rightWidth;
        var mode = string.IsNullOrWhiteSpace(overflow)
            ? string.Empty
            : overflow.Trim().ToLowerInvariant();

        if (available < 0)
        {
            return mode switch
            {
                "hide" => left,
                "break" => BreakLine(left, right, terminalWidth, rightWidth),
                _ => left + right,
            };
        }

        var fillerSource = fillerFactory?.Invoke(available);
        var filler = string.IsNullOrEmpty(fillerSource)
            ? string.Empty
            : Fit(fillerSource, available);

        if (!string.IsNullOrEmpty(filler))
        {
            return useAnsi
                ? left + SaveCursor + filler + right + RestoreCursor
                : left + filler + right;
        }

        if (useAnsi)
        {
            var column = Math.Max(1, terminalWidth - rightWidth + 1);
            return left + SaveCursor + AnsiCodes.Escape + column.ToString(CultureInfo.InvariantCulture) + "G" + right + RestoreCursor;
        }

        return left + new string(' ', available) + right;
    }

    /// <summary>Right-aligns text starting at a zero-based cursor column.</summary>
    public static string RightAlign(string text, int terminalWidth, int column)
    {
        ArgumentNullException.ThrowIfNull(text);

        if (text.Length == 0 || terminalWidth <= 0)
        {
            return text;
        }

        var padding = terminalWidth - Measure(text) - Math.Max(0, column);
        return padding > 0 ? new string(' ', padding) + text : text;
    }

    /// <summary>Repeats <paramref name="source"/> until it fills the requested width.</summary>
    public static string Fit(string source, int width)
    {
        if (string.IsNullOrEmpty(source) || width <= 0)
        {
            return string.Empty;
        }

        var sourceWidth = Measure(source);
        if (sourceWidth <= 0)
        {
            return string.Empty;
        }

        if (sourceWidth >= width)
        {
            return TakeWidth(source, width);
        }

        var builder = new StringBuilder(source.Length * Math.Max(1, width / sourceWidth));
        var remaining = width;
        while (remaining >= sourceWidth)
        {
            builder.Append(source);
            remaining -= sourceWidth;
        }

        if (remaining > 0)
        {
            builder.Append(TakeWidth(source, remaining));
        }

        return builder.ToString();
    }

    private static string BreakLine(string left, string right, int terminalWidth, int rightWidth)
    {
        var builder = new StringBuilder(left.Length + right.Length + terminalWidth + 2);
        builder.Append(left.TrimEnd('\r', '\n'));
        builder.Append('\n');

        var padding = Math.Max(0, terminalWidth - rightWidth);
        if (padding > 0)
        {
            builder.Append(' ', padding);
        }

        builder.Append(right);
        return builder.ToString();
    }

    private static string TakeWidth(string text, int width)
    {
        if (width <= 0)
        {
            return string.Empty;
        }

        var builder = new StringBuilder(text.Length);
        var used = 0;
        foreach (var rune in text.EnumerateRunes())
        {
            var runeWidth = RuneWidth(rune);
            if (used + runeWidth > width)
            {
                break;
            }

            builder.Append(rune.ToString());
            used += runeWidth;
        }

        return builder.ToString();
    }

    private static int RuneWidth(Rune rune)
    {
        var category = Rune.GetUnicodeCategory(rune);
        if (category is UnicodeCategory.NonSpacingMark or UnicodeCategory.EnclosingMark or UnicodeCategory.Format)
        {
            return 0;
        }

        if (rune.Value == '\t')
        {
            return 4;
        }

        if (Rune.IsControl(rune))
        {
            return 0;
        }

        var value = rune.Value;
        return value is >= 0x1100 and <= 0x115F
            or >= 0x2E80 and <= 0xA4CF
            or >= 0xAC00 and <= 0xD7A3
            or >= 0xF900 and <= 0xFAFF
            or >= 0xFE10 and <= 0xFE19
            or >= 0xFE30 and <= 0xFE6F
            or >= 0xFF00 and <= 0xFF60
            or >= 0xFFE0 and <= 0xFFE6
            or >= 0x1F300 and <= 0x1FAFF
            or >= 0x20000 and <= 0x3FFFD
            ? 2
            : 1;
    }
}
