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
        
        [int]$TimeoutMs = 1000
    )

    if (-not (Test-CommandExists $Command)) {
        return $null
    }

    $resolvedCommand = $Command
    $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
    if ($commandInfo -and $commandInfo.CommandType -in @('Application', 'ExternalScript')) {
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

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        if ($p.WaitForExit($TimeoutMs)) {
            $stdout = $p.StandardOutput.ReadToEnd()
            $stderr = $p.StandardError.ReadToEnd()
            return [pscustomobject]@{
                ExitCode = $p.ExitCode
                Output   = $stdout
                Error    = $stderr
                TimedOut = $false
            }
        } else {
            $p.Kill()
            return [pscustomobject]@{
                ExitCode = -1
                Output   = ""
                Error    = "Process timed out"
                TimedOut = $true
            }
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
}

function Get-CommandPath {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    return ""
}

function Invoke-PPFExternalCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @(),

        [int]$TimeoutMs = 1000
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

    $res = Invoke-CommandWithTimeout -Command $Command -Arguments $Arguments -TimeoutMs $TimeoutMs
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
        Output    = if ($res.Output -ne $null) { $res.Output.Trim() } else { $null }
        Error     = $res.Error
        TimedOut  = $res.TimedOut
        Installed = $true
    }
}
