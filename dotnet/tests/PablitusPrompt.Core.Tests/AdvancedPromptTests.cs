using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Rendering;
using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class AdvancedPromptTests
{
    [Fact]
    public async Task ComposesRightPromptWhenWidthIsKnown()
    {
        var config = CreateConfig();
        var context = PromptContextFactory.Create(".", terminalWidth: 20);
        var result = await new PromptEngine().RenderAsync(
            config,
            context,
            new PromptEngineOptions { TerminalWidth = 20, UseAnsi = false });

        Assert.Equal("left " + new string('.', 10) + "right", result.Output);
        Assert.Equal("right", result.RightPrompt);
        Assert.Equal(2, result.Blocks.Count);
    }

    [Fact]
    public async Task KeepsRightPromptSeparateWithoutWidth()
    {
        var config = CreateConfig();
        var result = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create("."),
            new PromptEngineOptions { UseAnsi = false });

        Assert.Equal("left ", result.Output);
        Assert.Equal("right", result.RightPrompt);
    }

    [Fact]
    public async Task HidesRightPromptOnOverflow()
    {
        var config = CreateConfig();
        config.Theme!.Blocks[1].Filler = ".";
        config.Theme.Blocks[1].Overflow = "hide";
        config.Theme.Blocks[1].Segments[0].Template = new string('R', 30);

        var result = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create("."),
            new PromptEngineOptions { TerminalWidth = 20, UseAnsi = false });

        Assert.Equal("left ", result.Output);
        Assert.Contains("R", result.RightPrompt);
    }

    [Fact]
    public void RendersTransientTemplateWithFillerAndRightTemplate()
    {
        var config = CreateConfig();
        config.Theme!.TransientPrompt = new TransientPromptConfig
        {
            Template = "{{ .Shell }}> ",
            RightTemplate = "R",
            Filler = ".",
        };

        var transient = new PromptEngine().RenderTransient(
            config,
            PromptContextFactory.Create(".", terminalWidth: 20),
            new PromptEngineOptions { TerminalWidth = 20, UseAnsi = false });

        Assert.Equal("pwsh> " + new string('.', 13) + "R", transient);
    }

    [Fact]
    public void RendersInterruptedTransientPromptAndFallbackTemplate()
    {
        var config = new PpfConfig
        {
            Template = new TemplateConfig
            {
                TransientPrompt = "{{ if .Interrupted }}^C {{ end }}{{ .Shell }}> ",
            },
            Theme = new ThemeConfig
            {
                Blocks =
                {
                    new BlockConfig
                    {
                        Segments = { new SegmentConfig { Type = "text", Template = "left" } },
                    },
                },
            },
        };

        var transient = new PromptEngine().RenderTransient(
            config,
            PromptContextFactory.Create(".", interrupted: true),
            new PromptEngineOptions { UseAnsi = false });

        Assert.Equal("^C pwsh> ", transient);
    }

    [Fact]
    public void AppliesTransientColorsAndNewline()
    {
        var config = CreateConfig();
        config.Theme!.TransientPrompt = new TransientPromptConfig
        {
            Template = "T",
            Foreground = "#ffffff",
            Background = "#000000",
            Newline = true,
        };

        var transient = new PromptEngine().RenderTransient(
            config,
            PromptContextFactory.Create("."),
            new PromptEngineOptions { UseAnsi = true });

        Assert.StartsWith(Environment.NewLine + "\u001b[38;2;255;255;255m", transient);
        Assert.Contains("T", transient);
        Assert.EndsWith("\u001b[0m", transient);
    }

    [Fact]
    public async Task RendersMatchingTooltipRightAligned()
    {
        var config = CreateConfig();
        config.Theme!.TooltipsAction = "replace";
        var result = await new PromptEngine().RenderTooltipAsync(
            config,
            PromptContextFactory.Create("."),
            "git status",
            terminalWidth: 40,
            column: 5,
            options: new PromptEngineOptions { UseAnsi = false });

        Assert.Equal("tooltip", result.Text);
        Assert.Equal(new[] { "tooltip" }, result.MatchedSegments);
        Assert.Equal(new string(' ', 28) + "tooltip", result.Output);
    }

    [Theory]
    [InlineData("extend", "righttooltip")]
    [InlineData("prepend", "tooltipright")]
    public async Task CombinesTooltipWithRightPrompt(string action, string expected)
    {
        var config = CreateConfig();
        config.Theme!.TooltipsAction = action;

        var result = await new PromptEngine().RenderTooltipAsync(
            config,
            PromptContextFactory.Create("."),
            "git",
            terminalWidth: 20,
            column: 0,
            options: new PromptEngineOptions { UseAnsi = false });

        Assert.Equal(expected, result.Text);
        Assert.Equal("right", result.RightPrompt);
        Assert.Equal(new string(' ', 20 - expected.Length) + expected, result.Output);
    }

    [Fact]
    public async Task ReturnsEmptyTooltipWhenNoTipMatches()
    {
        var result = await new PromptEngine().RenderTooltipAsync(
            CreateConfig(),
            PromptContextFactory.Create("."),
            "dotnet build",
            terminalWidth: 40);

        Assert.Equal(string.Empty, result.Output);
        Assert.Empty(result.MatchedSegments);
    }

    private static PpfConfig CreateConfig()
    {
        return new PpfConfig
        {
            Renderer = "plain",
            Theme = new ThemeConfig
            {
                Blocks =
                {
                    new BlockConfig
                    {
                        Segments =
                        {
                            new SegmentConfig { Type = "text", Template = "left" },
                        },
                    },
                    new BlockConfig
                    {
                        Type = "rprompt",
                        Alignment = "right",
                        Filler = ".",
                        Segments =
                        {
                            new SegmentConfig { Type = "text", Template = "right" },
                        },
                    },
                },
                Tooltips =
                {
                    new TooltipConfig
                    {
                        Name = "tooltip",
                        Type = "text",
                        Tips = { "git", "g" },
                        Template = "tooltip",
                    },
                },
            },
        };
    }
}
