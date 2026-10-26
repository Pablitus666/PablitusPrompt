using System.Text;

namespace PablitusPrompt.Core.Rendering;

/// <summary>
/// Plain text renderer. It keeps foreground/background colors but adds no
/// PowerLine glyphs, padding or separators.
/// </summary>
public sealed class PlainRenderer : IRenderer
{
    public string Render(PromptRenderModel model)
    {
        ArgumentNullException.ThrowIfNull(model);
        var resolver = new ColorResolver(model.Palette);
        var builder = new StringBuilder();
        var firstBlock = true;

        foreach (var block in model.Blocks)
        {
            var visible = block.Segments.Where(segment => segment.IsVisible).ToArray();
            if (visible.Length == 0)
            {
                continue;
            }

            if (!firstBlock && block.Newline)
            {
                builder.Append('\n');
            }

            foreach (var segment in visible)
            {
                AppendSegment(builder, segment, resolver, model.UseAnsi);
            }

            firstBlock = false;
        }

        if (model.FinalSpace)
        {
            builder.Append(' ');
        }

        return builder.ToString();
    }

    private static void AppendSegment(
        StringBuilder builder,
        Segments.SegmentResult segment,
        ColorResolver resolver,
        bool useAnsi)
    {
        var text = string.IsNullOrEmpty(segment.Icon)
            ? segment.Text
            : $"{segment.Icon} {segment.Text}";

        if (!useAnsi)
        {
            builder.Append(text);
            return;
        }

        var foreground = resolver.Resolve(segment.Foreground);
        var background = resolver.Resolve(segment.Background);

        if (foreground is null && background is null)
        {
            builder.Append(text);
            return;
        }

        if (foreground is not null)
        {
            builder.Append(foreground.Value.ToForegroundEscape());
        }

        if (background is not null)
        {
            builder.Append(background.Value.ToBackgroundEscape());
        }

        builder.Append(text);
        builder.Append(AnsiCodes.Reset);
    }
}
