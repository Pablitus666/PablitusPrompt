// ============================================================
// Pablitus Prompt Framework (PPF)
// PpfPowerShellPluginHost.cs
//
// Runtime-compiled bridge used by Prompt.DotNet.ps1. It keeps the
// .NET core free of a System.Management.Automation dependency while
// still allowing user segment scriptblocks to run in an isolated
// PowerShell runspace.
// ============================================================

using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Threading.Tasks;
using PablitusPrompt.Core.Segments;

namespace PablitusPrompt.Integrations
{
    /// <summary>
    /// Segment provider that executes one registered PowerShell segment
    /// scriptblock in a dedicated runspace pool. The pool imports the PPF
    /// module once and serializes plugin execution.
    /// </summary>
    public sealed class PpfPowerShellSegmentProvider : ISegmentProvider, IDisposable
    {
        private const string ResultTypeName = "PablitusPrompt.PluginResult";

        private readonly string _modulePath;
        private readonly string _pluginName;
        private readonly string _pluginScript;
        private readonly string _invocationScript;
        private readonly string _initializationScript;

        private RunspacePool _pool;
        private bool _disposed;

        public PpfPowerShellSegmentProvider(
            string type,
            string displayName,
            string modulePath,
            string pluginName,
            string pluginScript,
            string invocationScript,
            string initializationScript,
            int defaultTimeoutMs)
        {
            if (string.IsNullOrWhiteSpace(type))
            {
                throw new ArgumentException("The segment type cannot be empty.", nameof(type));
            }

            if (string.IsNullOrWhiteSpace(modulePath))
            {
                throw new ArgumentException("The module path cannot be empty.", nameof(modulePath));
            }

            if (string.IsNullOrWhiteSpace(invocationScript))
            {
                throw new ArgumentException("The invocation script cannot be empty.", nameof(invocationScript));
            }

            Definition = new SegmentDefinition
            {
                Type = type.Trim(),
                DisplayName = string.IsNullOrWhiteSpace(displayName) ? type.Trim() : displayName,
                DefaultTimeoutMs = defaultTimeoutMs > 0 ? defaultTimeoutMs : 2000,
            };

            _modulePath = modulePath;
            _pluginName = string.IsNullOrWhiteSpace(pluginName) ? type.Trim() : pluginName;
            _pluginScript = pluginScript ?? string.Empty;
            _invocationScript = invocationScript;
            _initializationScript = initializationScript ?? string.Empty;
        }

        public SegmentDefinition Definition { get; }

        public Task<SegmentResult> GetSegmentAsync(
            PromptSegment segment,
            PromptContext context,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(segment);
            ArgumentNullException.ThrowIfNull(context);

            if (cancellationToken.IsCancellationRequested)
            {
                return Task.FromResult(SegmentResult.ErrorResult(
                    segment,
                    SegmentStatus.Cancelled,
                    "Prompt rendering was cancelled."));
            }

            return Task.Run(
                () => InvokeCore(segment, context, cancellationToken),
                CancellationToken.None);
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _disposed = true;
            var pool = _pool;
            if (pool == null)
            {
                return;
            }

            try
            {
                pool.Dispose();
            }
            catch
            {
                // Disposal is best effort during module/session shutdown.
            }
        }

        private RunspacePool GetPool()
        {
            var pool = _pool;
            if (pool != null)
            {
                return pool;
            }

            pool = CreatePool();
            _pool = pool;
            return pool;
        }

        private RunspacePool CreatePool()
        {
            var pool = RunspaceFactory.CreateRunspacePool(InitialSessionState.CreateDefault());
            pool.SetMinRunspaces(1);
            pool.SetMaxRunspaces(1);

            try
            {
                pool.Open();

                using (var shell = PowerShell.Create())
                {
                    shell.RunspacePool = pool;
                    shell.AddScript(_initializationScript, useLocalScope: true);
                    shell.AddArgument(_modulePath);
                    shell.Invoke();

                    if (shell.HadErrors)
                    {
                        throw new InvalidOperationException(DescribeErrors(shell.Streams.Error));
                    }
                }

                return pool;
            }
            catch
            {
                try
                {
                    pool.Dispose();
                }
                catch
                {
                    // Preserve the original startup error.
                }

                throw;
            }
        }

        private SegmentResult InvokeCore(
            PromptSegment segment,
            PromptContext context,
            CancellationToken cancellationToken)
        {
            if (_disposed)
            {
                return SegmentResult.ErrorResult(
                    segment,
                    SegmentStatus.Failed,
                    "The PowerShell plugin provider has been disposed.");
            }

            if (cancellationToken.IsCancellationRequested)
            {
                return SegmentResult.ErrorResult(
                    segment,
                    SegmentStatus.Cancelled,
                    "Prompt rendering was cancelled.");
            }

            RunspacePool pool;
            try
            {
                pool = GetPool();
            }
            catch (Exception exception)
            {
                return SegmentResult.ErrorResult(
                    segment,
                    SegmentStatus.Failed,
                    "PowerShell plugin host failed to start: " + exception.Message);
            }

            var shell = PowerShell.Create();
            shell.RunspacePool = pool;
            var stopInBackground = false;

            try
            {
                shell.AddScript(_invocationScript, useLocalScope: true);
                shell.AddArgument(context);
                shell.AddArgument(segment);
                shell.AddArgument(_pluginName);
                shell.AddArgument(_pluginScript);

                var async = shell.BeginInvoke();
                var completed = WaitHandle.WaitAny(
                    new[] { async.AsyncWaitHandle, cancellationToken.WaitHandle });

                if (completed == 1)
                {
                    stopInBackground = true;
                    StopInBackground(shell);

                    // Let the scheduler decide whether this was an external
                    // cancellation (Cancelled) or a per-segment timeout
                    // (TimedOut). It owns the linked token and the timeout.
                    throw new OperationCanceledException(
                        "The PowerShell plugin execution was cancelled.",
                        cancellationToken);
                }

                PSDataCollection<PSObject> output;
                try
                {
                    output = shell.EndInvoke(async);
                }
                catch (Exception exception)
                {
                    return SegmentResult.ErrorResult(
                        segment,
                        SegmentStatus.Failed,
                        exception.Message);
                }

                var result = FindResult(output);
                if (result != null)
                {
                    return MapResult(result, segment);
                }

                if (shell.Streams.Error.Count > 0)
                {
                    return SegmentResult.ErrorResult(
                        segment,
                        SegmentStatus.Failed,
                        DescribeErrors(shell.Streams.Error));
                }

                return new SegmentResult
                {
                    Name = segment.Name,
                    Type = segment.Type,
                    Text = string.Empty,
                    Icon = segment.Icon,
                    Foreground = segment.Foreground,
                    Background = segment.Background,
                    Style = segment.Style,
                    LeadingDiamond = segment.LeadingDiamond,
                    TrailingDiamond = segment.TrailingDiamond,
                    Visible = false,
                    Status = SegmentStatus.Success,
                };
            }
            catch (Exception exception)
            {
                return SegmentResult.ErrorResult(
                    segment,
                    SegmentStatus.Failed,
                    exception.Message);
            }
            finally
            {
                if (!stopInBackground)
                {
                    shell.Dispose();
                }
            }
        }

        private static void StopInBackground(PowerShell shell)
        {
            // Stop() can block when a plugin ignores cancellation. The prompt
            // has already timed out, so the caller must not wait for it.
            _ = Task.Run(() =>
            {
                try
                {
                    shell.Stop();
                }
                catch
                {
                    // The pipeline may already have completed.
                }

                try
                {
                    shell.Dispose();
                }
                catch
                {
                    // Disposal is best effort.
                }
            });
        }

        private static PSObject FindResult(PSDataCollection<PSObject> output)
        {
            foreach (var item in output)
            {
                if (item == null)
                {
                    continue;
                }

                if (item.TypeNames.Contains(ResultTypeName))
                {
                    return item;
                }

                if (item.BaseObject is PSObject inner && inner.TypeNames.Contains(ResultTypeName))
                {
                    return inner;
                }
            }

            return null;
        }

        private static SegmentResult MapResult(PSObject result, PromptSegment segment)
        {
            var text = GetString(result, "Text") ?? string.Empty;
            var visible = GetBool(result, "Visible") ?? (text.Length > 0);
            var status = ParseStatus(GetString(result, "Status"));

            if (status != SegmentStatus.Success)
            {
                visible = false;
            }

            return new SegmentResult
            {
                Name = segment.Name,
                Type = segment.Type,
                Text = text,
                Icon = Coalesce(GetString(result, "Icon"), segment.Icon),
                Foreground = Coalesce(GetString(result, "Foreground"), segment.Foreground),
                Background = Coalesce(GetString(result, "Background"), segment.Background),
                Style = segment.Style,
                LeadingDiamond = segment.LeadingDiamond,
                TrailingDiamond = segment.TrailingDiamond,
                Visible = visible,
                Status = status,
                Error = GetString(result, "Error"),
            };
        }

        private static string Coalesce(string value, string fallback)
        {
            return string.IsNullOrEmpty(value) ? fallback : value;
        }

        private static string DescribeErrors(PSDataCollection<ErrorRecord> errors)
        {
            var messages = new string[errors.Count];
            for (var index = 0; index < errors.Count; index++)
            {
                messages[index] = errors[index].ToString();
            }

            return string.Join(Environment.NewLine, messages);
        }

        private static string GetString(PSObject result, string name)
        {
            var property = result.Properties[name];
            if (property == null || property.Value == null)
            {
                return null;
            }

            return property.Value.ToString();
        }

        private static bool? GetBool(PSObject result, string name)
        {
            var property = result.Properties[name];
            if (property == null || property.Value == null)
            {
                return null;
            }

            if (property.Value is bool value)
            {
                return value;
            }

            if (bool.TryParse(property.Value.ToString(), out var parsed))
            {
                return parsed;
            }

            return null;
        }

        private static SegmentStatus ParseStatus(string status)
        {
            if (string.IsNullOrWhiteSpace(status))
            {
                return SegmentStatus.Success;
            }

            return Enum.TryParse(status, ignoreCase: true, out SegmentStatus parsed)
                ? parsed
                : SegmentStatus.Success;
        }
    }
}
