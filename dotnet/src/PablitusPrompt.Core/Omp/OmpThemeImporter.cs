using System.Text.Json;
using PablitusPrompt.Core.Configuration;

namespace PablitusPrompt.Core.Omp;

/// <summary>
/// Imports the supported Oh My Posh theme subset into a PPF <see cref="ThemeConfig"/>.
/// Unsupported segment types are reported explicitly and never dropped silently.
/// </summary>
public sealed class OmpThemeImporter
{
    public static readonly IReadOnlyList<string> SupportedSegmentTypes = new[]
    {
        "session", "path", "git", "text", "time", "exit",
    };

    private static readonly Dictionary<string, string> DefaultTemplates =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["session"] = "{{ .UserName }}@{{ .HostName }}",
            ["path"] = "{{ .Path.Current }}",
            ["git"] = "{{ .Git.Branch }}",
            ["text"] = string.Empty,
            ["time"] = "{{ .Time }}",
            ["exit"] = "{{ if ne .ExitCode 0 }}{{ .ExitCode }}{{ end }}",
        };

    public ThemeConfig ImportFile(string path, bool ignoreUnsupportedSegments = false, string? name = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var json = File.ReadAllText(path);
        return Import(json, path, ignoreUnsupportedSegments, name);
    }

    public ThemeConfig Import(
        string json,
        string? sourceName = null,
        bool ignoreUnsupportedSegments = false,
        string? name = null)
    {
        ArgumentNullException.ThrowIfNull(json);

        JsonDocument document;
        try
        {
            document = JsonDocument.Parse(json, new JsonDocumentOptions
            {
                AllowTrailingCommas = true,
                CommentHandling = JsonCommentHandling.Skip,
            });
        }
        catch (JsonException exception)
        {
            var location = exception.LineNumber is not null
                ? $" at line {exception.LineNumber + 1}, column {exception.BytePositionInLine + 1}"
                : string.Empty;
            throw new OmpImportException(
                $"Invalid Oh My Posh JSON{location}: {exception.Message}",
                exception.Path,
                exception);
        }

        using (document)
        {
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object)
            {
                throw new OmpImportException("Oh My Posh theme root must be a JSON object.", "$");
            }

            var theme = new ThemeConfig
            {
                Schema = "https://pablitus.dev/schemas/theme.schema.json",
                Name = ResolveName(root, sourceName, name),
                Version = "1.0",
                Source = "oh-my-posh",
                Renderer = "powerline",
                FinalSpace = ReadBoolean(root, "final_space") ?? false,
                Palette = ReadPalette(root),
                TransientPrompt = ImportTransientPrompt(root),
                Tooltips = ImportTooltips(root, ignoreUnsupportedSegments),
                TooltipsAction = ReadString(root, "tooltips_action"),
            };

            if (!root.TryGetProperty("blocks", out var blocks) || blocks.ValueKind != JsonValueKind.Array)
            {
                throw new OmpImportException("Oh My Posh theme must contain a 'blocks' array.", "blocks");
            }

            var blockIndex = 0;
            foreach (var blockElement in blocks.EnumerateArray())
            {
                var blockPath = $"blocks[{blockIndex}]";
                if (blockElement.ValueKind != JsonValueKind.Object)
                {
                    throw new OmpImportException("Block must be a JSON object.", blockPath);
                }

                var block = new BlockConfig
                {
                    Type = ReadString(blockElement, "type") ?? "prompt",
                    Alignment = ReadString(blockElement, "alignment") ?? "left",
                    Newline = ReadBoolean(blockElement, "newline") ?? false,
                    Filler = ReadString(blockElement, "filler"),
                    Overflow = ReadString(blockElement, "overflow"),
                };

                if (!blockElement.TryGetProperty("segments", out var segments) ||
                    segments.ValueKind != JsonValueKind.Array)
                {
                    throw new OmpImportException("Block must contain a 'segments' array.", $"{blockPath}.segments");
                }

                var segmentIndex = 0;
                foreach (var segmentElement in segments.EnumerateArray())
                {
                    var segmentPath = $"{blockPath}.segments[{segmentIndex}]";
                    if (segmentElement.ValueKind != JsonValueKind.Object)
                    {
                        throw new OmpImportException("Segment must be a JSON object.", segmentPath);
                    }

                    var type = ReadString(segmentElement, "type");
                    if (string.IsNullOrWhiteSpace(type))
                    {
                        throw new OmpImportException("Segment 'type' is required.", $"{segmentPath}.type");
                    }

                    if (!SupportedSegmentTypes.Contains(type, StringComparer.OrdinalIgnoreCase))
                    {
                        if (ignoreUnsupportedSegments)
                        {
                            segmentIndex++;
                            continue;
                        }

                        throw new OmpImportException(
                            $"Unsupported Oh My Posh segment type '{type}'. Supported types: {string.Join(", ", SupportedSegmentTypes)}.",
                            $"{segmentPath}.type");
                    }

                    block.Segments.Add(ImportSegment(segmentElement, segmentPath, type));
                    segmentIndex++;
                }

                if (block.Segments.Count > 0)
                {
                    theme.Blocks.Add(block);
                }

                blockIndex++;
            }

            if (theme.Blocks.Count == 0)
            {
                throw new OmpImportException(
                    "Oh My Posh theme does not contain any supported segment.",
                    "blocks");
            }

            return theme;
        }
    }

    private static TransientPromptConfig? ImportTransientPrompt(JsonElement root)
    {
        if (!root.TryGetProperty("transient_prompt", out var element))
        {
            return null;
        }

        if (element.ValueKind != JsonValueKind.Object)
        {
            throw new OmpImportException(
                "Oh My Posh 'transient_prompt' must be a JSON object.",
                "transient_prompt");
        }

        return new TransientPromptConfig
        {
            Template = ReadString(element, "template") ?? "{{ .Shell }}> ",
            RightTemplate = ReadString(element, "right_template"),
            Filler = ReadString(element, "filler"),
            Newline = ReadBoolean(element, "newline") ?? false,
            Foreground = NormalizeColor(ReadString(element, "foreground")),
            Background = NormalizeColor(ReadString(element, "background")),
        };
    }

    private static List<TooltipConfig> ImportTooltips(JsonElement root, bool ignoreUnsupportedSegments)
    {
        var tooltips = new List<TooltipConfig>();
        if (!root.TryGetProperty("tooltips", out var element))
        {
            return tooltips;
        }

        if (element.ValueKind != JsonValueKind.Array)
        {
            throw new OmpImportException("Oh My Posh 'tooltips' must be a JSON array.", "tooltips");
        }

        var index = 0;
        foreach (var tooltipElement in element.EnumerateArray())
        {
            var path = $"tooltips[{index}]";
            if (tooltipElement.ValueKind != JsonValueKind.Object)
            {
                throw new OmpImportException("Tooltip must be a JSON object.", path);
            }

            var type = ReadString(tooltipElement, "type");
            if (string.IsNullOrWhiteSpace(type))
            {
                throw new OmpImportException("Tooltip 'type' is required.", $"{path}.type");
            }

            if (!SupportedSegmentTypes.Contains(type, StringComparer.OrdinalIgnoreCase))
            {
                if (ignoreUnsupportedSegments)
                {
                    index++;
                    continue;
                }

                throw new OmpImportException(
                    $"Unsupported Oh My Posh segment type '{type}'. Supported types: {string.Join(", ", SupportedSegmentTypes)}.",
                    $"{path}.type");
            }

            var segment = ImportSegment(tooltipElement, path, type);
            tooltips.Add(new TooltipConfig
            {
                Type = segment.Type,
                Name = segment.Name,
                Style = segment.Style,
                Foreground = segment.Foreground,
                Background = segment.Background,
                Icon = segment.Icon,
                Template = segment.Template,
                LeadingDiamond = segment.LeadingDiamond,
                TrailingDiamond = segment.TrailingDiamond,
                Enabled = segment.Enabled,
                TimeoutMs = segment.TimeoutMs,
                CacheTtlSeconds = segment.CacheTtlSeconds,
                Properties = segment.Properties,
                Tips = ReadStringArray(tooltipElement, "tips"),
            });
            index++;
        }

        return tooltips;
    }

    private static List<string> ReadStringArray(JsonElement element, string propertyName)
    {
        var values = new List<string>();
        if (!element.TryGetProperty(propertyName, out var array) ||
            array.ValueKind != JsonValueKind.Array)
        {
            return values;
        }

        foreach (var item in array.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                var value = item.GetString();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    values.Add(value.Trim());
                }
            }
        }

        return values;
    }

    private static SegmentConfig ImportSegment(JsonElement element, string path, string type)
    {
        var foreground = NormalizeColor(ReadString(element, "foreground"));
        var background = NormalizeColor(ReadString(element, "background"));
        var template = ReadString(element, "template");

        if (template is null && DefaultTemplates.TryGetValue(type, out var defaultTemplate))
        {
            template = defaultTemplate;
        }

        return new SegmentConfig
        {
            Type = type.ToLowerInvariant(),
            Style = MapStyle(ReadString(element, "style")),
            Foreground = foreground,
            Background = background,
            Template = template,
            LeadingDiamond = ReadString(element, "leading_diamond"),
            TrailingDiamond = ReadString(element, "trailing_diamond"),
            Properties = ReadProperties(element, $"{path}.properties"),
        };
    }

    private static string MapStyle(string? style)
    {
        if (string.IsNullOrWhiteSpace(style))
        {
            return "plain";
        }

        return style.Trim().ToLowerInvariant() switch
        {
            "plain" => "plain",
            "powerline" => "powerline",
            "diamond" => "diamond",
            "accordion" => "accordion",
            "minimal" => "plain",
            _ => "plain",
        };
    }

    private static string? NormalizeColor(string? color)
    {
        if (string.IsNullOrWhiteSpace(color))
        {
            return null;
        }

        var value = color.Trim();
        if (value.Equals("transparent", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        // Oh My Posh palette references use the p: prefix.
        if (value.StartsWith("p:", StringComparison.OrdinalIgnoreCase))
        {
            value = value[2..];
        }

        return value;
    }

    private static Dictionary<string, string> ReadPalette(JsonElement root)
    {
        var palette = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (!root.TryGetProperty("palette", out var paletteElement) ||
            paletteElement.ValueKind != JsonValueKind.Object)
        {
            return palette;
        }

        foreach (var property in paletteElement.EnumerateObject())
        {
            if (property.Value.ValueKind == JsonValueKind.String)
            {
                palette[property.Name] = property.Value.GetString() ?? string.Empty;
            }
            else if (property.Value.ValueKind == JsonValueKind.Object &&
                     property.Name.Equals("colors", StringComparison.OrdinalIgnoreCase))
            {
                foreach (var color in property.Value.EnumerateObject())
                {
                    if (color.Value.ValueKind == JsonValueKind.String)
                    {
                        palette[color.Name] = color.Value.GetString() ?? string.Empty;
                    }
                }
            }
        }

        return palette;
    }

    private static Dictionary<string, object?> ReadProperties(JsonElement element, string path)
    {
        var properties = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        if (!element.TryGetProperty("properties", out var propertiesElement))
        {
            return properties;
        }

        if (propertiesElement.ValueKind != JsonValueKind.Object)
        {
            throw new OmpImportException("Segment 'properties' must be a JSON object.", path);
        }

        foreach (var property in propertiesElement.EnumerateObject())
        {
            properties[property.Name] = ConvertElement(property.Value);
        }

        return properties;
    }

    private static object? ConvertElement(JsonElement element) =>
        element.ValueKind switch
        {
            JsonValueKind.String => element.GetString(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            JsonValueKind.Number => element.TryGetInt64(out var integer) ? integer : element.GetDecimal(),
            JsonValueKind.Array => element.EnumerateArray().Select(ConvertElement).ToList(),
            JsonValueKind.Object => element.EnumerateObject()
                .ToDictionary(property => property.Name, property => ConvertElement(property.Value)),
            _ => element.GetRawText(),
        };

    private static string ResolveName(JsonElement root, string? sourceName, string? explicitName)
    {
        if (!string.IsNullOrWhiteSpace(explicitName))
        {
            return explicitName.Trim();
        }

        var rootName = ReadString(root, "name");
        if (!string.IsNullOrWhiteSpace(rootName))
        {
            return rootName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(sourceName))
        {
            var fileName = Path.GetFileName(sourceName);
            if (fileName.EndsWith(".omp.json", StringComparison.OrdinalIgnoreCase))
            {
                return fileName[..^".omp.json".Length];
            }

            return Path.GetFileNameWithoutExtension(fileName);
        }

        return "imported";
    }

    private static string? ReadString(JsonElement element, string propertyName) =>
        element.TryGetProperty(propertyName, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static bool? ReadBoolean(JsonElement element, string propertyName) =>
        element.TryGetProperty(propertyName, out var value)
            ? value.ValueKind switch
            {
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                _ => null,
            }
            : null;
}
