namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Collects the data for one segment type and renders its template. Providers
/// must not throw for missing data; they return an invisible result instead.
/// Unexpected exceptions are captured by the scheduler.
/// </summary>
public interface ISegmentProvider
{
    SegmentDefinition Definition { get; }

    Task<SegmentResult> GetSegmentAsync(
        PromptSegment segment,
        PromptContext context,
        CancellationToken cancellationToken = default);
}
