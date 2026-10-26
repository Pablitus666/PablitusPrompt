namespace PablitusPrompt.Core.Rendering;

/// <summary>
/// Resolves a color reference through the theme palette before falling back to
/// ANSI names and hex truecolor. Unknown references render uncolored instead of
/// breaking the prompt.
/// </summary>
public sealed class ColorResolver
{
    private readonly IReadOnlyDictionary<string, string> _palette;

    public ColorResolver(IReadOnlyDictionary<string, string>? palette)
    {
        _palette = palette ?? new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    }

    public AnsiColor? Resolve(string? reference) => ResolveCore(reference, depth: 0);

    private AnsiColor? ResolveCore(string? reference, int depth)
    {
        if (string.IsNullOrWhiteSpace(reference) || depth > 8)
        {
            return null;
        }

        if (_palette.TryGetValue(reference, out var mapped) && !string.IsNullOrWhiteSpace(mapped))
        {
            var resolved = ResolveCore(mapped, depth + 1);
            if (resolved is not null)
            {
                return resolved;
            }
        }
        else
        {
            foreach (var pair in _palette)
            {
                if (string.Equals(pair.Key, reference, StringComparison.OrdinalIgnoreCase) &&
                    !string.IsNullOrWhiteSpace(pair.Value))
                {
                    var resolved = ResolveCore(pair.Value, depth + 1);
                    if (resolved is not null)
                    {
                        return resolved;
                    }

                    break;
                }
            }
        }

        return AnsiColor.TryParse(reference, out var color) ? color : null;
    }
}
