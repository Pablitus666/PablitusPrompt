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
}
