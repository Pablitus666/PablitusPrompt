using System.Text;
using PablitusPrompt.Core;
using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Omp;
using PablitusPrompt.Core.Segments;

namespace PablitusPrompt.Cli;

internal static class Program
{
    private static readonly IReadOnlyDictionary<string, string> Aliases =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["o"] = "output",
            ["c"] = "config",
            ["h"] = "help",
            ["n"] = "no-color",
        };

    private static async Task<int> Main(string[] args)
    {
        try
        {
            Console.OutputEncoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false);
        }
        catch (Exception exception) when (exception is IOException or PlatformNotSupportedException)
        {
            // Redirected consoles can reject encoding changes; output still works.
        }

        using var cancellation = new CancellationTokenSource();
        ConsoleCancelEventHandler handler = (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            cancellation.Cancel();
        };

        Console.CancelKeyPress += handler;
        try
        {
            return await RunAsync(args, cancellation.Token);
        }
        catch (CliUsageException exception)
        {
            Console.Error.WriteLine($"ppf: {exception.Message}");
            Console.Error.WriteLine();
            PrintGeneralUsage(Console.Error);
            return 2;
        }
        catch (PpfConfigurationException exception)
        {
            Console.Error.WriteLine(exception.Message);
            return 1;
        }
        catch (OmpImportException exception)
        {
            Console.Error.WriteLine($"ppf: {exception.Message}");
            return 1;
        }
        catch (OperationCanceledException)
        {
            Console.Error.WriteLine("ppf: cancelled.");
            return 130;
        }
        catch (Exception exception) when (
            exception is IOException or UnauthorizedAccessException or ArgumentException)
        {
            Console.Error.WriteLine($"ppf: {exception.Message}");
            return 1;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine($"ppf: unexpected error: {exception.Message}");
            return 1;
        }
        finally
        {
            Console.CancelKeyPress -= handler;
        }
    }

    private static Task<int> RunAsync(string[] args, CancellationToken cancellationToken)
    {
        if (args.Length == 0)
        {
            PrintGeneralUsage(Console.Out);
            return Task.FromResult(0);
        }

        var command = args[0].ToLowerInvariant();
        return command switch
        {
            "theme" => RunThemeAsync(args, cancellationToken),
            "render" => RunRenderAsync(args, debug: false, cancellationToken),
            "debug" => RunRenderAsync(args, debug: true, cancellationToken),
            "version" or "--version" or "-v" => PrintVersion(),
            "help" or "--help" or "-h" => PrintHelp(),
            _ => Task.FromResult(FailUnknownCommand(command)),
        };
    }

    private static Task<int> RunThemeAsync(string[] args, CancellationToken cancellationToken)
    {
        if (args.Length < 2)
        {
            Console.Error.WriteLine("ppf: missing theme subcommand.");
            PrintThemeUsage(Console.Error);
            return Task.FromResult(2);
        }

        return args[1].ToLowerInvariant() switch
        {
            "import" => RunThemeImportAsync(args.Skip(2).ToArray()),
            "validate" => RunThemeValidateAsync(args.Skip(2).ToArray()),
            "help" or "--help" or "-h" => PrintThemeUsage(Console.Out),
            _ => Task.FromResult(FailUnknownThemeCommand(args[1])),
        };
    }

    private static Task<int> RunThemeImportAsync(IReadOnlyList<string> args)
    {
        var commandLine = CommandLine.Parse(
            args,
            optionNames: new[] { "output", "name" },
            flagNames: new[] { "ignore-unsupported", "help" },
            aliases: Aliases);

        if (commandLine.Has("help"))
        {
            PrintThemeUsage(Console.Out);
            return Task.FromResult(0);
        }

        if (commandLine.Positionals.Count != 1)
        {
            throw new CliUsageException("Usage: ppf theme import <archivo.omp.json> [--output <archivo.ppf.json>].");
        }

        var input = commandLine.Positionals[0];
        if (!File.Exists(input))
        {
            throw new FileNotFoundException($"Input theme not found: {input}", input);
        }

        var importer = new OmpThemeImporter();
        var theme = importer.ImportFile(
            input,
            commandLine.Has("ignore-unsupported"),
            commandLine.Get("name"));

        var errors = PpfConfigValidator.ValidateTheme(theme);
        if (errors.Count > 0)
        {
            throw PpfConfigurationException.FromErrors(input, errors);
        }

        var output = commandLine.Get("output");
        if (string.IsNullOrWhiteSpace(output))
        {
            Console.Out.Write(PpfConfigSerializer.SerializeTheme(theme));
            Console.Out.WriteLine();
        }
        else
        {
            PpfConfigSerializer.SaveTheme(theme, output);
            Console.Error.WriteLine($"Imported '{input}' -> '{Path.GetFullPath(output)}'.");
        }

        return Task.FromResult(0);
    }

    private static Task<int> RunThemeValidateAsync(IReadOnlyList<string> args)
    {
        var commandLine = CommandLine.Parse(
            args,
            optionNames: Array.Empty<string>(),
            flagNames: new[] { "help" },
            aliases: Aliases);

        if (commandLine.Has("help"))
        {
            PrintThemeUsage(Console.Out);
            return Task.FromResult(0);
        }

        if (commandLine.Positionals.Count == 0)
        {
            throw new CliUsageException("Usage: ppf theme validate <archivo.ppf.json> [<archivo2> ...].");
        }

        var exitCode = 0;
        foreach (var path in commandLine.Positionals)
        {
            try
            {
                if (!File.Exists(path))
                {
                    Console.Error.WriteLine($"ppf: file not found: {path}");
                    exitCode = 1;
                    continue;
                }

                var json = File.ReadAllText(path);
                var kind = PpfConfigSerializer.DetectDocumentKind(json);
                if (kind == PpfDocumentKind.Theme)
                {
                    _ = PpfConfigSerializer.LoadThemeFromJson(json, path);
                }
                else
                {
                    _ = PpfConfigSerializer.LoadConfigFromJson(json, path);
                }

                Console.Out.WriteLine($"OK {path}");
            }
            catch (PpfConfigurationException exception)
            {
                Console.Error.WriteLine(exception.Message);
                exitCode = 1;
            }
            catch (System.Text.Json.JsonException exception)
            {
                Console.Error.WriteLine($"ppf: invalid JSON in '{path}': {exception.Message}");
                exitCode = 1;
            }
        }

        return Task.FromResult(exitCode);
    }

    private static async Task<int> RunRenderAsync(
        string[] args,
        bool debug,
        CancellationToken cancellationToken)
    {
        var commandLine = CommandLine.Parse(
            args.Skip(1).ToArray(),
            optionNames: new[] { "config", "cwd", "exit-code", "renderer", "terminal-width", "command-line", "tooltip", "column" },
            flagNames: new[] { "no-color", "no-cache", "transient", "help" },
            aliases: Aliases);

        if (commandLine.Has("help"))
        {
            PrintRenderUsage(Console.Out);
            return 0;
        }

        var configPath = commandLine.Get("config");
        if (string.IsNullOrWhiteSpace(configPath))
        {
            throw new CliUsageException("Usage: ppf render --config <archivo.ppf.json>.");
        }

        if (!File.Exists(configPath))
        {
            throw new FileNotFoundException($"Configuration not found: {configPath}", configPath);
        }

        var config = LoadConfigForRender(configPath);
        var terminalWidth = commandLine.GetInt("terminal-width", 0);
        var commandText = commandLine.Get("command-line") ?? commandLine.Get("tooltip");
        var context = PromptContextFactory.Create(
            commandLine.Get("cwd"),
            commandLine.GetInt("exit-code", 0),
            terminalWidth,
            commandText,
            column: commandLine.GetInt("column", 0));

        var engine = new PromptEngine();
        var options = new PromptEngineOptions
        {
            UseAnsi = !commandLine.Has("no-color"),
            RendererOverride = commandLine.Get("renderer"),
            UseCache = !commandLine.Has("no-cache"),
            TerminalWidth = terminalWidth,
        };

        if (commandLine.Has("transient"))
        {
            var transient = engine.RenderTransient(config, context, options);
            if (!string.IsNullOrEmpty(transient))
            {
                Console.Out.Write(transient);
                Console.Out.Flush();
            }

            return 0;
        }

        var tooltipCommand = commandLine.Get("tooltip");
        if (!string.IsNullOrWhiteSpace(tooltipCommand))
        {
            var tooltip = await engine.RenderTooltipAsync(
                config,
                context,
                tooltipCommand,
                terminalWidth,
                commandLine.GetInt("column", 0),
                options,
                cancellationToken);
            Console.Out.Write(tooltip.Output);
            Console.Out.Flush();
            return 0;
        }

        var result = await engine.RenderAsync(
            config,
            context,
            options,
            cancellationToken);

        Console.Out.Write(result.Output);
        Console.Out.Flush();

        if (debug)
        {
            PrintDebugReport(result);
        }

        return 0;
    }

    private static PpfConfig LoadConfigForRender(string path)
    {
        var json = File.ReadAllText(path);
        if (PpfConfigSerializer.DetectDocumentKind(json) == PpfDocumentKind.Theme)
        {
            var theme = PpfConfigSerializer.LoadThemeFromJson(json, path);
            return new PpfConfig
            {
                Theme = theme,
                Renderer = theme.Renderer ?? "plain",
                FinalSpace = theme.FinalSpace,
                Version = theme.Version,
            };
        }

        return PpfConfigSerializer.LoadConfigFromJson(json, path);
    }

    private static void PrintDebugReport(PromptRunResult result)
    {
        Console.Error.WriteLine();
        Console.Error.WriteLine(
            $"{"Segment",-30} {"Type",-10} {"Status",-9} {"ms",10}  Error");
        Console.Error.WriteLine(new string('-', 82));

        foreach (var segment in result.Segments)
        {
            var name = Truncate(segment.Name, 30);
            var type = Truncate(segment.Type, 10);
            var status = segment.Status.ToString();
            var error = segment.Error ?? string.Empty;
            Console.Error.WriteLine(
                $"{name,-30} {type,-10} {status,-9} {segment.Duration.TotalMilliseconds,10:F2}  {error}");
        }

        Console.Error.WriteLine(new string('-', 82));
        Console.Error.WriteLine($"Total: {result.Duration.TotalMilliseconds:F2} ms");
    }

    private static string Truncate(string value, int maxLength) =>
        value.Length <= maxLength ? value : value[..Math.Max(0, maxLength - 1)] + "…";

    private static Task<int> PrintVersion()
    {
        var version = typeof(Program).Assembly.GetName().Version?.ToString() ?? "0.0.0";
        Console.Out.WriteLine($"ppf {version}");
        return Task.FromResult(0);
    }

    private static Task<int> PrintHelp()
    {
        PrintGeneralUsage(Console.Out);
        return Task.FromResult(0);
    }

    private static Task<int> PrintThemeUsage(TextWriter writer)
    {
        writer.WriteLine("Usage:");
        writer.WriteLine("  ppf theme import <archivo.omp.json> [--output <archivo.ppf.json>] [--name <nombre>] [--ignore-unsupported]");
        writer.WriteLine("  ppf theme validate <archivo.ppf.json> [<archivo2> ...]");
        return Task.FromResult(0);
    }

    private static int FailUnknownCommand(string command)
    {
        Console.Error.WriteLine($"ppf: unknown command '{command}'.");
        PrintGeneralUsage(Console.Error);
        return 2;
    }

    private static int FailUnknownThemeCommand(string command)
    {
        Console.Error.WriteLine($"ppf: unknown theme subcommand '{command}'.");
        PrintThemeUsage(Console.Error);
        return 2;
    }

    private static void PrintGeneralUsage(TextWriter writer)
    {
        writer.WriteLine("ppf - Pablitus Prompt Framework CLI (.NET core)");
        writer.WriteLine();
        writer.WriteLine("Usage:");
        writer.WriteLine("  ppf theme import <archivo.omp.json> [--output <archivo.ppf.json>] [--name <nombre>] [--ignore-unsupported]");
        writer.WriteLine("  ppf theme validate <archivo.ppf.json> [<archivo2> ...]");
        writer.WriteLine("  ppf render --config <archivo.ppf.json> [--cwd <ruta>] [--exit-code <n>] [--renderer plain|powerline] [--terminal-width <n>] [--transient|--tooltip <comando>] [--no-color] [--no-cache]");
        writer.WriteLine("  ppf debug --config <archivo.ppf.json> [--cwd <ruta>] [--exit-code <n>] [--renderer plain|powerline] [--terminal-width <n>] [--no-color] [--no-cache]");
        writer.WriteLine("  ppf version");
        writer.WriteLine();
        writer.WriteLine("Options:");
        writer.WriteLine("  -c, --config <ruta>      PPF configuration or theme file.");
        writer.WriteLine("  -o, --output <ruta>      Output path for 'theme import' (stdout when omitted).");
        writer.WriteLine("      --name <nombre>      Override the imported theme name.");
        writer.WriteLine("      --cwd <ruta>         Working directory used by the prompt context.");
        writer.WriteLine("      --exit-code <n>      Exit code exposed to the 'exit' segment.");
        writer.WriteLine("      --renderer <nombre>  Override the configured renderer.");
        writer.WriteLine("      --terminal-width <n> Terminal width used by right prompts and tooltips.");
        writer.WriteLine("      --transient          Render the configured transient prompt.");
        writer.WriteLine("      --tooltip <comando>  Render the tooltip matching a command.");
        writer.WriteLine("      --command-line <txt> Current command line exposed to templates.");
        writer.WriteLine("      --column <n>         Cursor column used to right-align tooltips.");
        writer.WriteLine("      --no-color           Disable ANSI escapes in the output.");
        writer.WriteLine("      --no-cache           Disable the in-memory segment cache.");
        writer.WriteLine("      --ignore-unsupported Skip unsupported Oh My Posh segments.");
        writer.WriteLine("  -h, --help               Show this help.");
    }

    private static void PrintRenderUsage(TextWriter writer)
    {
        writer.WriteLine("Usage:");
        writer.WriteLine("  ppf render --config <archivo.ppf.json> [--cwd <ruta>] [--exit-code <n>] [--renderer plain|powerline] [--terminal-width <n>] [--transient|--tooltip <comando>] [--no-color] [--no-cache]");
        writer.WriteLine("  ppf debug  --config <archivo.ppf.json> [--cwd <ruta>] [--exit-code <n>] [--renderer plain|powerline] [--terminal-width <n>] [--no-color] [--no-cache]");
    }
}
