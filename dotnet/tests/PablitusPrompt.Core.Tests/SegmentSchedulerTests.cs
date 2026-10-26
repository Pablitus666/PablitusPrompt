using System.Diagnostics;
using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class SegmentSchedulerTests
{
    [Fact]
    public async Task ReturnsResultsInDeclarationOrder()
    {
        var provider = new DelegateSegmentProvider("work", async (segment, _, cancellationToken) =>
        {
            var delay = segment.Name switch
            {
                "first" => 80,
                "second" => 10,
                "third" => 40,
                _ => 0,
            };
            await Task.Delay(delay, cancellationToken);
            return Success(segment, segment.Name);
        });

        var scheduler = new SegmentScheduler(Registry(provider));
        var results = await scheduler.ScheduleAsync(
            new[]
            {
                Segment("work", "first"),
                Segment("work", "second"),
                Segment("work", "third"),
            },
            new PromptContext());

        Assert.Equal(new[] { "first", "second", "third" }, results.Select(result => result.Text));
        Assert.All(results, result => Assert.Equal(SegmentStatus.Success, result.Status));
    }

    [Fact]
    public async Task RunsSegmentsConcurrently()
    {
        var gate = new object();
        var active = 0;
        var maxActive = 0;

        var provider = new DelegateSegmentProvider("work", async (segment, _, cancellationToken) =>
        {
            lock (gate)
            {
                active++;
                maxActive = Math.Max(maxActive, active);
            }

            try
            {
                await Task.Delay(100, cancellationToken);
                return Success(segment, segment.Name);
            }
            finally
            {
                lock (gate)
                {
                    active--;
                }
            }
        });

        var scheduler = new SegmentScheduler(Registry(provider));
        var segments = Enumerable.Range(0, 4)
            .Select(index => Segment("work", $"s{index}"))
            .ToArray();

        var stopwatch = Stopwatch.StartNew();
        var results = await scheduler.ScheduleAsync(segments, new PromptContext());
        stopwatch.Stop();

        Assert.Equal(4, results.Count);
        Assert.True(maxActive >= 3, $"Expected at least 3 concurrent segments but observed {maxActive}.");
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(700),
            $"Segments appear to run sequentially: {stopwatch.Elapsed.TotalMilliseconds:F0} ms.");
    }

    [Fact]
    public async Task TimeoutDoesNotBreakOtherSegments()
    {
        var slow = new DelegateSegmentProvider("slow", (_, _, _) =>
            Task.Delay(TimeSpan.FromSeconds(30)).ContinueWith(
                _ => Success(Segment("slow", "slow"), "late"),
                TaskScheduler.Default));

        var fast = new DelegateSegmentProvider("fast", (segment, _, _) =>
            Task.FromResult(Success(segment, "fast")));

        var scheduler = new SegmentScheduler(Registry(slow, fast));
        var stopwatch = Stopwatch.StartNew();
        var results = await scheduler.ScheduleAsync(
            new[]
            {
                Segment("slow", "slow", timeoutMs: 50),
                Segment("fast", "fast"),
            },
            new PromptContext());
        stopwatch.Stop();

        Assert.True(stopwatch.Elapsed < TimeSpan.FromSeconds(2));
        Assert.Equal(SegmentStatus.TimedOut, results[0].Status);
        Assert.Contains("timed out", results[0].Error);
        Assert.Equal(SegmentStatus.Success, results[1].Status);
        Assert.Equal("fast", results[1].Text);
    }

    [Fact]
    public async Task ExternalCancellationMarksSegmentsCancelled()
    {
        var provider = new DelegateSegmentProvider("work", async (segment, _, cancellationToken) =>
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
            return Success(segment, "never");
        });

        var scheduler = new SegmentScheduler(Registry(provider));
        using var cancellation = new CancellationTokenSource(TimeSpan.FromMilliseconds(100));
        var stopwatch = Stopwatch.StartNew();
        var results = await scheduler.ScheduleAsync(
            new[]
            {
                Segment("work", "a"),
                Segment("work", "b"),
            },
            new PromptContext(),
            cancellation.Token);
        stopwatch.Stop();

        Assert.True(stopwatch.Elapsed < TimeSpan.FromSeconds(2));
        Assert.All(results, result => Assert.Equal(SegmentStatus.Cancelled, result.Status));
    }

    [Fact]
    public async Task AlreadyCancelledTokenReturnsImmediately()
    {
        var provider = new DelegateSegmentProvider("work", (segment, _, _) =>
            Task.FromResult(Success(segment, "value")));
        var scheduler = new SegmentScheduler(Registry(provider));
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();

        var stopwatch = Stopwatch.StartNew();
        var results = await scheduler.ScheduleAsync(
            new[] { Segment("work", "a") },
            new PromptContext(),
            cancellation.Token);
        stopwatch.Stop();

        Assert.True(stopwatch.Elapsed < TimeSpan.FromSeconds(1));
        Assert.Equal(SegmentStatus.Cancelled, Assert.Single(results).Status);
    }

    [Fact]
    public async Task ProviderExceptionIsCapturedInResult()
    {
        var broken = new DelegateSegmentProvider(
            "broken",
            (_, _, _) => Task.FromException<SegmentResult>(new InvalidOperationException("boom")));
        var healthy = new DelegateSegmentProvider("healthy", (segment, _, _) =>
            Task.FromResult(Success(segment, "ok")));

        var scheduler = new SegmentScheduler(Registry(broken, healthy));
        var results = await scheduler.ScheduleAsync(
            new[]
            {
                Segment("broken", "broken"),
                Segment("healthy", "healthy"),
            },
            new PromptContext());

        Assert.Equal(SegmentStatus.Failed, results[0].Status);
        Assert.Contains("boom", results[0].Error);
        Assert.Equal(SegmentStatus.Success, results[1].Status);
    }

    [Fact]
    public async Task MissingProviderFailsGracefully()
    {
        var scheduler = new SegmentScheduler(new SegmentProviderRegistry());

        var results = await scheduler.ScheduleAsync(
            new[] { Segment("missing", "missing") },
            new PromptContext());

        var result = Assert.Single(results);
        Assert.Equal(SegmentStatus.Failed, result.Status);
        Assert.Contains("No segment provider registered", result.Error);
    }

    [Fact]
    public async Task EmptySegmentListReturnsEmptyArray()
    {
        var scheduler = new SegmentScheduler(new SegmentProviderRegistry());

        var results = await scheduler.ScheduleAsync(Array.Empty<PromptSegment>(), new PromptContext());

        Assert.Empty(results);
    }

    [Fact]
    public async Task SegmentTimeoutOverridesProviderDefault()
    {
        var provider = new DelegateSegmentProvider(
            "slow",
            (_, _, _) => Task.Delay(TimeSpan.FromSeconds(30)).ContinueWith(
                _ => Success(Segment("slow", "x"), "late"),
                TaskScheduler.Default),
            defaultTimeoutMs: 10_000);

        var scheduler = new SegmentScheduler(Registry(provider));
        var stopwatch = Stopwatch.StartNew();
        var results = await scheduler.ScheduleAsync(
            new[] { Segment("slow", "slow", timeoutMs: 50) },
            new PromptContext());
        stopwatch.Stop();

        Assert.True(stopwatch.Elapsed < TimeSpan.FromSeconds(2));
        Assert.Equal(SegmentStatus.TimedOut, Assert.Single(results).Status);
    }

    [Fact]
    public async Task ProviderReturningNullTaskFailsGracefully()
    {
        var provider = new DelegateSegmentProvider("null", (_, _, _) => null!);
        var scheduler = new SegmentScheduler(Registry(provider));

        var results = await scheduler.ScheduleAsync(
            new[] { Segment("null", "null") },
            new PromptContext());

        var result = Assert.Single(results);
        Assert.Equal(SegmentStatus.Failed, result.Status);
        Assert.Contains("null task", result.Error);
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

    private static PromptSegment Segment(string type, string name, int? timeoutMs = null) =>
        new()
        {
            Type = type,
            Name = name,
            Style = "plain",
            TimeoutMs = timeoutMs,
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

    private sealed class DelegateSegmentProvider : ISegmentProvider
    {
        private readonly Func<PromptSegment, PromptContext, CancellationToken, Task<SegmentResult>> _run;

        public DelegateSegmentProvider(
            string type,
            Func<PromptSegment, PromptContext, CancellationToken, Task<SegmentResult>> run,
            int defaultTimeoutMs = 2000)
        {
            _run = run;
            Definition = new SegmentDefinition
            {
                Type = type,
                DisplayName = type,
                DefaultTimeoutMs = defaultTimeoutMs,
            };
        }

        public SegmentDefinition Definition { get; }

        public Task<SegmentResult> GetSegmentAsync(
            PromptSegment segment,
            PromptContext context,
            CancellationToken cancellationToken = default) =>
            _run(segment, context, cancellationToken);
    }
}
