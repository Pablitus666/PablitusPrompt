using PablitusPrompt.Core.Segments;

namespace PablitusPrompt.Core.Rendering;

/// <summary>Renderer input. It contains no console state, so output is deterministic.</summary>
public sealed class PromptRenderModel
{
    public IReadOnlyList<PromptRenderBlock> Blocks { get; init; } = Array.Empty<PromptRenderBlock>();

    public bool FinalSpace { get; init; } = true;

    public bool UseAnsi { get; init; } = true;

    public IReadOnlyDictionary<string, string> Palette { get; init; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    public string Separator { get; init; } = "\uE0B0";

    /// <summary>Terminal width in columns. Zero leaves right-aligned blocks separate.</summary>
    public int TerminalWidth { get; init; }
}

public sealed class PromptRenderBlock
{
    public IReadOnlyList<SegmentResult> Segments { get; init; } = Array.Empty<SegmentResult>();

    public bool Newline { get; init; }

    public string Alignment { get; init; } = "left";

    public string Type { get; init; } = "prompt";

    public string? Filler { get; init; }

    public string? Overflow { get; init; }

    public bool IsRightAligned =>
        Type.Equals("rprompt", StringComparison.OrdinalIgnoreCase) ||
        Alignment.Equals("right", StringComparison.OrdinalIgnoreCase);
}

public interface IRenderer
{
    string Render(PromptRenderModel model);
}
