namespace PablitusPrompt.Core.Segments;

/// <summary>
/// Creates a prompt context from the current process environment. Git branch
/// discovery reads <c>.git/HEAD</c> directly; it never starts a shell process.
/// </summary>
public static class PromptContextFactory
{
    public static PromptContext Create(
        string? workingDirectory = null,
        int exitCode = 0,
        int terminalWidth = 0,
        string? commandLine = null,
        bool interrupted = false,
        int column = 0)
    {
        var current = ResolveWorkingDirectory(workingDirectory);
        var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        var userName = Environment.UserName;
        var hostName = Environment.MachineName;
        var shell = "pwsh";

        return new PromptContext
        {
            UserName = userName,
            HostName = hostName,
            Shell = shell,
            ExitCode = exitCode,
            Timestamp = DateTimeOffset.Now,
            TerminalWidth = terminalWidth,
            CommandLine = commandLine ?? string.Empty,
            Interrupted = interrupted,
            Column = column,
            Path = new PathContext
            {
                Current = current,
                Display = BuildDisplayPath(current, home),
                Folder = GetFolderName(current),
                IsHome = PathsEqual(current, home),
            },
            Session = new SessionContext
            {
                UserName = userName,
                HostName = hostName,
                Shell = shell,
            },
            Git = ReadGitContext(current),
        };
    }

    private static string ResolveWorkingDirectory(string? workingDirectory)
    {
        if (!string.IsNullOrWhiteSpace(workingDirectory))
        {
            try
            {
                return Path.GetFullPath(workingDirectory);
            }
            catch (Exception exception) when (exception is ArgumentException or NotSupportedException or PathTooLongException)
            {
                // Fall back to the process directory for malformed input.
            }
        }

        return Environment.CurrentDirectory;
    }

    private static string BuildDisplayPath(string current, string home)
    {
        if (string.IsNullOrEmpty(home))
        {
            return current;
        }

        var normalizedCurrent = current.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var normalizedHome = home.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);

        if (string.Equals(normalizedCurrent, normalizedHome, StringComparison.OrdinalIgnoreCase))
        {
            return "~";
        }

        if (normalizedCurrent.StartsWith(normalizedHome + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
        {
            return "~" + normalizedCurrent[normalizedHome.Length..];
        }

        return current;
    }

    private static string GetFolderName(string path)
    {
        var trimmed = path.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var name = Path.GetFileName(trimmed);
        return string.IsNullOrEmpty(name) ? trimmed : name;
    }

    private static bool PathsEqual(string left, string right)
    {
        if (string.IsNullOrEmpty(left) || string.IsNullOrEmpty(right))
        {
            return false;
        }

        var comparison = OperatingSystem.IsWindows()
            ? StringComparison.OrdinalIgnoreCase
            : StringComparison.Ordinal;

        return string.Equals(
            left.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar),
            right.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar),
            comparison);
    }

    private static GitContext ReadGitContext(string workingDirectory)
    {
        try
        {
            var gitDirectory = FindGitDirectory(workingDirectory);
            if (gitDirectory is null)
            {
                return new GitContext();
            }

            var headPath = Path.Combine(gitDirectory, "HEAD");
            if (!File.Exists(headPath))
            {
                return new GitContext();
            }

            var head = File.ReadAllText(headPath).Trim();
            var branch = head.StartsWith("ref:", StringComparison.Ordinal)
                ? head["ref:".Length..].Trim()
                : head;

            const string headsPrefix = "refs/heads/";
            if (branch.StartsWith(headsPrefix, StringComparison.Ordinal))
            {
                branch = branch[headsPrefix.Length..];
            }

            if (branch.Length > 7 && branch.All(IsHexCharacter))
            {
                branch = branch[..7];
            }

            return new GitContext { Branch = branch };
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            return new GitContext();
        }
    }

    private static string? FindGitDirectory(string start)
    {
        var current = new DirectoryInfo(start);
        while (current is not null)
        {
            var dotGit = Path.Combine(current.FullName, ".git");
            if (Directory.Exists(dotGit))
            {
                return dotGit;
            }

            if (File.Exists(dotGit))
            {
                // Worktrees and submodules use a .git file pointing at the real directory.
                var content = File.ReadAllText(dotGit).Trim();
                const string prefix = "gitdir:";
                if (content.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    var target = content[prefix.Length..].Trim();
                    if (!Path.IsPathRooted(target))
                    {
                        target = Path.GetFullPath(Path.Combine(current.FullName, target));
                    }

                    if (Directory.Exists(target))
                    {
                        return target;
                    }
                }
            }

            current = current.Parent;
        }

        return null;
    }

    private static bool IsHexCharacter(char character) =>
        character is >= '0' and <= '9' or >= 'a' and <= 'f' or >= 'A' and <= 'F';
}
