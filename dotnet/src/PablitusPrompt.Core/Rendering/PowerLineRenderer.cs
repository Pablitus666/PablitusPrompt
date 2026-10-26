using System.Text;
using PablitusPrompt.Core.Segments;

namespace PablitusPrompt.Core.Rendering;

/// <summary>
/// PowerLine renderer with truecolor support. Blocks are joined with a newline
/// when <c>newline</c> is set. The renderer is pure: same model, same string.
/// </summary>
public sealed class PowerLineRenderer : IRenderer
{
    private const string DefaultLeadingDiamond = "\uE0B6";
    private const string DefaultTrailingDiamond = "\uE0B4";

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

            for (var index = 0; index < visible.Length; index++)
            {
                var next = index + 1 < visible.Length ? visible[index + 1] : null;
                AppendSegment(
                    builder,
                    visible[index],
                    next,
                    isFirstInBlock: index == 0,
                    resolver,
                    model);
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
        SegmentResult segment,
        SegmentResult? next,
        bool isFirstInBlock,
        ColorResolver resolver,
        PromptRenderModel model)
    {
        var style = string.IsNullOrWhiteSpace(segment.Style)
            ? "plain"
            : segment.Style.ToLowerInvariant();

        switch (style)
        {
            case "powerline":
            case "accordion":
                AppendPowerLine(builder, segment, next, isFirstInBlock, resolver, model);
                break;

            case "diamond":
                AppendDiamond(builder, segment, resolver, model);
                break;

            default:
                AppendPlain(builder, segment, resolver, model);
                break;
        }
    }

    private static void AppendPowerLine(
        StringBuilder builder,
        SegmentResult segment,
        SegmentResult? next,
        bool isFirstInBlock,
        ColorResolver resolver,
        PromptRenderModel model)
    {
        var background = resolver.Resolve(segment.Background);
        if (background is null)
        {
            AppendPlain(builder, segment, resolver, model);
            return;
        }

        var foreground = resolver.Resolve(segment.Foreground) ?? AnsiColor.ContrastFor(background.Value);
        var text = BuildPaddedText(segment);

        if (!model.UseAnsi)
        {
            if (isFirstInBlock && !string.IsNullOrEmpty(segment.LeadingDiamond))
            {
                builder.Append(segment.LeadingDiamond);
            }

            builder.Append(text);
            builder.Append(model.Separator);
            if (next is null)
            {
                builder.Append(' ');
            }

            return;
        }

        if (isFirstInBlock && !string.IsNullOrEmpty(segment.LeadingDiamond))
        {
            builder.Append(background.Value.ToForegroundEscape());
            builder.Append(segment.LeadingDiamond);
            builder.Append(AnsiCodes.Reset);
        }

        builder.Append(foreground.ToForegroundEscape());
        builder.Append(background.Value.ToBackgroundEscape());
        builder.Append(text);
        builder.Append(AnsiCodes.Reset);

        var nextBackground = next is null ? null : resolver.Resolve(next.Background);
        builder.Append(background.Value.ToForegroundEscape());
        if (nextBackground is not null)
        {
            builder.Append(nextBackground.Value.ToBackgroundEscape());
        }

        builder.Append(model.Separator);
        builder.Append(AnsiCodes.Reset);
        if (next is null)
        {
            builder.Append(' ');
        }
    }

    private static void AppendDiamond(
        StringBuilder builder,
        SegmentResult segment,
        ColorResolver resolver,
        PromptRenderModel model)
    {
        var background = resolver.Resolve(segment.Background) ?? resolver.Resolve(segment.Foreground);
        if (background is null)
        {
            AppendPlain(builder, segment, resolver, model);
            return;
        }

        var foreground = resolver.Resolve(segment.Foreground) ?? AnsiColor.ContrastFor(background.Value);
        var leading = string.IsNullOrEmpty(segment.LeadingDiamond) ? DefaultLeadingDiamond : segment.LeadingDiamond;
        var trailing = string.IsNullOrEmpty(segment.TrailingDiamond) ? DefaultTrailingDiamond : segment.TrailingDiamond;
        var text = BuildPaddedText(segment);

        if (!model.UseAnsi)
        {
            builder.Append(leading);
            builder.Append(text);
            builder.Append(trailing);
            return;
        }

        builder.Append(background.Value.ToForegroundEscape());
        builder.Append(leading);
        builder.Append(AnsiCodes.Reset);

        builder.Append(foreground.ToForegroundEscape());
        builder.Append(background.Value.ToBackgroundEscape());
        builder.Append(text);
        builder.Append(AnsiCodes.Reset);

        builder.Append(background.Value.ToForegroundEscape());
        builder.Append(trailing);
        builder.Append(AnsiCodes.Reset);
    }

    private static void AppendPlain(
        StringBuilder builder,
        SegmentResult segment,
        ColorResolver resolver,
        PromptRenderModel model)
    {
        var text = string.IsNullOrEmpty(segment.Icon)
            ? segment.Text
            : $"{segment.Icon} {segment.Text}";

        if (!model.UseAnsi)
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

    private static string BuildPaddedText(SegmentResult segment) =>
        string.IsNullOrEmpty(segment.Icon)
            ? $" {segment.Text} "
            : $" {segment.Icon} {segment.Text} ";
}
