using System.Diagnostics;
using System.Text;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Base class for segment providers that need to run an external command
/// (for example <c>kubectl</c>, <c>aws</c>, <c>node --version</c>) and parse
/// its output. Providers must not throw; they return an invisible result when
/// the command is not available or fails.
/// </summary>
public abstract class CommandSegmentProvider : TemplateSegmentProvider
{
    private static readonly Encoding OutputEncoding = new UTF8Encoding(false);

    protected CommandSegmentProvider(
        TemplateEngine templates,
        SegmentDefinition definition)
        : base(templates, definition)
    {
    }

    /// <summary>Runs <paramref name="command"/> with <paramref name="arguments"/>
    /// and returns the trimmed standard output, or <c>null</c> if the command
    /// could not be executed or timed out.</summary>
    protected static string? RunCommand(
        string command,
        IEnumerable<string> arguments,
        int timeoutMs = 5000,
        CancellationToken cancellationToken = default)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = string.Join(" ", arguments.Select(QuoteArgument)),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            StandardOutputEncoding = OutputEncoding,
            StandardErrorEncoding = OutputEncoding,
        };

        using var process = new Process { StartInfo = startInfo };
        var output = new StringBuilder();
        var error = new StringBuilder();

        process.OutputDataReceived += (_, e) =>
        {
            if (e.Data is not null)
            {
                output.AppendLine(e.Data);
            }
        };
        process.ErrorDataReceived += (_, e) =>
        {
            if (e.Data is not null)
            {
                error.AppendLine(e.Data);
            }
        };

        try
        {
            if (!process.Start())
            {
                return null;
            }

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            var waited = process.WaitForExit(timeoutMs);
            if (!waited)
            {
                try
                {
                    process.Kill();
                }
                catch
                {
                    // Ignore kill failures.
                }
                return null;
            }

            return output.Length > 0 ? output.ToString().Trim() : null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>Returns <c>true</c> when <paramref name="command"/> exists in PATH.</summary>
    protected static bool IsCommandAvailable(string command)
    {
        try
        {
            if (OperatingSystem.IsWindows())
            {
                var result = RunCommand("where", new[] { command }, 2000);
                return !string.IsNullOrEmpty(result);
            }

            var whichResult = RunCommand("which", new[] { command }, 2000);
            return !string.IsNullOrEmpty(whichResult);
        }
        catch
        {
            return false;
        }
    }

    /// <summary>Reads an environment variable, returning <c>null</c> when unset.</summary>
    protected static string? GetEnvironmentVariable(string name) =>
        Environment.GetEnvironmentVariable(name);

    /// <summary>Quotes a command argument for safe passing to a process.</summary>
    private static string QuoteArgument(string argument)
    {
        if (string.IsNullOrEmpty(argument))
        {
            return "\"\"";
        }

        if (OperatingSystem.IsWindows())
        {
            // On Windows, wrap in double quotes and escape internal double quotes.
            return $"\"{argument.Replace("\"", "\"\"")}\"";
        }

        // On Unix, wrap in single quotes and escape internal single quotes.
        return $"'{argument.Replace("'", "'\\''")}'";
    }
}
