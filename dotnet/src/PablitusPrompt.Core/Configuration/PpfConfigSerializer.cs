using System.Text;
using System.Text.Json;

namespace PablitusPrompt.Core.Configuration;

public enum PpfDocumentKind
{
    Config,
    Theme,
}

/// <summary>
/// Loads and saves PPF documents. Validation is always performed before a
/// document is returned, so callers never receive an invalid configuration.
/// </summary>
public static class PpfConfigSerializer
{
    public static PpfConfig LoadConfig(string path)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var json = File.ReadAllText(path);
        return LoadConfigFromJson(json, path);
    }

    public static PpfConfig LoadConfigFromJson(string json, string? source = null)
    {
        ArgumentNullException.ThrowIfNull(json);

        var config = Deserialize<PpfConfig>(json, source);
        if (config is null)
        {
            throw new PpfConfigurationException(
                $"Invalid PPF configuration{(source is null ? string.Empty : $" in '{source}'")}: document is empty.",
                source: source);
        }

        var errors = PpfConfigValidator.Validate(config);
        if (errors.Count > 0)
        {
            throw PpfConfigurationException.FromErrors(source, errors);
        }

        return config;
    }

    public static ThemeConfig LoadTheme(string path)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var json = File.ReadAllText(path);
        return LoadThemeFromJson(json, path);
    }

    public static ThemeConfig LoadThemeFromJson(string json, string? source = null)
    {
        ArgumentNullException.ThrowIfNull(json);

        var theme = Deserialize<ThemeConfig>(json, source);
        if (theme is null)
        {
            throw new PpfConfigurationException(
                $"Invalid PPF theme{(source is null ? string.Empty : $" in '{source}'")}: document is empty.",
                source: source);
        }

        var errors = PpfConfigValidator.ValidateTheme(theme);
        if (errors.Count > 0)
        {
            throw PpfConfigurationException.FromErrors(source, errors);
        }

        return theme;
    }

    public static string SerializeConfig(PpfConfig config)
    {
        ArgumentNullException.ThrowIfNull(config);
        return JsonSerializer.Serialize(config, PpfJson.Options);
    }

    public static string SerializeTheme(ThemeConfig theme)
    {
        ArgumentNullException.ThrowIfNull(theme);
        return JsonSerializer.Serialize(theme, PpfJson.Options);
    }

    public static void SaveConfig(PpfConfig config, string path)
    {
        ArgumentNullException.ThrowIfNull(config);
        WriteFile(path, SerializeConfig(config));
    }

    public static void SaveTheme(ThemeConfig theme, string path)
    {
        ArgumentNullException.ThrowIfNull(theme);
        WriteFile(path, SerializeTheme(theme));
    }

    public static PpfDocumentKind DetectDocumentKind(string json)
    {
        ArgumentNullException.ThrowIfNull(json);

        using var document = JsonDocument.Parse(json, new JsonDocumentOptions
        {
            AllowTrailingCommas = true,
            CommentHandling = JsonCommentHandling.Skip,
        });

        var root = document.RootElement;
        if (root.ValueKind != JsonValueKind.Object)
        {
            return PpfDocumentKind.Config;
        }

        if (root.TryGetProperty("theme", out _))
        {
            return PpfDocumentKind.Config;
        }

        if (root.TryGetProperty("$schema", out var schema) &&
            schema.ValueKind == JsonValueKind.String)
        {
            var schemaValue = schema.GetString() ?? string.Empty;
            if (schemaValue.Contains("theme.schema", StringComparison.OrdinalIgnoreCase))
            {
                return PpfDocumentKind.Theme;
            }

            if (schemaValue.Contains("ppf.schema", StringComparison.OrdinalIgnoreCase))
            {
                return PpfDocumentKind.Config;
            }
        }

        if (root.TryGetProperty("blocks", out _) && root.TryGetProperty("name", out _))
        {
            return PpfDocumentKind.Theme;
        }

        if (root.TryGetProperty("renderer", out _) ||
            root.TryGetProperty("cache", out _) ||
            root.TryGetProperty("template", out _))
        {
            return PpfDocumentKind.Config;
        }

        return PpfDocumentKind.Config;
    }

    private static T? Deserialize<T>(string json, string? source)
    {
        try
        {
            return JsonSerializer.Deserialize<T>(json, PpfJson.Options);
        }
        catch (JsonException exception)
        {
            var path = string.IsNullOrWhiteSpace(exception.Path) ? "$" : exception.Path!;
            var location = exception.LineNumber is not null
                ? $" at line {exception.LineNumber + 1}, column {exception.BytePositionInLine + 1}"
                : string.Empty;
            var error = new ConfigValidationError(path, $"{exception.Message}{location}");
            throw PpfConfigurationException.FromErrors(source, new[] { error });
        }
        catch (NotSupportedException exception)
        {
            var error = new ConfigValidationError("$", exception.Message);
            throw PpfConfigurationException.FromErrors(source, new[] { error });
        }
    }

    private static void WriteFile(string path, string content)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var directory = Path.GetDirectoryName(Path.GetFullPath(path));
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        File.WriteAllText(path, content + Environment.NewLine, new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
    }
}
