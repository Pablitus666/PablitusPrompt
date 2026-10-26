using System.Globalization;

namespace PablitusPrompt.Core.Rendering;

public static class AnsiCodes
{
    public const string Escape = "\u001b[";
    public const string Reset = "\u001b[0m";
}

/// <summary>
/// ANSI or 24-bit truecolor value. Named colors keep their classic SGR codes so
/// terminal themes keep working; hex colors are emitted as 38;2 / 48;2.
/// </summary>
public readonly struct AnsiColor : IEquatable<AnsiColor>
{
    private static readonly Dictionary<string, int> NamedIndexes = new(StringComparer.OrdinalIgnoreCase)
    {
        ["black"] = 0,
        ["red"] = 1,
        ["green"] = 2,
        ["yellow"] = 3,
        ["blue"] = 4,
        ["magenta"] = 5,
        ["cyan"] = 6,
        ["white"] = 7,
        ["brightblack"] = 8,
        ["gray"] = 8,
        ["grey"] = 8,
        ["brightred"] = 9,
        ["brightgreen"] = 10,
        ["brightyellow"] = 11,
        ["brightblue"] = 12,
        ["brightmagenta"] = 13,
        ["brightcyan"] = 14,
        ["brightwhite"] = 15,
    };

    private static readonly (byte R, byte G, byte B)[] NamedRgb =
    {
        (0, 0, 0), (205, 49, 49), (13, 188, 121), (229, 229, 16),
        (36, 114, 200), (188, 63, 188), (17, 168, 205), (229, 229, 229),
        (102, 102, 102), (241, 76, 76), (35, 209, 139), (245, 245, 67),
        (59, 142, 234), (214, 112, 214), (41, 184, 219), (255, 255, 255),
    };

    private readonly byte _kind;
    private readonly byte _index;
    private readonly byte _red;
    private readonly byte _green;
    private readonly byte _blue;

    private AnsiColor(byte index)
    {
        _kind = 0;
        _index = index;
    }

    private AnsiColor(byte red, byte green, byte blue)
    {
        _kind = 1;
        _red = red;
        _green = green;
        _blue = blue;
    }

    public static AnsiColor Black => new(0);

    public static AnsiColor White => new(7);

    public bool IsRgb => _kind == 1;

    public int NamedIndex => _index;

    public byte Red => _red;

    public byte Green => _green;

    public byte Blue => _blue;

    public static AnsiColor FromRgb(byte red, byte green, byte blue) => new(red, green, blue);

    public static AnsiColor FromNamedIndex(int index)
    {
        if (index is < 0 or > 15)
        {
            throw new ArgumentOutOfRangeException(nameof(index), "Named ANSI index must be between 0 and 15.");
        }

        return new AnsiColor((byte)index);
    }

    public static bool TryParse(string? value, out AnsiColor color)
    {
        color = default;
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var text = value.Trim();
        if (text.Equals("transparent", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (NamedIndexes.TryGetValue(text, out var namedIndex))
        {
            color = new AnsiColor((byte)namedIndex);
            return true;
        }

        var hex = text.StartsWith('#') ? text[1..] : text;
        if (hex.Length is 3)
        {
            if (!TryParseHexByte(new string(hex[0], 2), out var r) ||
                !TryParseHexByte(new string(hex[1], 2), out var g) ||
                !TryParseHexByte(new string(hex[2], 2), out var b))
            {
                return false;
            }

            color = new AnsiColor(r, g, b);
            return true;
        }

        if (hex.Length is 6 or 8)
        {
            if (!TryParseHexByte(hex[..2], out var r) ||
                !TryParseHexByte(hex.Substring(2, 2), out var g) ||
                !TryParseHexByte(hex.Substring(4, 2), out var b))
            {
                return false;
            }

            color = new AnsiColor(r, g, b);
            return true;
        }

        return false;
    }

    private static bool TryParseHexByte(string value, out byte result) =>
        byte.TryParse(value, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out result);

    public string ToForegroundEscape() =>
        IsRgb
            ? $"{AnsiCodes.Escape}38;2;{_red};{_green};{_blue}m"
            : $"{AnsiCodes.Escape}{(_index < 8 ? 30 + _index : 90 + (_index - 8))}m";

    public string ToBackgroundEscape() =>
        IsRgb
            ? $"{AnsiCodes.Escape}48;2;{_red};{_green};{_blue}m"
            : $"{AnsiCodes.Escape}{(_index < 8 ? 40 + _index : 100 + (_index - 8))}m";

    public (byte R, byte G, byte B) ToRgb() =>
        IsRgb ? (_red, _green, _blue) : NamedRgb[_index];

    public static AnsiColor ContrastFor(AnsiColor background)
    {
        var (red, green, blue) = background.ToRgb();
        var luminance = (0.299 * red) + (0.587 * green) + (0.114 * blue);
        return luminance > 150 ? Black : White;
    }

    public bool Equals(AnsiColor other) =>
        _kind == other._kind &&
        _index == other._index &&
        _red == other._red &&
        _green == other._green &&
        _blue == other._blue;

    public override bool Equals(object? obj) => obj is AnsiColor other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(_kind, _index, _red, _green, _blue);

    public override string ToString() =>
        IsRgb
            ? $"#{_red:x2}{_green:x2}{_blue:x2}"
            : $"ansi:{_index}";

    public static bool operator ==(AnsiColor left, AnsiColor right) => left.Equals(right);

    public static bool operator !=(AnsiColor left, AnsiColor right) => !left.Equals(right);
}
