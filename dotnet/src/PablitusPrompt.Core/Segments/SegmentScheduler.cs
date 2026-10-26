using System.Diagnostics;

namespace PablitusPrompt.Core.Segments;

public sealed class SegmentSchedulerOptions
{
    /// <summary>Timeout used when neither the segment nor its provider defines one.</summary>
    public int DefaultTimeoutMs { get; set; } = 2000;

    /// <summary>
    /// When a provider ignores cancellation, its task is abandoned after a timeout.
    /// The scheduler observes the eventual exception to avoid unobserved-task noise.
    /// </summary>
    public bool ObserveAbandonedTasks { get; set; } = true;
}

/// <summary>
/// Runs segment providers concurrently with per-segment timeouts and external
/// cancellation. Results always keep the declaration order and never throw for a
/// provider failure: one broken segment cannot break the prompt.
/// </summary>
public sealed class SegmentScheduler
{
    private readonly SegmentProviderRegistry _registry;
    private readonly SegmentSchedulerOptions _options;

    public SegmentScheduler(SegmentProviderRegistry registry, SegmentSchedulerOptions? options = null)
    {
        _registry = registry ?? throw new ArgumentNullException(nameof(registry));
        _options = options ?? new SegmentSchedulerOptions();
    }

    public async Task<IReadOnlyList<SegmentResult>> ScheduleAsync(
        IReadOnlyList<PromptSegment> segments,
        PromptContext context,
        CancellationToken cancellationToken = default,
        SegmentCachePolicy? cachePolicy = null)
    {
        ArgumentNullException.ThrowIfNull(segments);
        ArgumentNullException.ThrowIfNull(context);

        var results = new SegmentResult[segments.Count];
        if (segments.Count == 0)
        {
            return results;
        }

        if (cancellationToken.IsCancellationRequested)
        {
            for (var i = 0; i < segments.Count; i++)
            {
                results[i] = SegmentResult.ErrorResult(
                    segments[i],
                    SegmentStatus.Cancelled,
                    "Prompt rendering was cancelled.");
            }

            return results;
        }

        var tasks = new Task[segments.Count];
        for (var i = 0; i < segments.Count; i++)
        {
            tasks[i] = RunOneAsync(segments[i], context, results, i, cancellationToken, cachePolicy);
        }

        await Task.WhenAll(tasks).ConfigureAwait(false);
        return results;
    }

    private async Task RunOneAsync(
        PromptSegment segment,
        PromptContext context,
        SegmentResult[] results,
        int index,
        CancellationToken cancellationToken,
        SegmentCachePolicy? cachePolicy)
    {
        var started = Stopwatch.GetTimestamp();
        SegmentResult result;

        try
        {
            result = await ExecuteAsync(segment, context, cancellationToken, cachePolicy).ConfigureAwait(false);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            result = SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Cancelled,
                "Prompt rendering was cancelled.");
        }
        catch (Exception exception)
        {
            result = SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Failed,
                exception.Message);
        }

        result.Duration = Stopwatch.GetElapsedTime(started);
        results[index] = result;
    }

    private async Task<SegmentResult> ExecuteAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken,
        SegmentCachePolicy? cachePolicy)
    {
        if (cachePolicy is null || !cachePolicy.IsCacheable(segment))
        {
            return await ExecuteCoreAsync(segment, context, cancellationToken).ConfigureAwait(false);
        }

        var cacheKey = SegmentCacheKey.Create(segment, context);
        if (cachePolicy.Cache.TryGet(cacheKey, out var cached))
        {
            return cached;
        }

        var result = await ExecuteCoreAsync(segment, context, cancellationToken).ConfigureAwait(false);
        if (result.Status == SegmentStatus.Success)
        {
            var ttl = cachePolicy.ResolveTtl(segment);
            if (ttl > TimeSpan.Zero)
            {
                cachePolicy.Cache.Set(cacheKey, result, ttl);
            }
        }

        return result;
    }

    private async Task<SegmentResult> ExecuteCoreAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken)
    {
        if (!_registry.TryGet(segment.Type, out var provider))
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Failed,
                $"No segment provider registered for type '{segment.Type}'. Registered types: {string.Join(", ", _registry.Types)}.");
        }

        var timeoutMs = ResolveTimeout(segment, provider);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        if (timeoutMs > 0)
        {
            linked.CancelAfter(timeoutMs);
        }

        Task<SegmentResult> work;
        try
        {
            work = provider.GetSegmentAsync(segment, context, linked.Token);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Cancelled, "Prompt rendering was cancelled.");
        }
        catch (Exception exception)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Failed, exception.Message);
        }

        if (work is null)
        {
            return SegmentResult.ErrorResult(
                segment,
                SegmentStatus.Failed,
                $"Segment provider '{provider.Definition.Type}' returned a null task.");
        }

        if (timeoutMs <= 0)
        {
            try
            {
                var result = await work.WaitAsync(cancellationToken).ConfigureAwait(false);
                return cancellationToken.IsCancellationRequested
                    ? SegmentResult.ErrorResult(segment, SegmentStatus.Cancelled, "Prompt rendering was cancelled.")
                    : result;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                return SegmentResult.ErrorResult(segment, SegmentStatus.Cancelled, "Prompt rendering was cancelled.");
            }
            catch (Exception exception)
            {
                return SegmentResult.ErrorResult(segment, SegmentStatus.Failed, exception.Message);
            }
        }

        var timeoutTask = Task.Delay(timeoutMs, cancellationToken);
        var completed = await Task.WhenAny(work, timeoutTask).ConfigureAwait(false);

        if (completed == work)
        {
            try
            {
                var result = await work.ConfigureAwait(false);
                return cancellationToken.IsCancellationRequested
                    ? SegmentResult.ErrorResult(segment, SegmentStatus.Cancelled, "Prompt rendering was cancelled.")
                    : result;
            }
            catch (OperationCanceledException)
            {
                return SegmentResult.ErrorResult(
                    segment,
                    cancellationToken.IsCancellationRequested ? SegmentStatus.Cancelled : SegmentStatus.TimedOut,
                    cancellationToken.IsCancellationRequested
                        ? "Prompt rendering was cancelled."
                        : $"Segment '{segment.Name}' timed out after {timeoutMs} ms.");
            }
            catch (Exception exception)
            {
                return SegmentResult.ErrorResult(segment, SegmentStatus.Failed, exception.Message);
            }
        }

        ObserveAbandoned(work);

        if (cancellationToken.IsCancellationRequested)
        {
            return SegmentResult.ErrorResult(segment, SegmentStatus.Cancelled, "Prompt rendering was cancelled.");
        }

        linked.Cancel();
        return SegmentResult.ErrorResult(
            segment,
            SegmentStatus.TimedOut,
            $"Segment '{segment.Name}' timed out after {timeoutMs} ms.");
    }

    private int ResolveTimeout(PromptSegment segment, ISegmentProvider provider)
    {
        if (segment.TimeoutMs is > 0)
        {
            return segment.TimeoutMs.Value;
        }

        if (provider.Definition.DefaultTimeoutMs > 0)
        {
            return provider.Definition.DefaultTimeoutMs;
        }

        return _options.DefaultTimeoutMs;
    }

    private void ObserveAbandoned(Task<SegmentResult> task)
    {
        if (!_options.ObserveAbandonedTasks)
        {
            return;
        }

        _ = task.ContinueWith(
            static completed => _ = completed.Exception,
            CancellationToken.None,
            TaskContinuationOptions.OnlyOnFaulted | TaskContinuationOptions.ExecuteSynchronously,
            TaskScheduler.Default);
    }
}
