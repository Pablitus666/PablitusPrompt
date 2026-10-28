using System.Globalization;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Segment for battery status. On Windows it reads the battery state via
/// WMI/CIM (<c>Win32_Battery</c>). On Linux it reads
/// <c>/sys/class/power_supply/*</c>. Inspired by the Oh My Posh
/// <c>battery</c> segment.
/// </summary>
public sealed class BatterySegmentProvider : TemplateSegmentProvider
{
    private readonly TemplateEngine _templates;

    public BatterySegmentProvider(TemplateEngine templates)
        : base(templates, new SegmentDefinition
        {
            Type = "battery",
            DisplayName = "Battery",
            DefaultTemplate = "{{ if .Charging }}⚡{{ else }}🔋{{ end }} {{ .Percent }}%",
            DefaultTimeoutMs = 2000,
        })
    {
        _templates = templates;
    }

    public override Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);
        cancellationToken.ThrowIfCancellationRequested();

        var battery = ReadBattery();
        if (battery is null)
        {
            return Task.FromResult(SegmentResult.ErrorResult(
                segment, SegmentStatus.Skipped, "Battery information is not available on this system."));
        }

        var contextData = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
        {
            ["Percent"] = battery.Percent,
            ["Charging"] = battery.Charging,
        };

        var template = GetTemplate(segment);
        var text = string.IsNullOrEmpty(template)
            ? string.Empty
            : _templates.Render(template, contextData);

        return Task.FromResult(new SegmentResult
        {
            Name = segment.Name,
            Type = segment.Type,
            Text = text,
            Icon = segment.Icon,
            Foreground = segment.Foreground,
            Background = segment.Background,
            Style = segment.Style,
            LeadingDiamond = segment.LeadingDiamond,
            TrailingDiamond = segment.TrailingDiamond,
            Visible = !string.IsNullOrWhiteSpace(text),
            Status = SegmentStatus.Success,
        });
    }

    private sealed record BatteryInfo(int Percent, bool Charging);

    private static BatteryInfo? ReadBattery()
    {
        if (OperatingSystem.IsWindows())
        {
            return ReadBatteryWindows();
        }

        if (OperatingSystem.IsLinux())
        {
            return ReadBatteryLinux();
        }

        if (OperatingSystem.IsMacOS())
        {
            return ReadBatteryMacOS();
        }

        return null;
    }

    private static BatteryInfo? ReadBatteryWindows()
    {
        try
        {
            using var searcher = new System.Management.ManagementObjectSearcher(
                "SELECT EstimatedChargeRemaining, BatteryStatus FROM Win32_Battery");
            var collection = searcher.Get();

            foreach (var item in collection.Cast<System.Management.ManagementObject>())
            {
                var percentValue = item["EstimatedChargeRemaining"];
                var statusValue = item["BatteryStatus"];

                int percent = 0;
                if (percentValue is not null && int.TryParse(percentValue.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsedPercent))
                {
                    percent = parsedPercent;
                }

                bool charging = false;
                if (statusValue is not null)
                {
                    var statusText = statusValue.ToString();
                    if (int.TryParse(statusText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var statusCode))
                    {
                        charging = statusCode is 2 or 6 or 7 or 8 or 10;
                    }
                    else
                    {
                        charging = string.Equals(statusText, "2", StringComparison.OrdinalIgnoreCase)
                            || string.Equals(statusText, "6", StringComparison.OrdinalIgnoreCase)
                            || string.Equals(statusText, "7", StringComparison.OrdinalIgnoreCase)
                            || string.Equals(statusText, "8", StringComparison.OrdinalIgnoreCase)
                            || string.Equals(statusText, "10", StringComparison.OrdinalIgnoreCase);
                    }
                }

                return new BatteryInfo(percent, charging);
            }
        }
        catch
        {
            // WMI may not be available or accessible; fall through.
        }

        return null;
    }

    private static BatteryInfo? ReadBatteryLinux()
    {
        try
        {
            var powerSupplyDir = new DirectoryInfo("/sys/class/power_supply");
            if (!powerSupplyDir.Exists)
            {
                return null;
            }

            int totalPercent = 0;
            bool anyCharging = false;
            int count = 0;

            foreach (var supply in powerSupplyDir.GetDirectories())
            {
                var typeFile = Path.Combine(supply.FullName, "type");
                if (File.Exists(typeFile))
                {
                    var type = File.ReadAllText(typeFile).Trim();
                    if (!string.Equals(type, "Battery", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                }

                var capacityFile = Path.Combine(supply.FullName, "capacity");
                var statusFile = Path.Combine(supply.FullName, "status");

                int percent = 0;
                if (File.Exists(capacityFile))
                {
                    var capacityText = File.ReadAllText(capacityFile).Trim();
                    if (int.TryParse(capacityText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsedCapacity))
                    {
                        percent = parsedCapacity;
                    }
                }

                bool charging = false;
                if (File.Exists(statusFile))
                {
                    var status = File.ReadAllText(statusFile).Trim();
                    charging = string.Equals(status, "Charging", StringComparison.OrdinalIgnoreCase)
                        || string.Equals(status, "Unknown", StringComparison.OrdinalIgnoreCase);
                }

                totalPercent += percent;
                if (charging)
                {
                    anyCharging = true;
                }
                count++;
            }

            if (count == 0)
            {
                return null;
            }

            return new BatteryInfo(totalPercent / count, anyCharging);
        }
        catch
        {
            return null;
        }
    }

    private static BatteryInfo? ReadBatteryMacOS()
    {
        try
        {
            // Use pmset to get battery information on macOS
            var output = RunProcess("pmset", new[] { "-g", "batt" }, 5000);
            if (string.IsNullOrEmpty(output))
            {
                return null;
            }

            // Example output:
            // Now drawing from 'AC Power'
            // -InternalBattery-0   87%; charging; 0:00 remaining present: true
            var lines = output.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (!trimmed.StartsWith("-InternalBattery", StringComparison.Ordinal) &&
                    !trimmed.StartsWith("-", StringComparison.Ordinal))
                {
                    continue;
                }

                // Parse percentage
                int percent = 0;
                var percentMatch = System.Text.RegularExpressions.Regex.Match(trimmed, @"(\d+)%");
                if (percentMatch.Success && int.TryParse(percentMatch.Groups[1].Value, out var parsedPercent))
                {
                    percent = parsedPercent;
                }

                // Parse charging status
                bool charging = trimmed.Contains("charging", StringComparison.OrdinalIgnoreCase) ||
                                trimmed.Contains("AC Power", StringComparison.OrdinalIgnoreCase);

                return new BatteryInfo(percent, charging);
            }

            return null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>Runs an external command and returns its trimmed standard output.</summary>
    private static string? RunProcess(string command, IEnumerable<string> arguments, int timeoutMs)
    {
        var startInfo = new System.Diagnostics.ProcessStartInfo
        {
            FileName = command,
            Arguments = string.Join(" ", arguments.Select(QuoteArgument)),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        using var process = new System.Diagnostics.Process { StartInfo = startInfo };
        var output = new System.Text.StringBuilder();
        var outputCompleted = new System.Threading.Tasks.TaskCompletionSource<bool>();

        process.OutputDataReceived += (_, e) =>
        {
            if (e.Data is not null)
            {
                output.AppendLine(e.Data);
            }
            else
            {
                outputCompleted.TrySetResult(true);
            }
        };

        try
        {
            if (!process.Start())
            {
                return null;
            }

            process.BeginOutputReadLine();

            var waited = process.WaitForExit(timeoutMs);
            if (!waited)
            {
                try { process.Kill(); } catch { }
                return null;
            }

            outputCompleted.TrySetResult(true);
            return output.Length > 0 ? output.ToString().Trim() : null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>Quotes a command argument for safe passing to a process.</summary>
    private static string QuoteArgument(string argument)
    {
        if (string.IsNullOrEmpty(argument))
        {
            return "\"\"";
        }

        if (OperatingSystem.IsWindows())
        {
            return $"\"{argument.Replace("\"", "\"\"")}\"";
        }

        return $"'{argument.Replace("'", "'\\''")}'";
    }
}
