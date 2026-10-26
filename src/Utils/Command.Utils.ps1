# ============================================================
# Pablitus Prompt Framework (PPF)
# Command Utilities
# ============================================================

function Test-CommandExists {

    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)

}

function Invoke-CommandSafe {

    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @()
    )

    if (-not (Test-CommandExists $Command)) {
        return $null
    }

    try {

        $output = & $Command @Arguments 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return ($output | Out-String).Trim()

    }
    catch {

        return $null

    }

}

function Get-CommandVersion {

    param(

        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @("--version")

    )

    return Invoke-CommandSafe `
        -Command $Command `
        -Arguments $Arguments

}

function Invoke-CommandWithTimeout {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @(),

        [int]$TimeoutMs = 1000,

        [string]$WorkingDirectory
    )

    $resolvedCommand = $Command
    $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $commandInfo) {
        return $null
    }
    if ($commandInfo.CommandType -in @('Application', 'ExternalScript')) {
        if ($commandInfo.Path) {
            $resolvedCommand = $commandInfo.Path
        }
        elseif ($commandInfo.Source) {
            $resolvedCommand = $commandInfo.Source
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $resolvedCommand
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    foreach ($argument in $Arguments) {
        [void]$psi.ArgumentList.Add($argument)
    }

    # PowerShell's Set-Location does not change the process working directory,
    # so child processes must receive it explicitly or they run in the
    # directory where pwsh.exe was started.
    $effectiveWorkingDirectory = $WorkingDirectory
    if ([string]::IsNullOrWhiteSpace($effectiveWorkingDirectory)) {
        $location = Get-Location
        if ($location.Provider.Name -eq 'FileSystem') {
            $effectiveWorkingDirectory = $location.ProviderPath
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($effectiveWorkingDirectory)) {
        try {
            $psi.WorkingDirectory = (Resolve-Path -LiteralPath $effectiveWorkingDirectory -ErrorAction Stop).ProviderPath
        }
        catch {
            return [pscustomobject]@{
                ExitCode = -1
                Output   = ""
                Error    = "Working directory not found: $effectiveWorkingDirectory"
                TimedOut = $false
            }
        }
    }

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        if ($null -eq $p) {
            return [pscustomobject]@{
                ExitCode = -1
                Output   = ""
                Error    = "Process could not be started"
                TimedOut = $false
            }
        }

        # Read both streams asynchronously: a full stderr buffer can block
        # the child before it exits and cause false timeouts.
        $stdoutTask = $p.StandardOutput.ReadToEndAsync()
        $stderrTask = $p.StandardError.ReadToEndAsync()

        if ($p.WaitForExit($TimeoutMs)) {
            return [pscustomobject]@{
                ExitCode = $p.ExitCode
                Output   = $stdoutTask.GetAwaiter().GetResult()
                Error    = $stderrTask.GetAwaiter().GetResult()
                TimedOut = $false
            }
        }

        try {
            $p.Kill($true)
        }
        catch {
            try { $p.Kill() } catch { }
        }
        $null = $p.WaitForExit(500)

        return [pscustomobject]@{
            ExitCode = -1
            Output   = ""
            Error    = "Process timed out"
            TimedOut = $true
        }
    }
    catch {
        return [pscustomobject]@{
            ExitCode = -1
            Output   = ""
            Error    = $_.Exception.Message
            TimedOut = $false
        }
    }
    finally {
        if ($null -ne $p) {
            $p.Dispose()
        }
    }
}

# Get-Command performs a full command discovery pass and is comparatively
# expensive (several milliseconds for some applications). Runtime providers
# call it on every render, so resolved paths are memoized and invalidated when
# PATH changes (for example after `nvm use`) or after a short TTL (for tools
# installed into a directory that is already part of PATH).
$script:PPFCommandPathCache = @{}
$script:PPFCommandPathCachePath = $env:PATH
$script:PPFCommandPathCacheTtlMs = 15000

function Get-CommandPath {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $pathSnapshot = $env:PATH
    if ($pathSnapshot -ne $script:PPFCommandPathCachePath) {
        $script:PPFCommandPathCache.Clear()
        $script:PPFCommandPathCachePath = $pathSnapshot
    }

    $nowTicks = [DateTime]::UtcNow.Ticks
    $entry = $script:PPFCommandPathCache[$Command]
    if ($null -ne $entry -and $entry.ExpiresTicks -gt $nowTicks) {
        return $entry.Value
    }

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    $resolved = if ($cmd) { $cmd.Source } else { "" }

    $script:PPFCommandPathCache[$Command] = @{
        Value        = $resolved
        ExpiresTicks = $nowTicks + ($script:PPFCommandPathCacheTtlMs * [TimeSpan]::TicksPerMillisecond)
    }

    return $resolved
}

function Invoke-PPFExternalCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @(),

        [int]$TimeoutMs = 1000,

        [string]$WorkingDirectory
    )

    if (-not (Test-CommandExists $Command)) {
        return [pscustomobject]@{
            ExitCode  = -1
            Output    = $null
            Error     = "CommandNotFoundException"
            TimedOut  = $false
            Installed = $false
        }
    }

    $res = Invoke-CommandWithTimeout -Command $Command -Arguments $Arguments -TimeoutMs $TimeoutMs -WorkingDirectory $WorkingDirectory
    if ($null -eq $res) {
        return [pscustomobject]@{
            ExitCode  = -1
            Output    = $null
            Error     = "Execution failed"
            TimedOut  = $false
            Installed = $true
        }
    }

    return [pscustomobject]@{
        ExitCode  = $res.ExitCode
        # Only trim the trailing newline: leading spaces are significant in
        # output such as `git status --porcelain` (e.g. " M file").
        Output    = if ($null -ne $res.Output) { $res.Output.TrimEnd() } else { $null }
        Error     = $res.Error
        TimedOut  = $res.TimedOut
        Installed = $true
    }
}
