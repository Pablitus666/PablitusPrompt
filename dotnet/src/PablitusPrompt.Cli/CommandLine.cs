using System.Globalization;

namespace PablitusPrompt.Cli;

internal sealed class CliUsageException : Exception
{
    public CliUsageException(string message)
        : base(message)
    {
    }
}

/// <summary>
/// Minimal argument parser: no external dependencies, supports
/// <c>--name value</c>, <c>--name=value</c> and a small alias table.
/// </summary>
internal sealed class CommandLine
{
    private readonly Dictionary<string, string> _values = new(StringComparer.OrdinalIgnoreCase);
    private readonly List<string> _positionals = new();

    public IReadOnlyList<string> Positionals => _positionals;

    public bool Has(string name) => _values.ContainsKey(name);

    public string? Get(string name) => _values.TryGetValue(name, out var value) ? value : null;

    public int GetInt(string name, int defaultValue)
    {
        if (!_values.TryGetValue(name, out var value))
        {
            return defaultValue;
        }

        if (!int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var result))
        {
            throw new CliUsageException($"Option '--{name}' expects an integer but got '{value}'.");
        }

        return result;
    }

    public static CommandLine Parse(
        IReadOnlyList<string> args,
        IEnumerable<string> optionNames,
        IEnumerable<string> flagNames,
        IReadOnlyDictionary<string, string>? aliases = null)
    {
        var options = new HashSet<string>(optionNames, StringComparer.OrdinalIgnoreCase);
        var flags = new HashSet<string>(flagNames, StringComparer.OrdinalIgnoreCase);
        var commandLine = new CommandLine();
        aliases ??= new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        for (var index = 0; index < args.Count; index++)
        {
            var arg = args[index];
            if (arg == "--")
            {
                for (index++; index < args.Count; index++)
                {
                    commandLine._positionals.Add(args[index]);
                }

                break;
            }

            if (arg.StartsWith("--", StringComparison.Ordinal))
            {
                index = ParseLongOption(args, index, options, flags, commandLine);
                continue;
            }

            if (arg.Length > 1 && arg[0] == '-' && !char.IsDigit(arg[1]))
            {
                index = ParseShortOption(args, index, options, flags, aliases, commandLine);
                continue;
            }

            commandLine._positionals.Add(arg);
        }

        return commandLine;
    }

    private static int ParseLongOption(
        IReadOnlyList<string> args,
        int index,
        HashSet<string> options,
        HashSet<string> flags,
        CommandLine commandLine)
    {
        var raw = args[index][2..];
        var separator = raw.IndexOf('=');
        var name = separator >= 0 ? raw[..separator] : raw;
        var inlineValue = separator >= 0 ? raw[(separator + 1)..] : null;

        if (name.Length == 0)
        {
            throw new CliUsageException("Empty option name after '--'.");
        }

        if (flags.Contains(name))
        {
            if (inlineValue is not null)
            {
                throw new CliUsageException($"Flag '--{name}' does not accept a value.");
            }

            commandLine._values[name] = "true";
            return index;
        }

        if (!options.Contains(name))
        {
            throw new CliUsageException($"Unknown option '--{name}'.");
        }

        if (inlineValue is null)
        {
            if (index + 1 >= args.Count || args[index + 1].StartsWith("--", StringComparison.Ordinal))
            {
                throw new CliUsageException($"Option '--{name}' requires a value.");
            }

            inlineValue = args[++index];
        }

        commandLine._values[name] = inlineValue;
        return index;
    }

    private static int ParseShortOption(
        IReadOnlyList<string> args,
        int index,
        HashSet<string> options,
        HashSet<string> flags,
        IReadOnlyDictionary<string, string> aliases,
        CommandLine commandLine)
    {
        var alias = args[index][1..];
        if (!aliases.TryGetValue(alias, out var name))
        {
            throw new CliUsageException($"Unknown option '-{alias}'.");
        }

        if (flags.Contains(name))
        {
            commandLine._values[name] = "true";
            return index;
        }

        if (!options.Contains(name))
        {
            throw new CliUsageException($"Unknown option '-{alias}'.");
        }

        if (index + 1 >= args.Count)
        {
            throw new CliUsageException($"Option '-{alias}' requires a value.");
        }

        commandLine._values[name] = args[++index];
        return index;
    }
}
