using System.Globalization;
using System.Text;
using System.Text.Json;

namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Stores rendered segment results between prompt invocations. Implementations
/// must be thread-safe because the scheduler can populate the cache from several
/// segment tasks at once.
/// </summary>
public interface ISegmentCache
{
    bool TryGet(string key, out SegmentResult result);

    void Set(string key, SegmentResult result, TimeSpan timeToLive);

    void Clear();

    int Count { get; }
}

/// <summary>
/// In-memory cache with per-entry TTL and a hard entry limit. Entries are
/// cloned on the way in and out so callers cannot mutate a cached result.
/// </summary>
public sealed class InMemorySegmentCache : ISegmentCache
{
    private readonly object _gate = new();
    private readonly Dictionary<string, CacheEntry> _entries = new(StringComparer.Ordinal);
    private readonly TimeProvider _timeProvider;
    private long _sequence;
    private int _maxEntries;

    public InMemorySegmentCache(int maxEntries = 256, TimeProvider? timeProvider = null)
    {
        if (maxEntries <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maxEntries), maxEntries, "MaxEntries must be greater than zero.");
        }

        _maxEntries = maxEntries;
        _timeProvider = timeProvider ?? TimeProvider.System;
    }

    public int MaxEntries
    {
        get
        {
            lock (_gate)
            {
                return _maxEntries;
            }
        }
        set
        {
            if (value <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(value), value, "MaxEntries must be greater than zero.");
            }

            lock (_gate)
            {
                _maxEntries = value;
                TrimLocked();
            }
        }
    }

    public int Count
    {
        get
        {
            lock (_gate)
            {
                RemoveExpiredLocked(_timeProvider.GetUtcNow());
                return _entries.Count;
            }
        }
    }

    public bool TryGet(string key, out SegmentResult result)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);

        lock (_gate)
        {
            var now = _timeProvider.GetUtcNow();
            if (!_entries.TryGetValue(key, out var entry))
            {
                result = null!;
                return false;
            }

            if (entry.ExpiresAt <= now)
            {
                _entries.Remove(key);
                result = null!;
                return false;
            }

            result = Clone(entry.Result);
            return true;
        }
    }

    public void Set(string key, SegmentResult result, TimeSpan timeToLive)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(result);

        if (timeToLive <= TimeSpan.Zero)
        {
            return;
        }

        lock (_gate)
        {
            var now = _timeProvider.GetUtcNow();
            RemoveExpiredLocked(now);

            _entries[key] = new CacheEntry(Clone(result), now + timeToLive, ++_sequence);
            TrimLocked();
        }
    }

    public void Clear()
    {
        lock (_gate)
        {
            _entries.Clear();
        }
    }

    private void TrimLocked()
    {
        while (_entries.Count > _maxEntries)
        {
            var oldestKey = default(string);
            var oldestSequence = long.MaxValue;

            foreach (var pair in _entries)
            {
                if (pair.Value.Sequence < oldestSequence)
                {
                    oldestSequence = pair.Value.Sequence;
                    oldestKey = pair.Key;
                }
            }

            if (oldestKey is null)
            {
                return;
            }

            _entries.Remove(oldestKey);
        }
    }

    private void RemoveExpiredLocked(DateTimeOffset now)
    {
        if (_entries.Count == 0)
        {
            return;
        }

        List<string>? expired = null;
        foreach (var pair in _entries)
        {
            if (pair.Value.ExpiresAt <= now)
            {
                (expired ??= new List<string>()).Add(pair.Key);
            }
        }

        if (expired is null)
        {
            return;
        }

        foreach (var key in expired)
        {
            _entries.Remove(key);
        }
    }

    private static SegmentResult Clone(SegmentResult source) =>
        new()
        {
            Name = source.Name,
            Type = source.Type,
            Text = source.Text,
            Icon = source.Icon,
            Foreground = source.Foreground,
            Background = source.Background,
            Style = source.Style,
            LeadingDiamond = source.LeadingDiamond,
            TrailingDiamond = source.TrailingDiamond,
            Visible = source.Visible,
            Status = source.Status,
            Duration = source.Duration,
            Error = source.Error,
        };

    private sealed record CacheEntry(SegmentResult Result, DateTimeOffset ExpiresAt, long Sequence);
}

/// <summary>
/// Per-render cache settings. Segment TTLs win over the global TTL. Types that
/// change on every prompt (<c>time</c> and <c>exit</c>) are not cached unless a
/// caller supplies a different exclusion set.
/// </summary>
public sealed class SegmentCachePolicy
{
    public static readonly IReadOnlyList<string> DefaultNonCacheableTypes = new[] { "time", "exit" };

    private readonly HashSet<string> _nonCacheableTypes;

    public SegmentCachePolicy(
        ISegmentCache cache,
        TimeSpan defaultTtl,
        IEnumerable<string>? nonCacheableTypes = null)
    {
        Cache = cache ?? throw new ArgumentNullException(nameof(cache));
        DefaultTtl = defaultTtl;
        _nonCacheableTypes = new HashSet<string>(
            nonCacheableTypes ?? DefaultNonCacheableTypes,
            StringComparer.OrdinalIgnoreCase);
    }

    public ISegmentCache Cache { get; }

    public TimeSpan DefaultTtl { get; }

    public bool IsCacheable(PromptSegment segment) =>
        segment is not null &&
        !string.IsNullOrWhiteSpace(segment.Type) &&
        !_nonCacheableTypes.Contains(segment.Type);

    /// <summary>Returns <see cref="TimeSpan.Zero"/> when the segment opted out of caching.</summary>
    public TimeSpan ResolveTtl(PromptSegment segment)
    {
        var ttl = segment.CacheTtlSeconds is { } seconds
            ? TimeSpan.FromSeconds(seconds)
            : DefaultTtl;

        return ttl > TimeSpan.Zero ? ttl : TimeSpan.Zero;
    }
}

/// <summary>
/// Builds a stable cache key from the segment identity and the parts of the
/// context that can change its output. Length prefixes avoid delimiter
/// collisions between values.
/// </summary>
public static class SegmentCacheKey
{
    public static string Create(PromptSegment segment, PromptContext context)
    {
        ArgumentNullException.ThrowIfNull(segment);
        ArgumentNullException.ThrowIfNull(context);

        var builder = new StringBuilder(192);
        Append(builder, segment.Type);
        Append(builder, segment.Name);
        Append(builder, segment.Style);
        Append(builder, segment.Foreground);
        Append(builder, segment.Background);
        Append(builder, segment.Icon);
        Append(builder, segment.LeadingDiamond);
        Append(builder, segment.TrailingDiamond);
        Append(builder, context.Path?.Current);
        Append(builder, context.Git?.Branch);
        Append(builder, context.Git?.IsDirty.ToString());
        Append(builder, context.Git?.Ahead.ToString(CultureInfo.InvariantCulture));
        Append(builder, context.Git?.Behind.ToString(CultureInfo.InvariantCulture));
        Append(builder, context.ExitCode.ToString(CultureInfo.InvariantCulture));
        Append(builder, context.UserName);
        Append(builder, context.HostName);
        Append(builder, context.Shell);
        Append(builder, segment.Template);
        AppendProperties(builder, segment.Properties);
        return builder.ToString();
    }

    /// <summary>
    /// Serializes provider properties in a stable key order. Two segments with
    /// the same type/name but different options (for example a full path and a
    /// shortened path) must not share a cache entry.
    /// </summary>
    private static void AppendProperties(
        StringBuilder builder,
        IReadOnlyDictionary<string, object?> properties)
    {
        if (properties is null || properties.Count == 0)
        {
            builder.Append("0|");
            return;
        }

        builder.Append(properties.Count.ToString(CultureInfo.InvariantCulture));
        builder.Append('|');

        foreach (var pair in properties.OrderBy(entry => entry.Key, StringComparer.OrdinalIgnoreCase))
        {
            Append(builder, pair.Key);
            Append(builder, FormatPropertyValue(pair.Value));
        }
    }

    private static string? FormatPropertyValue(object? value)
    {
        if (value is null)
        {
            return null;
        }

        if (value is string text)
        {
            return text;
        }

        if (value is IFormattable formattable)
        {
            return formattable.ToString(null, CultureInfo.InvariantCulture);
        }

        try
        {
            return JsonSerializer.Serialize(value);
        }
        catch (Exception exception) when (exception is JsonException or NotSupportedException)
        {
            return value.ToString();
        }
    }

    private static void Append(StringBuilder builder, string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            builder.Append("-|");
            return;
        }

        builder.Append(value.Length.ToString(CultureInfo.InvariantCulture));
        builder.Append(':');
        builder.Append(value);
        builder.Append('|');
    }
}
