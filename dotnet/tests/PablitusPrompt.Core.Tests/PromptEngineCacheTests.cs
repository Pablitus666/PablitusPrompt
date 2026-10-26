using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Segments;
using PablitusPrompt.Core.Templating;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class PromptEngineCacheTests
{
    [Fact]
    public async Task EnabledCacheReusesSegmentResultsBetweenRenders()
    {
        var (engine, provider, config, context) = Build(enableCache: true);

        var first = await engine.RenderAsync(config, context);
        var second = await engine.RenderAsync(config, context);

        Assert.Equal(1, provider.Calls);
        Assert.Equal(first.Output, second.Output);
    }

    [Fact]
    public async Task UseCacheFalseBypassesTheCache()
    {
        var (engine, provider, config, context) = Build(enableCache: true);

        _ = await engine.RenderAsync(config, context);
        _ = await engine.RenderAsync(
            config,
            context,
            new PromptEngineOptions { UseCache = false });

        Assert.Equal(2, provider.Calls);
    }

    [Fact]
    public async Task DisabledCacheDoesNotStoreResults()
    {
        var (engine, provider, config, context) = Build(enableCache: false);

        _ = await engine.RenderAsync(config, context);
        _ = await engine.RenderAsync(config, context);

        Assert.Equal(2, provider.Calls);
    }

    private static (PromptEngine Engine, CountingProvider Provider, PpfConfig Config, PromptContext Context) Build(bool enableCache)
    {
        var templates = new TemplateEngine();
        var provider = new CountingProvider(templates);
        var registry = new SegmentProviderRegistry().Register(provider);

        var config = new PpfConfig
        {
            Renderer = "plain",
            Cache = new CacheConfig
            {
                Enabled = enableCache,
                TtlSeconds = 60,
                MaxEntries = 16,
            },
            Blocks = new List<BlockConfig>
            {
                new()
                {
                    Type = "prompt",
                    Alignment = "left",
                    Segments = new List<SegmentConfig>
                    {
                        new()
                        {
                            Type = "work",
                            Name = "work",
                            Template = "{{ .UserName }}",
                        },
                    },
                },
            },
        };

        var context = new PromptContext
        {
            UserName = "tester",
            HostName = "host",
            Path = new PathContext { Current = "C:\\repo" },
        };

        return (new PromptEngine(templates, registry), provider, config, context);
    }

    private sealed class CountingProvider : TemplateSegmentProvider
    {
        private int _calls;

        public CountingProvider(TemplateEngine templates)
            : base(templates, new SegmentDefinition
            {
                Type = "work",
                DisplayName = "Work",
                DefaultTemplate = "{{ .UserName }}",
            })
        {
        }

        public int Calls => _calls;

        public override Task<SegmentResult> GetSegmentAsync(
            PromptSegment segment,
            PromptContext context,
            CancellationToken cancellationToken = default)
        {
            Interlocked.Increment(ref _calls);
            return base.GetSegmentAsync(segment, context, cancellationToken);
        }
    }
}
