using System.Text.RegularExpressions;

namespace PablitusPrompt.Core.Configuration;

/// <summary>
/// Lightweight color-reference validation. A reference can be a hex truecolor
/// value, a named ANSI color or a palette key; the actual resolution happens at
/// render time against the active theme palette.
/// </summary>
public static class ColorReferenceValidator
{
    private static readonly Regex HexPattern = new(
        "^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    private static readonly Regex PaletteKeyPattern = new(
        "^[A-Za-z_][A-Za-z0-9_-]*$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    private static readonly HashSet<string> NamedColors = new(StringComparer.OrdinalIgnoreCase)
    {
        "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
        "brightblack", "brightred", "brightgreen", "brightyellow", "brightblue",
        "brightmagenta", "brightcyan", "brightwhite", "gray", "grey", "transparent",
    };

    public static bool IsValid(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return true;
        }

        return HexPattern.IsMatch(value) ||
               NamedColors.Contains(value) ||
               PaletteKeyPattern.IsMatch(value);
    }
}
