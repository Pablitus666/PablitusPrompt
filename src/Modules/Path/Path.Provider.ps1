# ============================================================
# Pablitus Prompt Framework (PPF)
# Path.Provider.ps1
# ============================================================

function Invoke-PathProvider {

    param(
        [PromptContext]$Context
    )

    $current = (Get-Location).Path
    $userHome = if ($HOME) { $HOME } else { [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile) }

    $friendly = $current

    if (-not [string]::IsNullOrWhiteSpace($userHome)) {
        $trimChars = @([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        $normalizedHome = $userHome.TrimEnd($trimChars)
        $separator = [System.IO.Path]::DirectorySeparatorChar

        # Windows and macOS use case-insensitive file systems by default;
        # Linux paths are case-sensitive.
        $comparison = if ([System.OperatingSystem]::IsWindows() -or [System.OperatingSystem]::IsMacOS()) {
            [System.StringComparison]::OrdinalIgnoreCase
        }
        else {
            [System.StringComparison]::Ordinal
        }

        if ($current.Equals($normalizedHome, $comparison)) {
            $friendly = "~"
        }
        elseif ($current.StartsWith("$normalizedHome$separator", $comparison)) {
            $friendly = "~" + $current.Substring($normalizedHome.Length)
        }
    }

    $Context.Path.Current  = $current
    $Context.Path.Friendly = $friendly

}

Register-PromptProvider `
    -Name "Path" `
    -Priority 200 `
    -Script ${function:Invoke-PathProvider}
