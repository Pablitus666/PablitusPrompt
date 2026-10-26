using PablitusPrompt.Core.Segments;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class SegmentCacheTests
{
    [Fact]
    public void HitReturnsCachedResultWithoutSharingMutableState()
    {
        var cache = new InMemorySegmentCache();
        cache.Set("key", Result("original"), TimeSpan.FromMinutes(1));

        Assert.True(cache.TryGet("key", out var first));
        Assert.Equal("original", first.Text);

        first.Text = "mutated";
        Assert.True(cache.TryGet("key", out var second));
        Assert.Equal("original", second.Text);
    }

    [Fact]
    public void ExpiredEntriesAreNotReturned()
    {
        var time = new MutableTimeProvider();
        var cache = new InMemorySegmentCache(timeProvider: time);
        cache.Set("key", Result("value"), TimeSpan.FromSeconds(10));

        time.Advance(TimeSpan.FromSeconds(9));
        Assert.True(cache.TryGet("key", out _));

        time.Advance(TimeSpan.FromSeconds(2));
        Assert.False(cache.TryGet("key", out _));
        Assert.Equal(0, cache.Count);
    }

    [Fact]
    public void MaxEntriesEvictsTheOldestEntry()
    {
        var cache = new InMemorySegmentCache(maxEntries: 2);
        cache.Set("first", Result("1"), TimeSpan.FromMinutes(1));
        cache.Set("second", Result("2"), TimeSpan.FromMinutes(1));
        cache.Set("third", Result("3"), TimeSpan.FromMinutes(1));

        Assert.Equal(2, cache.Count);
        Assert.False(cache.TryGet("first", out _));
        Assert.True(cache.TryGet("second", out _));
        Assert.True(cache.TryGet("third", out _));
    }

    [Fact]
    public void ReducingMaxEntriesTrimsImmediately()
    {
        var cache = new InMemorySegmentCache(maxEntries: 3);
        cache.Set("first", Result("1"), TimeSpan.FromMinutes(1));
        cache.Set("second", Result("2"), TimeSpan.FromMinutes(1));
        cache.Set("third", Result("3"), TimeSpan.FromMinutes(1));

        cache.MaxEntries = 1;

        Assert.Equal(1, cache.Count);
        Assert.True(cache.TryGet("third", out _));
    }

    [Fact]
    public void ClearRemovesEveryEntry()
    {
        var cache = new InMemorySegmentCache();
        cache.Set("one", Result("1"), TimeSpan.FromMinutes(1));
        cache.Set("two", Result("2"), TimeSpan.FromMinutes(1));

        cache.Clear();

        Assert.Equal(0, cache.Count);
        Assert.False(cache.TryGet("one", out _));
    }

    [Fact]
    public void NonPositiveTtlIsIgnored()
    {
        var cache = new InMemorySegmentCache();
        cache.Set("key", Result("value"), TimeSpan.Zero);

        Assert.Equal(0, cache.Count);
        Assert.False(cache.TryGet("key", out _));
    }

    private static SegmentResult Result(string text) =>
        new()
        {
            Name = "test",
            Type = "test",
            Text = text,
            Visible = true,
            Status = SegmentStatus.Success,
        };

    private sealed class MutableTimeProvider : TimeProvider
    {
        private DateTimeOffset _utcNow = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

        public override DateTimeOffset GetUtcNow() => _utcNow;

        public void Advance(TimeSpan delta) => _utcNow += delta;
    }
}
