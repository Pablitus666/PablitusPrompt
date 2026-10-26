using PablitusPrompt.Core.Rendering;
using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class RendererTests
{
    [Fact]
    public void ParsesNamedAndTrueColors()
    {
        Assert.True(AnsiColor.TryParse("red", out var red));
        Assert.Equal("\u001b[31m", red.ToForegroundEscape());
        Assert.Equal("\u001b[41m", red.ToBackgroundEscape());

        Assert.True(AnsiColor.TryParse("brightcyan", out var brightCyan));
        Assert.Equal("\u001b[96m", brightCyan.ToForegroundEscape());

        Assert.True(AnsiColor.TryParse("#ff8800", out var orange));
        Assert.Equal("\u001b[38;2;255;136;0m", orange.ToForegroundEscape());
        Assert.Equal("\u001b[48;2;255;136;0m", orange.ToBackgroundEscape());

        Assert.True(AnsiColor.TryParse("#f80", out var shortHex));
        Assert.Equal("\u001b[38;2;255;136;0m", shortHex.ToForegroundEscape());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("transparent")]
    [InlineData("#12")]
    [InlineData("#gggggg")]
    [InlineData("not a color")]
    public void RejectsInvalidColors(string? value)
    {
        Assert.False(AnsiColor.TryParse(value, out _));
    }

    [Fact]
    public void ResolvesPaletteReferencesAndCycles()
    {
        var palette = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["accent"] = "#5e81ac",
            ["alias"] = "accent",
            ["a"] = "b",
            ["b"] = "a",
        };
        var resolver = new ColorResolver(palette);

        Assert.Equal("#5e81ac", resolver.Resolve("accent")?.ToString());
        Assert.Equal("#5e81ac", resolver.Resolve("alias")?.ToString());
        Assert.Null(resolver.Resolve("a"));
        Assert.Null(resolver.Resolve("missing"));
    }

    [Fact]
    public void PlainRendererAppliesColorsAndBlocks()
    {
        var model = new PromptRenderModel
        {
            Palette = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["accent"] = "#5e81ac",
            },
            FinalSpace = true,
            Blocks = new[]
            {
                Block(
                    Result("user", "pablo", foreground: "accent"),
                    Result("path", "repo", foreground: "cyan")),
                Block(newline: true, Result("text", "❯")),
            },
        };

        var output = new PlainRenderer().Render(model);

        Assert.Contains("\u001b[38;2;94;129;172m", output);
        Assert.Contains("pablo", output);
        Assert.Contains("\u001b[36m", output);
        Assert.Contains("\u001b[0m", output);
        Assert.Contains("\n", output);
        Assert.EndsWith(" ", output);
    }

    [Fact]
    public void PlainRendererCanDisableAnsi()
    {
        var model = new PromptRenderModel
        {
            UseAnsi = false,
            FinalSpace = true,
            Blocks = new[]
            {
                Block(Result("user", "pablo", foreground: "red")),
            },
        };

        Assert.Equal("pablo ", new PlainRenderer().Render(model));
    }

    [Fact]
    public void RenderersSkipInvisibleSegments()
    {
        var invisible = Result("git", "main");
        invisible.Visible = false;

        var model = new PromptRenderModel
        {
            UseAnsi = false,
            FinalSpace = false,
            Blocks = new[]
            {
                Block(Result("a", "A"), invisible, Result("b", "B")),
            },
        };

        Assert.Equal("AB", new PlainRenderer().Render(model));
        Assert.Equal("AB", new PowerLineRenderer().Render(model));
    }

    [Fact]
    public void PowerLineRendererEmitsTrueColorSeparators()
    {
        var first = Result(
            "session",
            "pablo",
            foreground: "#eceff4",
            background: "#5e81ac",
            style: "powerline");
        var second = Result(
            "path",
            "repo",
            foreground: "#2e3440",
            background: "#a3be8c",
            style: "powerline");

        var model = new PromptRenderModel
        {
            FinalSpace = true,
            Blocks = new[] { Block(first, second) },
        };

        var output = new PowerLineRenderer().Render(model);

        Assert.Contains("\u001b[48;2;94;129;172m", output);
        Assert.Contains("\u001b[38;2;163;190;140m", output);
        Assert.Contains("\uE0B0", output);
        Assert.Contains("\u001b[0m", output);
        Assert.EndsWith(" ", output);
    }

    [Fact]
    public void PowerLineRendererIsDeterministic()
    {
        var model = new PromptRenderModel
        {
            FinalSpace = true,
            Blocks = new[]
            {
                Block(Result(
                    "session",
                    "pablo",
                    foreground: "white",
                    background: "#5e81ac",
                    style: "powerline")),
            },
        };
        var renderer = new PowerLineRenderer();

        Assert.Equal(renderer.Render(model), renderer.Render(model));
    }

    [Fact]
    public void PowerLineRendererSupportsDiamondStyle()
    {
        var model = new PromptRenderModel
        {
            UseAnsi = false,
            FinalSpace = false,
            Blocks = new[]
            {
                Block(Result(
                    "time",
                    "12:00",
                    foreground: "white",
                    background: "#ebcb8b",
                    style: "diamond")),
            },
        };

        var output = new PowerLineRenderer().Render(model);

        Assert.Contains("\uE0B6", output);
        Assert.Contains("\uE0B4", output);
        Assert.Contains("12:00", output);
    }

    [Fact]
    public void PowerLineRendererUsesContrastForMissingForeground()
    {
        var model = new PromptRenderModel
        {
            FinalSpace = false,
            Blocks = new[]
            {
                Block(Result("light", "x", background: "#ffffff", style: "powerline")),
            },
        };

        var output = new PowerLineRenderer().Render(model);

        Assert.Contains("\u001b[30m", output);
    }

    [Fact]
    public void EmptyModelStillHonorsFinalSpace()
    {
        var model = new PromptRenderModel { FinalSpace = true };

        Assert.Equal(" ", new PlainRenderer().Render(model));
        Assert.Equal(" ", new PowerLineRenderer().Render(model));
    }

    [Fact]
    public void RendererFactoryRejectsUnknownNames()
    {
        Assert.IsType<PlainRenderer>(RendererFactory.Create("plain"));
        Assert.IsType<PowerLineRenderer>(RendererFactory.Create("powerline"));
        Assert.Throws<ArgumentException>(() => RendererFactory.Create("fancy"));
    }

    private static PromptRenderBlock Block(params SegmentResult[] segments) =>
        new() { Segments = segments };

    private static PromptRenderBlock Block(bool newline, params SegmentResult[] segments) =>
        new() { Segments = segments, Newline = newline };

    private static SegmentResult Result(
        string name,
        string text,
        string? foreground = null,
        string? background = null,
        string style = "plain") =>
        new()
        {
            Name = name,
            Type = name,
            Text = text,
            Foreground = foreground,
            Background = background,
            Style = style,
            Visible = true,
            Status = SegmentStatus.Success,
        };
}
