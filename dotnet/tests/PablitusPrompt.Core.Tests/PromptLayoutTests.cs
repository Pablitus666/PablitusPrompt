using PablitusPrompt.Core.Rendering;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class PromptLayoutTests
{
    [Fact]
    public void MeasuresWithoutAnsiAndUsesLastLine()
    {
        Assert.Equal(5, PromptLayout.Measure("ab\u001b[31mcd\u001b[0me"));
        Assert.Equal(3, PromptLayout.MeasureLastLine("first\nabc"));
        Assert.Equal(2, PromptLayout.Measure("界"));
    }

    [Fact]
    public void ComposesFillerAndRestoresCursor()
    {
        var result = PromptLayout.Compose(
            "L ",
            "R",
            terminalWidth: 20,
            overflow: null,
            fillerFactory: _ => ".",
            useAnsi: true);

        Assert.Equal("L \u001b[s" + new string('.', 17) + "R\u001b[u", result);
    }

    [Fact]
    public void ComposesWithoutAnsiUsingSpaces()
    {
        var result = PromptLayout.Compose(
            "L ",
            "R",
            terminalWidth: 10,
            overflow: null,
            fillerFactory: null,
            useAnsi: false);

        Assert.Equal("L " + new string(' ', 7) + "R", result);
    }

    [Fact]
    public void HidesOrBreaksOverflowingRightPrompt()
    {
        var left = new string('x', 20);

        Assert.Equal(
            left,
            PromptLayout.Compose(left, "right", 20, "hide", null, useAnsi: false));

        Assert.Equal(
            left + "\n" + new string(' ', 15) + "right",
            PromptLayout.Compose(left, "right", 20, "break", null, useAnsi: false));
    }

    [Fact]
    public void RightAlignsFromCursorColumn()
    {
        Assert.Equal("        tooltip", PromptLayout.RightAlign("tooltip", 20, 5));
        Assert.Equal("tooltip", PromptLayout.RightAlign("tooltip", 5, 2));
    }

    [Fact]
    public void FitsFillerToExactWidth()
    {
        Assert.Equal("ababa", PromptLayout.Fit("ab", 5));
        Assert.Equal("a", PromptLayout.Fit("ab", 1));
        Assert.Equal(string.Empty, PromptLayout.Fit("ab", 0));
    }
}
