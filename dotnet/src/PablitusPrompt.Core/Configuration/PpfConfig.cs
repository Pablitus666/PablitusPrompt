using System.Text.Json;
using System.Text.Json.Serialization;

namespace PablitusPrompt.Core.Configuration;

/// <summary>
/// Root document for a PPF configuration. A configuration can either embed a
/// theme or declare blocks directly; both shapes are accepted so a theme file can
/// also be rendered from the CLI without an adapter document.
/// </summary>
public sealed class PpfConfig
{
    [JsonPropertyName("$schema")]
    public string? Schema { get; set; }

    public string? Version { get; set; } = "1.0";

    /// <summary>Renderer name: <c>plain</c> or <c>powerline</c>.</summary>
    public string Renderer { get; set; } = "plain";

    /// <summary>Appends a trailing space after the prompt when true.</summary>
    public bool? FinalSpace { get; set; }

    public CacheConfig? Cache { get; set; }

    public TemplateConfig? Template { get; set; }

    /// <summary>Replacement prompt rendered when the previous line is submitted.</summary>
    public TransientPromptConfig? TransientPrompt { get; set; }

    /// <summary>Segments shown while the user types a matching command.</summary>
    public List<TooltipConfig> Tooltips { get; set; } = new();

    /// <summary><c>replace</c>, <c>extend</c> or <c>prepend</c> relative to the right prompt.</summary>
    public string? TooltipsAction { get; set; }

    /// <summary>Embedded theme. When present it owns the blocks.</summary>
    public ThemeConfig? Theme { get; set; }

    /// <summary>Blocks declared directly at the document root.</summary>
    public List<BlockConfig> Blocks { get; set; } = new();
}

public sealed class ThemeConfig
{
    [JsonPropertyName("$schema")]
    public string? Schema { get; set; }

    public string? Name { get; set; }

    public string? Version { get; set; } = "1.0";

    /// <summary>Optional source label, for example <c>oh-my-posh</c>.</summary>
    public string? Source { get; set; }

    /// <summary>Default renderer suggested by the theme (optional).</summary>
    public string? Renderer { get; set; }

    public bool? FinalSpace { get; set; }

    public string? DefaultStyle { get; set; }

    public Dictionary<string, string> Palette { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    public TemplateConfig? Template { get; set; }

    public TransientPromptConfig? TransientPrompt { get; set; }

    public List<TooltipConfig> Tooltips { get; set; } = new();

    public string? TooltipsAction { get; set; }

    public List<BlockConfig> Blocks { get; set; } = new();
}

public sealed class BlockConfig
{
    public string Type { get; set; } = "prompt";

    public string Alignment { get; set; } = "left";

    public bool Newline { get; set; }

    /// <summary>Text repeated to connect the left and right-aligned blocks.</summary>
    public string? Filler { get; set; }

    /// <summary>Right block behavior on overflow: <c>hide</c> or <c>break</c>.</summary>
    public string? Overflow { get; set; }

    public List<SegmentConfig> Segments { get; set; } = new();
}

public class SegmentConfig
{
    public string Type { get; set; } = string.Empty;

    /// <summary>Optional unique name. Generated when missing.</summary>
    public string? Name { get; set; }

    public string Style { get; set; } = "plain";

    public string? Foreground { get; set; }

    public string? Background { get; set; }

    public string? Icon { get; set; }

    public string? Template { get; set; }

    public string? LeadingDiamond { get; set; }

    public string? TrailingDiamond { get; set; }

    public bool Enabled { get; set; } = true;

    /// <summary>Per-segment timeout in milliseconds. Overrides the scheduler default.</summary>
    public int? TimeoutMs { get; set; }

    /// <summary>Optional cache TTL in seconds (reserved for the scheduler cache).</summary>
    public int? CacheTtlSeconds { get; set; }

    public Dictionary<string, object?> Properties { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public sealed class CacheConfig
{
    public bool Enabled { get; set; }

    public int TtlSeconds { get; set; } = 30;

    public int MaxEntries { get; set; } = 256;

    public string? Directory { get; set; }
}

public sealed class TemplateConfig
{
    public string? Prompt { get; set; }

    public string? RightPrompt { get; set; }

    public string? TransientPrompt { get; set; }
}

/// <summary>
/// Replacement prompt shown after a command is accepted. It mirrors the Oh My
/// Posh transient prompt shape so imported themes do not lose information.
/// </summary>
public sealed class TransientPromptConfig
{
    public string? Template { get; set; } = "{{ .Shell }}> ";

    public string? RightTemplate { get; set; }

    public string? Filler { get; set; }

    public bool Newline { get; set; }

    public string? Foreground { get; set; }

    public string? Background { get; set; }
}

/// <summary>A regular segment plus the command keywords that activate it.</summary>
public sealed class TooltipConfig : SegmentConfig
{
    public List<string> Tips { get; set; } = new();
}
