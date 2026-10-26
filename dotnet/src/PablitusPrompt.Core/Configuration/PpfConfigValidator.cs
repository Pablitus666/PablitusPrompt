using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core.Configuration;

/// <summary>
/// Semantic validation performed after JSON deserialization. Errors always carry
/// the JSON path of the offending field (for example
/// <c>theme.blocks[0].segments[1].template</c>).
/// </summary>
public static class PpfConfigValidator
{
    private static readonly TemplateEngine TemplateValidatorEngine = new();

    private static readonly HashSet<string> RendererNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "plain", "powerline",
    };

    private static readonly HashSet<string> Styles = new(StringComparer.OrdinalIgnoreCase)
    {
        "plain", "powerline", "diamond", "accordion", "minimal",
    };

    private static readonly HashSet<string> BlockTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "prompt", "rprompt",
    };

    private static readonly HashSet<string> Alignments = new(StringComparer.OrdinalIgnoreCase)
    {
        "left", "right",
    };

    private static readonly HashSet<string> OverflowModes = new(StringComparer.OrdinalIgnoreCase)
    {
        "hide", "break",
    };

    private static readonly HashSet<string> TooltipsActions = new(StringComparer.OrdinalIgnoreCase)
    {
        "replace", "extend", "prepend",
    };

    public static IReadOnlyList<string> SupportedRenderers => RendererNames.ToArray();

    public static IReadOnlyList<string> SupportedStyles => Styles.ToArray();

    public static IReadOnlyList<ConfigValidationError> Validate(PpfConfig config)
    {
        ArgumentNullException.ThrowIfNull(config);

        var errors = new List<ConfigValidationError>();

        if (!string.IsNullOrWhiteSpace(config.Version) &&
            !VersionPattern.IsMatch(config.Version))
        {
            errors.Add(new ConfigValidationError("version", "must be a dotted numeric version such as '1.0'."));
        }

        if (!RendererNames.Contains(config.Renderer ?? string.Empty))
        {
            errors.Add(new ConfigValidationError(
                "renderer",
                $"'{config.Renderer}' is not a supported renderer. Expected one of: {string.Join(", ", RendererNames)}."));
        }

        ValidateCache(config.Cache, "cache", errors);
        ValidateTemplateConfig(config.Template, "template", errors);
        ValidateTransientPrompt(config.TransientPrompt, "transientPrompt", errors);
        ValidateTooltipsAction(config.TooltipsAction, "tooltipsAction", errors);

        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        ValidateTooltips(config.Tooltips, "tooltips", names, errors);

        if (config.Theme is not null)
        {
            ValidateThemeCore(config.Theme, "theme", errors, names);
        }
        else if (config.Blocks.Count == 0)
        {
            errors.Add(new ConfigValidationError(
                "theme",
                "configuration must define 'theme.blocks' or top-level 'blocks'."));
        }
        else
        {
            ValidateBlocks(config.Blocks, "blocks", names, errors);
        }

        return errors;
    }

    public static IReadOnlyList<ConfigValidationError> ValidateTheme(ThemeConfig theme)
    {
        ArgumentNullException.ThrowIfNull(theme);
        var errors = new List<ConfigValidationError>();
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        ValidateThemeCore(theme, string.Empty, errors, names);
        return errors;
    }

    private static void ValidateThemeCore(
        ThemeConfig theme,
        string prefix,
        List<ConfigValidationError> errors,
        HashSet<string> names)
    {
        if (!string.IsNullOrWhiteSpace(theme.Renderer) && !RendererNames.Contains(theme.Renderer))
        {
            errors.Add(new ConfigValidationError(
                Path(prefix, "renderer"),
                $"'{theme.Renderer}' is not a supported renderer. Expected one of: {string.Join(", ", RendererNames)}."));
        }

        if (!string.IsNullOrWhiteSpace(theme.DefaultStyle) && !Styles.Contains(theme.DefaultStyle))
        {
            errors.Add(new ConfigValidationError(
                Path(prefix, "defaultStyle"),
                $"'{theme.DefaultStyle}' is not a supported style. Expected one of: {string.Join(", ", Styles)}."));
        }

        ValidatePalette(theme.Palette, Path(prefix, "palette"), errors);
        ValidateTemplateConfig(theme.Template, Path(prefix, "template"), errors);
        ValidateTransientPrompt(theme.TransientPrompt, Path(prefix, "transientPrompt"), errors);
        ValidateTooltipsAction(theme.TooltipsAction, Path(prefix, "tooltipsAction"), errors);
        ValidateBlocks(theme.Blocks, Path(prefix, "blocks"), names, errors);
        ValidateTooltips(theme.Tooltips, Path(prefix, "tooltips"), names, errors);
    }

    private static void ValidatePalette(
        Dictionary<string, string>? palette,
        string path,
        List<ConfigValidationError> errors)
    {
        if (palette is null)
        {
            return;
        }

        foreach (var pair in palette)
        {
            if (string.IsNullOrWhiteSpace(pair.Key))
            {
                errors.Add(new ConfigValidationError(path, "palette keys must not be empty."));
                continue;
            }

            if (!ColorReferenceValidator.IsValid(pair.Value))
            {
                errors.Add(new ConfigValidationError(
                    Path(path, pair.Key),
                    $"'{pair.Value}' is not a valid hex color, ANSI color name or palette reference."));
            }
        }
    }

    private static void ValidateBlocks(
        List<BlockConfig>? blocks,
        string path,
        HashSet<string> names,
        List<ConfigValidationError> errors)
    {
        if (blocks is null || blocks.Count == 0)
        {
            errors.Add(new ConfigValidationError(path, "must contain at least one block."));
            return;
        }

        var hasRightPrompt = false;

        for (var blockIndex = 0; blockIndex < blocks.Count; blockIndex++)
        {
            var block = blocks[blockIndex];
            var blockPath = $"{path}[{blockIndex}]";

            if (block is null)
            {
                errors.Add(new ConfigValidationError(blockPath, "block must not be null."));
                continue;
            }

            if (string.IsNullOrWhiteSpace(block.Type) || !BlockTypes.Contains(block.Type))
            {
                errors.Add(new ConfigValidationError(
                    Path(blockPath, "type"),
                    $"'{block.Type}' is not a supported block type. Expected 'prompt' or 'rprompt'."));
            }
            else if (block.Type.Equals("rprompt", StringComparison.OrdinalIgnoreCase))
            {
                if (hasRightPrompt)
                {
                    errors.Add(new ConfigValidationError(
                        Path(blockPath, "type"),
                        "only one 'rprompt' block is permitted."));
                }

                hasRightPrompt = true;
            }

            if (string.IsNullOrWhiteSpace(block.Alignment) || !Alignments.Contains(block.Alignment))
            {
                errors.Add(new ConfigValidationError(
                    Path(blockPath, "alignment"),
                    $"'{block.Alignment}' is not a supported alignment. Expected 'left' or 'right'."));
            }

            if (!string.IsNullOrWhiteSpace(block.Overflow) && !OverflowModes.Contains(block.Overflow))
            {
                errors.Add(new ConfigValidationError(
                    Path(blockPath, "overflow"),
                    $"'{block.Overflow}' is not a supported overflow mode. Expected 'hide' or 'break'."));
            }

            ValidateTemplate(block.Filler, Path(blockPath, "filler"), errors);

            if (block.Segments is null || block.Segments.Count == 0)
            {
                errors.Add(new ConfigValidationError(
                    Path(blockPath, "segments"),
                    "must contain at least one segment."));
                continue;
            }

            for (var segmentIndex = 0; segmentIndex < block.Segments.Count; segmentIndex++)
            {
                ValidateSegment(
                    block.Segments[segmentIndex],
                    $"{blockPath}.segments[{segmentIndex}]",
                    names,
                    errors);
            }
        }
    }

    private static void ValidateSegment(
        SegmentConfig? segment,
        string path,
        HashSet<string> names,
        List<ConfigValidationError> errors)
    {
        if (segment is null)
        {
            errors.Add(new ConfigValidationError(path, "segment must not be null."));
            return;
        }

        if (string.IsNullOrWhiteSpace(segment.Type))
        {
            errors.Add(new ConfigValidationError(Path(path, "type"), "segment type is required."));
        }

        if (!string.IsNullOrWhiteSpace(segment.Name) && !names.Add(segment.Name))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "name"),
                $"duplicate segment name '{segment.Name}'."));
        }

        if (!string.IsNullOrWhiteSpace(segment.Style) && !Styles.Contains(segment.Style))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "style"),
                $"'{segment.Style}' is not a supported style. Expected one of: {string.Join(", ", Styles)}."));
        }

        if (!ColorReferenceValidator.IsValid(segment.Foreground))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "foreground"),
                $"'{segment.Foreground}' is not a valid hex color, ANSI color name or palette reference."));
        }

        if (!ColorReferenceValidator.IsValid(segment.Background))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "background"),
                $"'{segment.Background}' is not a valid hex color, ANSI color name or palette reference."));
        }

        if (segment.TimeoutMs is <= 0)
        {
            errors.Add(new ConfigValidationError(
                Path(path, "timeoutMs"),
                "timeoutMs must be greater than zero when specified."));
        }

        if (segment.CacheTtlSeconds is < 0)
        {
            errors.Add(new ConfigValidationError(
                Path(path, "cacheTtlSeconds"),
                "cacheTtlSeconds must be zero or greater."));
        }

        ValidateTemplate(segment.Template, Path(path, "template"), errors);
    }

    private static void ValidateCache(CacheConfig? cache, string path, List<ConfigValidationError> errors)
    {
        if (cache is null)
        {
            return;
        }

        if (cache.TtlSeconds < 0)
        {
            errors.Add(new ConfigValidationError(Path(path, "ttlSeconds"), "ttlSeconds must be zero or greater."));
        }

        if (cache.MaxEntries <= 0)
        {
            errors.Add(new ConfigValidationError(Path(path, "maxEntries"), "maxEntries must be greater than zero."));
        }
    }

    private static void ValidateTransientPrompt(
        TransientPromptConfig? transient,
        string path,
        List<ConfigValidationError> errors)
    {
        if (transient is null)
        {
            return;
        }

        ValidateTemplate(transient.Template, Path(path, "template"), errors);
        ValidateTemplate(transient.RightTemplate, Path(path, "rightTemplate"), errors);
        ValidateTemplate(transient.Filler, Path(path, "filler"), errors);

        if (!ColorReferenceValidator.IsValid(transient.Foreground))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "foreground"),
                $"'{transient.Foreground}' is not a valid hex color, ANSI color name or palette reference."));
        }

        if (!ColorReferenceValidator.IsValid(transient.Background))
        {
            errors.Add(new ConfigValidationError(
                Path(path, "background"),
                $"'{transient.Background}' is not a valid hex color, ANSI color name or palette reference."));
        }
    }

    private static void ValidateTooltips(
        List<TooltipConfig>? tooltips,
        string path,
        HashSet<string> names,
        List<ConfigValidationError> errors)
    {
        if (tooltips is null || tooltips.Count == 0)
        {
            return;
        }

        for (var index = 0; index < tooltips.Count; index++)
        {
            var tooltip = tooltips[index];
            var tooltipPath = $"{path}[{index}]";
            if (tooltip is null)
            {
                errors.Add(new ConfigValidationError(tooltipPath, "tooltip must not be null."));
                continue;
            }

            if (tooltip.Tips is null || tooltip.Tips.Count == 0)
            {
                errors.Add(new ConfigValidationError(
                    Path(tooltipPath, "tips"),
                    "tooltip must define at least one command tip."));
            }
            else
            {
                for (var tipIndex = 0; tipIndex < tooltip.Tips.Count; tipIndex++)
                {
                    var tip = tooltip.Tips[tipIndex];
                    if (string.IsNullOrWhiteSpace(tip))
                    {
                        errors.Add(new ConfigValidationError(
                            $"{tooltipPath}.tips[{tipIndex}]",
                            "tip must not be empty."));
                    }
                    else if (tip.Any(char.IsWhiteSpace))
                    {
                        errors.Add(new ConfigValidationError(
                            $"{tooltipPath}.tips[{tipIndex}]",
                            "tip must not contain whitespace; it is matched against the first command word."));
                    }
                }
            }

            ValidateSegment(tooltip, tooltipPath, names, errors);
        }
    }

    private static void ValidateTooltipsAction(
        string? action,
        string path,
        List<ConfigValidationError> errors)
    {
        if (string.IsNullOrWhiteSpace(action) || TooltipsActions.Contains(action))
        {
            return;
        }

        errors.Add(new ConfigValidationError(
            path,
            $"'{action}' is not a supported tooltips action. Expected one of: {string.Join(", ", TooltipsActions)}."));
    }

    private static void ValidateTemplateConfig(
        TemplateConfig? template,
        string path,
        List<ConfigValidationError> errors)
    {
        if (template is null)
        {
            return;
        }

        ValidateTemplate(template.Prompt, Path(path, "prompt"), errors);
        ValidateTemplate(template.RightPrompt, Path(path, "rightPrompt"), errors);
        ValidateTemplate(template.TransientPrompt, Path(path, "transientPrompt"), errors);
    }

    private static void ValidateTemplate(string? template, string path, List<ConfigValidationError> errors)
    {
        if (string.IsNullOrEmpty(template))
        {
            return;
        }

        try
        {
            _ = TemplateValidatorEngine.Compile(template);
        }
        catch (TemplateParseException exception)
        {
            errors.Add(new ConfigValidationError(path, exception.Message));
        }
    }

    private static string Path(string prefix, string member) =>
        string.IsNullOrEmpty(prefix) ? member : $"{prefix}.{member}";

    private static readonly System.Text.RegularExpressions.Regex VersionPattern = new(
        @"^\d+(\.\d+){0,3}$",
        System.Text.RegularExpressions.RegexOptions.Compiled | System.Text.RegularExpressions.RegexOptions.CultureInvariant);
}
