using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class SegmentCacheKeyTests
{
    [Fact]
    public void PropertiesChangeTheKey()
    {
        var context = Context();
        var full = Segment(new Dictionary<string, object?> { ["style"] = "full" });
        var shortPath = Segment(new Dictionary<string, object?> { ["style"] = "short" });

        Assert.NotEqual(
            SegmentCacheKey.Create(full, context),
            SegmentCacheKey.Create(shortPath, context));
    }

    [Fact]
    public void PropertyOrderDoesNotChangeTheKey()
    {
        var context = Context();
        var first = Segment(new Dictionary<string, object?>
        {
            ["style"] = "full",
            ["maxDepth"] = 3,
        });
        var second = Segment(new Dictionary<string, object?>
        {
            ["maxDepth"] = 3,
            ["style"] = "full",
        });

        Assert.Equal(
            SegmentCacheKey.Create(first, context),
            SegmentCacheKey.Create(second, context));
    }

    [Fact]
    public void DiamondsAndShellChangeTheKey()
    {
        var first = Segment();
        var second = Segment(leadingDiamond: "[");
        var third = Segment(trailingDiamond: "]");

        Assert.NotEqual(
            SegmentCacheKey.Create(first, Context()),
            SegmentCacheKey.Create(second, Context()));
        Assert.NotEqual(
            SegmentCacheKey.Create(first, Context()),
            SegmentCacheKey.Create(third, Context()));
        Assert.NotEqual(
            SegmentCacheKey.Create(first, Context(shell: "pwsh")),
            SegmentCacheKey.Create(first, Context(shell: "bash")));
    }

    private static PromptContext Context(string shell = "pwsh") =>
        new()
        {
            UserName = "tester",
            HostName = "host",
            Shell = shell,
            Path = new PathContext { Current = "C:\\repo" },
            Git = new GitContext { Branch = "main" },
        };

    private static PromptSegment Segment(
        IReadOnlyDictionary<string, object?>? properties = null,
        string? leadingDiamond = null,
        string? trailingDiamond = null) =>
        new()
        {
            Type = "path",
            Name = "path",
            Style = "plain",
            LeadingDiamond = leadingDiamond,
            TrailingDiamond = trailingDiamond,
            Properties = properties ?? new Dictionary<string, object?>(),
        };
}
