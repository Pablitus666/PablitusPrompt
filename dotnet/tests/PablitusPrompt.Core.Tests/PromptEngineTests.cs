using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class PromptEngineTests
{
    [Fact]
    public async Task RendersExampleConfigurationWithAnsi()
    {
        var config = PpfConfigSerializer.LoadConfig(TestPaths.ExampleConfig);
        var context = PromptContextFactory.Create(TestPaths.RepoRoot, exitCode: 0);
        var engine = new PromptEngine();

        var result = await engine.RenderAsync(config, context);

        Assert.NotEmpty(result.Output);
        Assert.Contains("\u001b[", result.Output);
        Assert.Equal(2, result.Blocks.Count);
        Assert.All(result.Segments, segment => Assert.Equal(SegmentStatus.Success, segment.Status));
        Assert.True(result.Duration > TimeSpan.Zero);
    }

    [Fact]
    public async Task RendersThemeFileWithoutAnsi()
    {
        var theme = PpfConfigSerializer.LoadTheme(TestPaths.NordTheme);
        var config = new PpfConfig
        {
            Theme = theme,
            Renderer = theme.Renderer ?? "plain",
            FinalSpace = theme.FinalSpace,
        };
        var context = PromptContextFactory.Create(TestPaths.RepoRoot, exitCode: 0);
        var engine = new PromptEngine();

        var result = await engine.RenderAsync(
            config,
            context,
            new PromptEngineOptions { UseAnsi = false });

        Assert.DoesNotContain("\u001b[", result.Output);
        Assert.Contains(context.Path.Display, result.Output);
        Assert.Contains("❯", result.Output);
    }

    [Fact]
    public async Task ExitSegmentIsHiddenForZeroExitCode()
    {
        var config = ExitConfig();

        var zero = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create(TestPaths.RepoRoot, exitCode: 0));
        var failure = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create(TestPaths.RepoRoot, exitCode: 42));

        Assert.Equal(string.Empty, zero.Output);
        Assert.Equal("42", failure.Output);
    }

    [Fact]
    public async Task DisabledSegmentsAreNotScheduled()
    {
        var config = new PpfConfig
        {
            Renderer = "plain",
            FinalSpace = false,
            Blocks =
            {
                new BlockConfig
                {
                    Segments =
                    {
                        new SegmentConfig { Type = "text", Name = "a", Template = "A" },
                        new SegmentConfig { Type = "text", Name = "b", Template = "B", Enabled = false },
                        new SegmentConfig { Type = "text", Name = "c", Template = "C" },
                    },
                },
            },
        };

        var result = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create(TestPaths.RepoRoot));

        Assert.Equal("AC", result.Output);
        Assert.Equal(2, result.Segments.Count);
    }

    [Fact]
    public async Task UnknownProviderFailsOnlyItsSegment()
    {
        var config = new PpfConfig
        {
            Renderer = "plain",
            FinalSpace = false,
            Blocks =
            {
                new BlockConfig
                {
                    Segments =
                    {
                        new SegmentConfig { Type = "does-not-exist" },
                        new SegmentConfig { Type = "text", Name = "ok", Template = "ok" },
                    },
                },
            },
        };

        var result = await new PromptEngine().RenderAsync(
            config,
            PromptContextFactory.Create(TestPaths.RepoRoot));

        Assert.Equal("ok", result.Output);
        Assert.Equal(SegmentStatus.Failed, result.Segments[0].Status);
        Assert.Equal(SegmentStatus.Success, result.Segments[1].Status);
    }

    [Fact]
    public async Task InvalidConfigurationIsRejectedBeforeRunningProviders()
    {
        var config = new PpfConfig
        {
            Renderer = "fancy",
            Blocks =
            {
                new BlockConfig
                {
                    Segments = { new SegmentConfig { Type = "text", Template = "x" } },
                },
            },
        };

        await Assert.ThrowsAsync<PpfConfigurationException>(
            () => new PromptEngine().RenderAsync(
                config,
                PromptContextFactory.Create(TestPaths.RepoRoot)));
    }

    [Fact]
    public void PromptContextFactoryDetectsRepositoryAndFolder()
    {
        var context = PromptContextFactory.Create(TestPaths.RepoRoot);

        Assert.Equal("PablitusPrompt", context.Path.Folder);
        Assert.Equal(TestPaths.RepoRoot, context.Path.Current);
        Assert.True(context.Git.IsRepository);
        Assert.False(string.IsNullOrWhiteSpace(context.Git.Branch));
        Assert.Equal(context.UserName, context.Session.UserName);
    }

    [Fact]
    public void PromptContextFactoryHandlesMissingDirectory()
    {
        var context = PromptContextFactory.Create(Path.Combine(Path.GetTempPath(), "ppf-does-not-exist"));

        Assert.False(context.Git.IsRepository);
        Assert.Contains("ppf-does-not-exist", context.Path.Current);
    }

    private static PpfConfig ExitConfig() =>
        new()
        {
            Renderer = "plain",
            FinalSpace = false,
            Blocks =
            {
                new BlockConfig
                {
                    Segments =
                    {
                        new SegmentConfig
                        {
                            Type = "exit",
                            Template = "{{ if ne .ExitCode 0 }}{{ .ExitCode }}{{ end }}",
                        },
                    },
                },
            },
        };
}
