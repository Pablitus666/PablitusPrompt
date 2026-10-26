using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class SegmentCacheSchedulerTests
{
    [Fact]
    public async Task CacheHitSkipsProviderOnSecondRender()
    {
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            Interlocked.Increment(ref calls);
            return Task.FromResult(Success(segment, "value"));
        });

        var cache = new InMemorySegmentCache(timeProvider: new MutableTimeProvider());
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromMinutes(1));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work") };
        var context = Context("C:\\repo");

        var first = await scheduler.ScheduleAsync(segments, context, default, policy);
        var second = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal("value", Assert.Single(first).Text);
        Assert.Equal("value", Assert.Single(second).Text);
        Assert.Equal(1, calls);
    }

    [Fact]
    public async Task ExpiredEntryCallsProviderAgain()
    {
        var time = new MutableTimeProvider();
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            Interlocked.Increment(ref calls);
            return Task.FromResult(Success(segment, "value"));
        });

        var cache = new InMemorySegmentCache(timeProvider: time);
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromSeconds(5));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work") };
        var context = Context("C:\\repo");

        _ = await scheduler.ScheduleAsync(segments, context, default, policy);
        time.Advance(TimeSpan.FromSeconds(6));
        _ = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal(2, calls);
    }

    [Fact]
    public async Task PerSegmentTtlOverridesGlobalTtl()
    {
        var time = new MutableTimeProvider();
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            Interlocked.Increment(ref calls);
            return Task.FromResult(Success(segment, "value"));
        });

        var cache = new InMemorySegmentCache(timeProvider: time);
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromHours(1));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work", cacheTtlSeconds: 5) };
        var context = Context("C:\\repo");

        _ = await scheduler.ScheduleAsync(segments, context, default, policy);
        time.Advance(TimeSpan.FromSeconds(6));
        _ = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal(2, calls);
    }

    [Fact]
    public async Task ZeroSegmentTtlDisablesCaching()
    {
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            Interlocked.Increment(ref calls);
            return Task.FromResult(Success(segment, "value"));
        });

        var cache = new InMemorySegmentCache(timeProvider: new MutableTimeProvider());
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromMinutes(1));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work", cacheTtlSeconds: 0) };
        var context = Context("C:\\repo");

        _ = await scheduler.ScheduleAsync(segments, context, default, policy);
        _ = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal(2, calls);
        Assert.Equal(0, cache.Count);
    }

    [Fact]
    public async Task TimeAndExitAreNotCachedByDefault()
    {
        var timeCalls = 0;
        var exitCalls = 0;
        var timeProvider = new TestProvider("time", (segment, _, _) =>
        {
            Interlocked.Increment(ref timeCalls);
            return Task.FromResult(Success(segment, "12:00"));
        });
        var exitProvider = new TestProvider("exit", (segment, _, _) =>
        {
            Interlocked.Increment(ref exitCalls);
            return Task.FromResult(Success(segment, "0"));
        });

        var cache = new InMemorySegmentCache();
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromMinutes(1));
        var scheduler = new SegmentScheduler(Registry(timeProvider, exitProvider));
        var segments = new[] { Segment("time", "time"), Segment("exit", "exit") };
        var context = Context("C:\\repo");

        _ = await scheduler.ScheduleAsync(segments, context, default, policy);
        _ = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal(2, timeCalls);
        Assert.Equal(2, exitCalls);
        Assert.Equal(0, cache.Count);
    }

    [Fact]
    public async Task FailedResultsAreNotCached()
    {
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            if (Interlocked.Increment(ref calls) == 1)
            {
                return Task.FromException<SegmentResult>(new InvalidOperationException("boom"));
            }

            return Task.FromResult(Success(segment, "recovered"));
        });

        var cache = new InMemorySegmentCache();
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromMinutes(1));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work") };
        var context = Context("C:\\repo");

        var first = await scheduler.ScheduleAsync(segments, context, default, policy);
        var second = await scheduler.ScheduleAsync(segments, context, default, policy);

        Assert.Equal(SegmentStatus.Failed, Assert.Single(first).Status);
        Assert.Equal("recovered", Assert.Single(second).Text);
        Assert.Equal(2, calls);
    }

    [Fact]
    public async Task ContextChangesInvalidateTheKey()
    {
        var calls = 0;
        var provider = new TestProvider("work", (segment, _, _) =>
        {
            Interlocked.Increment(ref calls);
            return Task.FromResult(Success(segment, "value"));
        });

        var cache = new InMemorySegmentCache();
        var policy = new SegmentCachePolicy(cache, TimeSpan.FromMinutes(1));
        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = new[] { Segment("work", "work") };

        _ = await scheduler.ScheduleAsync(segments, Context("C:\\one"), default, policy);
        _ = await scheduler.ScheduleAsync(segments, Context("C:\\two"), default, policy);

        Assert.Equal(2, calls);
    }

    private static SegmentProviderRegistry Registry(params ISegmentProvider[] providers)
    {
        var registry = new SegmentProviderRegistry();
        foreach (var provider in providers)
        {
            registry.Register(provider);
        }

        return registry;
    }

    private static PromptContext Context(string directory) =>
        new()
        {
            UserName = "tester",
            HostName = "host",
            ExitCode = 0,
            Path = new PathContext { Current = directory },
            Git = new GitContext { Branch = "main" },
        };

    private static PromptSegment Segment(string type, string name, int? cacheTtlSeconds = null) =>
        new()
        {
            Type = type,
            Name = name,
            Style = "plain",
            CacheTtlSeconds = cacheTtlSeconds,
        };

    private static SegmentResult Success(PromptSegment segment, string text) =>
        new()
        {
            Name = segment.Name,
            Type = segment.Type,
            Text = text,
            Style = segment.Style,
            Visible = true,
            Status = SegmentStatus.Success,
        };

    private sealed class TestProvider : ISegmentProvider
    {
        private readonly Func<PromptSegment, PromptContext, CancellationToken, Task<SegmentResult>> _run;

        public TestProvider(
            string type,
            Func<PromptSegment, PromptContext, CancellationToken, Task<SegmentResult>> run)
        {
            _run = run;
            Definition = new SegmentDefinition
            {
                Type = type,
                DisplayName = type,
                DefaultTimeoutMs = 2000,
            };
        }

        public SegmentDefinition Definition { get; }

        public Task<SegmentResult> GetSegmentAsync(
            PromptSegment segment,
            PromptContext context,
            CancellationToken cancellationToken = default) =>
            _run(segment, context, cancellationToken);
    }

    private sealed class MutableTimeProvider : TimeProvider
    {
        private DateTimeOffset _utcNow = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

        public override DateTimeOffset GetUtcNow() => _utcNow;

        public void Advance(TimeSpan delta) => _utcNow += delta;
    }
}
