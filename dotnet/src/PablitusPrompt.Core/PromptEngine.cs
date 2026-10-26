using System.Diagnostics;
using System.Text;
using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Rendering;
using PablitusPrompt.Core.Segments;
using PablitusPrompt.Core.Templating;

namespace PablitusPrompt.Core;

public sealed class PromptEngineOptions
{
    public bool UseAnsi { get; set; } = true;

    public string? RendererOverride { get; set; }

    /// <summary>When false, segment results are neither read from nor written to the cache.</summary>
    public bool UseCache { get; set; } = true;

    /// <summary>Terminal width used to compose right prompts. Zero keeps them separate.</summary>
    public int TerminalWidth { get; set; }
}

public sealed class PromptRunResult
{
    public PromptRunResult(
        string output,
        IReadOnlyList<PromptRenderBlock> blocks,
        IReadOnlyList<SegmentResult> segments,
        TimeSpan duration,
        string? rightPrompt = null)
    {
        Output = output;
        Blocks = blocks;
        Segments = segments;
        Duration = duration;
        RightPrompt = rightPrompt;
    }

    /// <summary>Primary prompt. It already includes the right prompt when a width was supplied.</summary>
    public string Output { get; }

    public IReadOnlyList<PromptRenderBlock> Blocks { get; }

    public IReadOnlyList<SegmentResult> Segments { get; }

    public TimeSpan Duration { get; }

    /// <summary>Raw right prompt, without cursor positioning.</summary>
    public string? RightPrompt { get; }
}

public sealed class PromptTooltipResult
{
    public PromptTooltipResult(
        string output,
        string text,
        string? rightPrompt,
        string action,
        IReadOnlyList<string> matchedSegments,
        IReadOnlyList<SegmentResult> segments,
        TimeSpan duration)
    {
        Output = output;
        Text = text;
        RightPrompt = rightPrompt;
        Action = action;
        MatchedSegments = matchedSegments;
        Segments = segments;
        Duration = duration;
    }

    /// <summary>Tooltip with the leading spaces needed to reach the right edge.</summary>
    public string Output { get; }

    /// <summary>Tooltip text before right alignment.</summary>
    public string Text { get; }

    /// <summary>Right prompt text used by <c>extend</c>/<c>prepend</c>.</summary>
    public string? RightPrompt { get; }

    public string Action { get; }

    public IReadOnlyList<string> MatchedSegments { get; }

    public IReadOnlyList<SegmentResult> Segments { get; }

    public TimeSpan Duration { get; }
}

/// <summary>
/// Orchestrates configuration, providers, scheduler and renderer. Right prompts,
/// transient prompts and tooltips are resolved from the same configuration so
/// the CLI and the PowerShell adapter render the same output.
/// </summary>
public sealed class PromptEngine
{
    private readonly SegmentScheduler _scheduler;
    private readonly ISegmentCache? _injectedCache;
    private readonly object _cacheGate = new();
    private InMemorySegmentCache? _segmentCache;

    public PromptEngine(
        TemplateEngine? templates = null,
        SegmentProviderRegistry? registry = null,
        SegmentSchedulerOptions? schedulerOptions = null,
        ISegmentCache? segmentCache = null)
    {
        Templates = templates ?? new TemplateEngine();
        Registry = registry ?? SegmentProviderRegistry.CreateDefault(Templates);
        _scheduler = new SegmentScheduler(Registry, schedulerOptions);
        _injectedCache = segmentCache;
    }

    public TemplateEngine Templates { get; }

    public SegmentProviderRegistry Registry { get; }

    public async Task<PromptRunResult> RenderAsync(
        PpfConfig config,
        PromptContext context,
        PromptEngineOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(config);
        ArgumentNullException.ThrowIfNull(context);
        Validate(config);

        var started = Stopwatch.GetTimestamp();
        var blocks = PromptConfigResolver.Blocks(config);
        var plan = BuildPlan(blocks);
        var results = await ScheduleAsync(
            config,
            plan.Segments,
            context,
            options,
            cancellationToken).ConfigureAwait(false);

        var renderBlocks = BuildRenderBlocks(plan.Plans, results);
        var palette = PromptConfigResolver.Palette(config);
        var finalSpace = config.FinalSpace ?? config.Theme?.FinalSpace ?? true;
        var renderer = RendererFactory.Create(options?.RendererOverride ?? config.Renderer);
        var leftBlocks = renderBlocks.Where(block => !block.IsRightAligned).ToArray();
        var rightBlocks = renderBlocks.Where(block => block.IsRightAligned).ToArray();

        string output;
        string? rightOutput = null;

        if (rightBlocks.Length == 0)
        {
            output = renderer.Render(new PromptRenderModel
            {
                Blocks = renderBlocks,
                FinalSpace = finalSpace,
                UseAnsi = options?.UseAnsi ?? true,
                Palette = palette,
            });
        }
        else
        {
            rightOutput = RenderBlockSet(
                renderer,
                rightBlocks,
                palette,
                useAnsi: options?.UseAnsi ?? true,
                finalSpace: false).TrimEnd();

            var leftOutput = RenderBlockSet(
                renderer,
                leftBlocks,
                palette,
                useAnsi: options?.UseAnsi ?? true,
                finalSpace: false);

            if (finalSpace)
            {
                leftOutput += " ";
            }

            var terminalWidth = options?.TerminalWidth ?? 0;
            if (terminalWidth <= 0 || rightOutput.Length == 0)
            {
                output = leftOutput;
            }
            else
            {
                var rightConfig = rightBlocks.FirstOrDefault(block => !string.IsNullOrWhiteSpace(block.Filler)) ??
                                  rightBlocks[0];
                Func<int, string>? fillerFactory = null;
                if (!string.IsNullOrWhiteSpace(rightConfig.Filler))
                {
                    fillerFactory = padding => RenderFiller(
                        rightConfig.Filler!,
                        padding,
                        rightConfig.Overflow,
                        context);
                }

                output = PromptLayout.Compose(
                    leftOutput,
                    rightOutput,
                    terminalWidth,
                    rightConfig.Overflow,
                    fillerFactory,
                    options?.UseAnsi ?? true);
            }
        }

        return new PromptRunResult(
            output,
            renderBlocks,
            results,
            Stopwatch.GetElapsedTime(started),
            rightOutput);
    }

    /// <summary>
    /// Renders the replacement prompt. Returns <c>null</c> when the configuration
    /// does not define a transient prompt, so callers can keep the primary one.
    /// </summary>
    public string? RenderTransient(
        PpfConfig config,
        PromptContext context,
        PromptEngineOptions? options = null)
    {
        ArgumentNullException.ThrowIfNull(config);
        ArgumentNullException.ThrowIfNull(context);
        Validate(config);

        var transient = PromptConfigResolver.Transient(config);
        if (transient is null)
        {
            return null;
        }

        var terminalWidth = options?.TerminalWidth ?? context.TerminalWidth;
        var transientContext = new PromptContext
        {
            UserName = context.UserName,
            HostName = context.HostName,
            Path = context.Path,
            Session = context.Session,
            Git = context.Git,
            Timestamp = context.Timestamp,
            ExitCode = context.ExitCode,
            Shell = context.Shell,
            CommandLine = context.CommandLine,
            TerminalWidth = terminalWidth,
            Column = context.Column,
            Interrupted = context.Interrupted,
            Properties = context.Properties,
        };

        var template = string.IsNullOrEmpty(transient.Template)
            ? "{{ .Shell }}> "
            : transient.Template;
        var left = Templates.Render(template, transientContext);
        var right = string.IsNullOrEmpty(transient.RightTemplate)
            ? string.Empty
            : Templates.Render(transient.RightTemplate, transientContext);

        var palette = PromptConfigResolver.Palette(config);
        var useAnsi = options?.UseAnsi ?? true;
        left = ApplyColors(left, transient.Foreground, transient.Background, palette, useAnsi);
        right = ApplyColors(right, transient.Foreground, transient.Background, palette, useAnsi);

        if (terminalWidth > 0 &&
            (!string.IsNullOrEmpty(right) || !string.IsNullOrWhiteSpace(transient.Filler)))
        {
            left = ComposeTransient(
                left,
                right,
                terminalWidth,
                transient.Filler,
                transientContext,
                useAnsi);
        }

        return transient.Newline ? Environment.NewLine + left : left;
    }

    /// <summary>
    /// Renders the tooltip matching the first command word. The returned output
    /// starts with the spaces needed to place it at the right edge.
    /// </summary>
    public async Task<PromptTooltipResult> RenderTooltipAsync(
        PpfConfig config,
        PromptContext context,
        string? commandLine = null,
        int terminalWidth = 0,
        int column = 0,
        PromptEngineOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(config);
        ArgumentNullException.ThrowIfNull(context);
        Validate(config);

        var started = Stopwatch.GetTimestamp();
        var action = PromptConfigResolver.TooltipsAction(config);
        var command = FirstCommandWord(commandLine ?? context.CommandLine);
        var tooltips = PromptConfigResolver.Tooltips(config);

        if (command.Length == 0 || tooltips.Count == 0)
        {
            return EmptyTooltip(action, Stopwatch.GetElapsedTime(started));
        }

        var matched = tooltips
            .Where(tooltip => tooltip.Tips.Any(tip =>
                string.Equals(tip, command, StringComparison.OrdinalIgnoreCase)))
            .ToArray();

        if (matched.Length == 0)
        {
            return EmptyTooltip(action, Stopwatch.GetElapsedTime(started));
        }

        var tooltipSegments = new List<PromptSegment>(matched.Length);
        for (var index = 0; index < matched.Length; index++)
        {
            tooltipSegments.Add(PromptSegment.FromConfig(matched[index], int.MaxValue, index));
        }

        var results = await ScheduleAsync(
            config,
            tooltipSegments,
            context,
            options,
            cancellationToken).ConfigureAwait(false);

        var palette = PromptConfigResolver.Palette(config);
        var useAnsi = options?.UseAnsi ?? true;
        var renderer = RendererFactory.Create(options?.RendererOverride ?? config.Renderer);
        var tooltipBlock = new PromptRenderBlock
        {
            Segments = results,
            Alignment = "right",
            Type = "rprompt",
        };

        var tooltipText = RenderBlockSet(
            renderer,
            new[] { tooltipBlock },
            palette,
            useAnsi,
            finalSpace: false).TrimEnd();

        string? rightText = null;
        if (!action.Equals("replace", StringComparison.OrdinalIgnoreCase))
        {
            var rightBlocks = PromptConfigResolver.Blocks(config)
                .Where(block => IsRightAligned(block))
                .ToArray();

            if (rightBlocks.Length > 0)
            {
                var rightPlan = BuildPlan(rightBlocks);
                var rightResults = await ScheduleAsync(
                    config,
                    rightPlan.Segments,
                    context,
                    options,
                    cancellationToken).ConfigureAwait(false);
                var renderRight = BuildRenderBlocks(rightPlan.Plans, rightResults);
                rightText = RenderBlockSet(
                    renderer,
                    renderRight,
                    palette,
                    useAnsi,
                    finalSpace: false).TrimEnd();
            }
        }

        var text = action.Equals("replace", StringComparison.OrdinalIgnoreCase)
            ? tooltipText
            : action.Equals("prepend", StringComparison.OrdinalIgnoreCase)
                ? tooltipText + (rightText ?? string.Empty)
                : (rightText ?? string.Empty) + tooltipText;

        var width = terminalWidth > 0 ? terminalWidth : context.TerminalWidth;
        var cursorColumn = column > 0 ? column : context.Column;
        var output = PromptLayout.RightAlign(text, width, cursorColumn);

        return new PromptTooltipResult(
            output,
            text,
            rightText,
            action,
            matched
                .Select((tooltip, index) => string.IsNullOrWhiteSpace(tooltip.Name)
                    ? $"tooltip:{index}"
                    : tooltip.Name!)
                .ToArray(),
            results,
            Stopwatch.GetElapsedTime(started));
    }

    private static void Validate(PpfConfig config)
    {
        var validationErrors = PpfConfigValidator.Validate(config);
        if (validationErrors.Count > 0)
        {
            throw PpfConfigurationException.FromErrors(null, validationErrors);
        }
    }

    private static string RenderBlockSet(
        IRenderer renderer,
        IReadOnlyList<PromptRenderBlock> blocks,
        IReadOnlyDictionary<string, string> palette,
        bool useAnsi,
        bool finalSpace) =>
        renderer.Render(new PromptRenderModel
        {
            Blocks = blocks,
            FinalSpace = finalSpace,
            UseAnsi = useAnsi,
            Palette = palette,
        });

    private static bool IsRightAligned(BlockConfig block) =>
        block.Type.Equals("rprompt", StringComparison.OrdinalIgnoreCase) ||
        block.Alignment.Equals("right", StringComparison.OrdinalIgnoreCase);

    private static string FirstCommandWord(string? commandLine)
    {
        if (string.IsNullOrWhiteSpace(commandLine))
        {
            return string.Empty;
        }

        var trimmed = commandLine.TrimStart();
        var separator = trimmed.IndexOfAny(new[] { ' ', '\t', '\r', '\n' });
        return separator < 0 ? trimmed : trimmed[..separator];
    }

    private static PromptTooltipResult EmptyTooltip(string action, TimeSpan duration) =>
        new(
            string.Empty,
            string.Empty,
            null,
            action,
            Array.Empty<string>(),
            Array.Empty<SegmentResult>(),
            duration);

    private string ComposeTransient(
        string left,
        string right,
        int terminalWidth,
        string? fillerTemplate,
        PromptContext context,
        bool useAnsi)
    {
        var leftWidth = PromptLayout.MeasureLastLine(left);
        var rightWidth = PromptLayout.Measure(right);
        var available = terminalWidth - leftWidth - rightWidth;
        if (available < 0)
        {
            return left + right;
        }

        var filler = string.Empty;
        if (!string.IsNullOrWhiteSpace(fillerTemplate))
        {
            var source = RenderFiller(fillerTemplate, available, null, context);
            filler = PromptLayout.Fit(source, available);
        }

        if (filler.Length == 0 && right.Length == 0)
        {
            filler = new string(' ', Math.Max(0, available));
        }
        else if (filler.Length == 0 && right.Length > 0)
        {
            filler = new string(' ', Math.Max(0, available));
        }

        return useAnsi || filler.Length > 0
            ? left + filler + right
            : left + right;
    }

    private string RenderFiller(
        string template,
        int padding,
        string? overflow,
        PromptContext context)
    {
        var fillerContext = new FillerTemplateContext
        {
            Padding = padding,
            Overflow = overflow ?? string.Empty,
            Shell = context.Shell,
            CommandLine = context.CommandLine,
            TerminalWidth = context.TerminalWidth,
        };

        return Templates.Render(template, fillerContext);
    }

    private static string ApplyColors(
        string text,
        string? foreground,
        string? background,
        IReadOnlyDictionary<string, string> palette,
        bool useAnsi)
    {
        if (!useAnsi || text.Length == 0)
        {
            return text;
        }

        var resolver = new ColorResolver(palette);
        var backgroundValue = resolver.Resolve(background);
        var foregroundValue = resolver.Resolve(foreground) ??
                              (backgroundValue is null ? null : AnsiColor.ContrastFor(backgroundValue.Value));

        if (foregroundValue is null && backgroundValue is null)
        {
            return text;
        }

        var builder = new StringBuilder(text.Length + 16);
        if (foregroundValue is not null)
        {
            builder.Append(foregroundValue.Value.ToForegroundEscape());
        }

        if (backgroundValue is not null)
        {
            builder.Append(backgroundValue.Value.ToBackgroundEscape());
        }

        builder.Append(text);
        builder.Append(AnsiCodes.Reset);
        return builder.ToString();
    }

    private static BlockPlanSet BuildPlan(IReadOnlyList<BlockConfig> blocks)
    {
        var plans = new List<BlockPlan>(blocks.Count);
        var segments = new List<PromptSegment>();

        for (var blockIndex = 0; blockIndex < blocks.Count; blockIndex++)
        {
            var block = blocks[blockIndex];
            var start = segments.Count;

            for (var segmentIndex = 0; segmentIndex < block.Segments.Count; segmentIndex++)
            {
                var definition = PromptSegment.FromConfig(block.Segments[segmentIndex], blockIndex, segmentIndex);
                if (definition.Enabled)
                {
                    segments.Add(definition);
                }
            }

            plans.Add(new BlockPlan(block, start, segments.Count - start));
        }

        return new BlockPlanSet(plans, segments);
    }

    private static List<PromptRenderBlock> BuildRenderBlocks(
        IReadOnlyList<BlockPlan> plans,
        IReadOnlyList<SegmentResult> results)
    {
        var renderBlocks = new List<PromptRenderBlock>(plans.Count);
        foreach (var plan in plans)
        {
            var blockResults = new SegmentResult[plan.Count];
            for (var index = 0; index < plan.Count; index++)
            {
                blockResults[index] = results[plan.Start + index];
            }

            renderBlocks.Add(new PromptRenderBlock
            {
                Segments = blockResults,
                Newline = plan.Block.Newline,
                Alignment = plan.Block.Alignment,
                Type = plan.Block.Type,
                Filler = plan.Block.Filler,
                Overflow = plan.Block.Overflow,
            });
        }

        return renderBlocks;
    }

    private async Task<IReadOnlyList<SegmentResult>> ScheduleAsync(
        PpfConfig config,
        IReadOnlyList<PromptSegment> segments,
        PromptContext context,
        PromptEngineOptions? options,
        CancellationToken cancellationToken)
    {
        var cachePolicy = ResolveCachePolicy(config, options);
        return await _scheduler
            .ScheduleAsync(segments, context, cancellationToken, cachePolicy)
            .ConfigureAwait(false);
    }

    private SegmentCachePolicy? ResolveCachePolicy(PpfConfig config, PromptEngineOptions? options)
    {
        if (config.Cache is not { Enabled: true } cacheConfig || options?.UseCache == false)
        {
            return null;
        }

        ISegmentCache cache;
        if (_injectedCache is not null)
        {
            cache = _injectedCache;
        }
        else
        {
            lock (_cacheGate)
            {
                _segmentCache ??= new InMemorySegmentCache(cacheConfig.MaxEntries);
                _segmentCache.MaxEntries = cacheConfig.MaxEntries;
                cache = _segmentCache;
            }
        }

        return new SegmentCachePolicy(cache, TimeSpan.FromSeconds(cacheConfig.TtlSeconds));
    }

    private sealed record BlockPlan(BlockConfig Block, int Start, int Count);

    private sealed record BlockPlanSet(List<BlockPlan> Plans, List<PromptSegment> Segments);

    private sealed class FillerTemplateContext
    {
        public int Padding { get; init; }

        public string Overflow { get; init; } = string.Empty;

        public string Shell { get; init; } = "pwsh";

        public string CommandLine { get; init; } = string.Empty;

        public int TerminalWidth { get; init; }
    }
}

internal static class PromptConfigResolver
{
    public static IReadOnlyList<BlockConfig> Blocks(PpfConfig config) =>
        config.Theme?.Blocks ?? config.Blocks;

    public static IReadOnlyDictionary<string, string> Palette(PpfConfig config) =>
        config.Theme?.Palette ??
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    public static TransientPromptConfig? Transient(PpfConfig config)
    {
        var transient = config.TransientPrompt ?? config.Theme?.TransientPrompt;
        if (transient is not null)
        {
            return transient;
        }

        var template = config.Template?.TransientPrompt ?? config.Theme?.Template?.TransientPrompt;
        return string.IsNullOrEmpty(template)
            ? null
            : new TransientPromptConfig { Template = template };
    }

    public static IReadOnlyList<TooltipConfig> Tooltips(PpfConfig config)
    {
        if (config.Tooltips.Count > 0)
        {
            return config.Tooltips;
        }

        return config.Theme?.Tooltips ?? new List<TooltipConfig>();
    }

    public static string TooltipsAction(PpfConfig config) =>
        FirstNonEmpty(config.TooltipsAction, config.Theme?.TooltipsAction) ?? "replace";

    private static string? FirstNonEmpty(string? first, string? second) =>
        string.IsNullOrWhiteSpace(first) ? second : first;
}
