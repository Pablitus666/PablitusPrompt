namespace PablitusPrompt.Core.Rendering;

public static class RendererFactory
{
    public static IReadOnlyList<string> SupportedRenderers { get; } = new[] { "plain", "powerline" };

    public static IRenderer Create(string? name) =>
        (name ?? "plain").Trim().ToLowerInvariant() switch
        {
            "plain" or "" => new PlainRenderer(),
            "powerline" => new PowerLineRenderer(),
            _ => throw new ArgumentException(
                $"Unknown renderer '{name}'. Supported renderers: {string.Join(", ", SupportedRenderers)}.",
                nameof(name)),
        };
}
