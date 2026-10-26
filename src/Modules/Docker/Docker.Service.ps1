# ============================================================
# Pablitus Prompt Framework (PPF)
# Docker.Service.ps1
# ============================================================

function Get-DockerInfo {

    # Fast daemon availability check without spawning processes
    $daemonAvailable = $false
    if ($env:DOCKER_HOST) {
        $daemonAvailable = $true
    }
    elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        # Test-Path does not reliably detect named pipes; enumerate the pipe
        # namespace instead.
        try {
            $expectedPipes = @('docker_engine', 'dockerDesktopLinuxEngine', 'dockerDesktopWindowsEngine')
            $pipeNames = [System.IO.Directory]::GetFiles('\\.\pipe\') |
                ForEach-Object { [System.IO.Path]::GetFileName($_) }
            foreach ($expectedPipe in $expectedPipes) {
                if ($pipeNames -contains $expectedPipe) {
                    $daemonAvailable = $true
                    break
                }
            }
        }
        catch {
            $daemonAvailable = $false
        }
    }
    else {
        $daemonAvailable = [System.IO.File]::Exists("/var/run/docker.sock") -or [System.IO.File]::Exists("$env:HOME/.docker/run/docker.sock")
    }

    if (-not $daemonAvailable) {
        return [pscustomobject]@{ Active = $false; Count = 0 }
    }

    $dockerCfg = Get-SegmentConfiguration -Name "Docker"
    $timeoutMs = if ($dockerCfg -and $dockerCfg.ContainsKey("TimeoutMs")) { [int]$dockerCfg["TimeoutMs"] } else { 100 }
    if ($timeoutMs -le 0) { $timeoutMs = 100 }

    # Run docker ps -q with timeout
    $res = Invoke-PPFExternalCommand -Command "docker" -Arguments @("ps", "-q") -TimeoutMs $timeoutMs
    if ($null -eq $res -or -not $res.Installed -or $res.TimedOut -or $res.ExitCode -ne 0 -or $null -eq $res.Output) {
        return [pscustomobject]@{ Active = $false; Count = 0 }
    }

    $lines = $res.Output -split "`r?`n" | Where-Object { $_.Trim() }
    return [pscustomobject]@{
        Active = $true
        Count  = @($lines).Count
    }

}

