namespace PablitusPrompt.Core.Omp;

/// <summary>Raised when an Oh My Posh theme cannot be imported unambiguously.</summary>
public sealed class OmpImportException : Exception
{
    public OmpImportException(string message, string? path = null, Exception? innerException = null)
        : base(path is null ? message : $"{message} (at {path})", innerException)
    {
        Path = path;
    }

    public string? Path { get; }
}
