# ============================================================
# Pablitus Prompt Framework (PPF)
# CPU.Service.ps1
# ============================================================

# Thread-safe container for CPU metrics
if ($null -eq $global:PPF_CpuSharedData) {
    $global:PPF_CpuSharedData = [hashtable]::Synchronized(@{
        Usage = 0
        Stopped = $false
        IterationCount = 0
        UpdateDurationMs = 0.0
        LastUpdateTime = $null
    })
}

function Start-CpuSampler {

    # Recreate the shared container if a consumer (or a test) cleared it.
    if ($null -eq $global:PPF_CpuSharedData) {
        $global:PPF_CpuSharedData = [hashtable]::Synchronized(@{
            Usage = 0
            Stopped = $false
            IterationCount = 0
            UpdateDurationMs = 0.0
            LastUpdateTime = $null
        })
    }

    # Verify if the runspace is already running before changing the stop flag:
    # resetting it first could revive a loop that is already exiting.
    $alreadyRunning = $false
    if ($null -ne $global:PPF_CpuRunspace) {
        try {
            if ($global:PPF_CpuRunspace.RunspaceStateInfo.State -eq 'Opened') {
                if ($null -ne $global:PPF_CpuPowerShell) {
                    $state = $global:PPF_CpuPowerShell.InvocationStateInfo.State
                    $alreadyRunning = $state -in @('Running', 'NotStarted')
                }
                else {
                    # Untracked open runspace: assume it is in use to avoid duplicates.
                    $alreadyRunning = $true
                }
            }
        }
        catch {}
    }

    if ($alreadyRunning) {
        # A tracked live sampler must not be revived after Stop-CpuSampler set
        # the flag. Untracked runspaces are assumed to be in use, so their
        # state is normalised without spawning a duplicate sampler.
        if ($null -eq $global:PPF_CpuPowerShell -and $global:PPF_CpuSharedData.Stopped) {
            $global:PPF_CpuSharedData.Stopped = $false
        }
        return
    }

    # A previous sampler that completed or failed is no longer running.
    # Dispose it before replacing the globals so its runspace is not leaked.
    if ($null -ne $global:PPF_CpuPowerShell -or $null -ne $global:PPF_CpuRunspace) {
        Stop-CpuSampler
    }

    if ($global:PPF_CpuSharedData.Stopped) {
        $global:PPF_CpuSharedData.Stopped = $false
    }

    $rs = $null
    $ps = $null

    try {
        # Retrieve interval from framework configuration
        $interval = 2
        try {
            if (Get-Command Get-PromptConfiguration -ErrorAction SilentlyContinue) {
                $config = Get-PromptConfiguration
                if ($null -ne $config -and $null -ne $config.Performance -and $config.Performance.ContainsKey("CpuSampleInterval")) {
                    $interval = [int]$config.Performance["CpuSampleInterval"]
                }
            }
        } catch {}

        if ($interval -le 0) { $interval = 2 }

        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $rs.Open()
        $rs.SessionStateProxy.SetVariable('CpuSharedData', $global:PPF_CpuSharedData)
        $rs.SessionStateProxy.SetVariable('SampleIntervalSec', $interval)

        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs

        $null = $ps.AddScript({
            $previousCpuSample = $null

            while (-not $CpuSharedData.Stopped) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                $usage = $null
                try {
                    if ([System.OperatingSystem]::IsWindows()) {
                        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
                        if ($cpu) {
                            $avg = $cpu.LoadPercentage | Measure-Object -Average | Select-Object -ExpandProperty Average
                            if ($null -ne $avg) {
                                $usage = [int]$avg
                            }
                        }
                    }
                    elseif ([System.OperatingSystem]::IsLinux()) {
                        $statLine = Get-Content -LiteralPath "/proc/stat" -TotalCount 1 -ErrorAction Stop
                        if ($statLine -match '^cpu\s+(.+)$') {
                            $fields = $Matches[1] -split '\s+'
                            if ($fields.Count -ge 5) {
                                $total = 0.0
                                foreach ($field in $fields) {
                                    $total += [double]$field
                                }
                                # idle + iowait are the non-busy counters.
                                $idle = [double]$fields[3] + [double]$fields[4]
                                if ($null -ne $previousCpuSample) {
                                    $deltaTotal = $total - $previousCpuSample.Total
                                    $deltaIdle = $idle - $previousCpuSample.Idle
                                    if ($deltaTotal -gt 0) {
                                        $usage = [int][math]::Round((1 - ($deltaIdle / $deltaTotal)) * 100)
                                    }
                                }
                                $previousCpuSample = @{ Total = $total; Idle = $idle }
                            }
                        }
                    }
                    elseif ([System.OperatingSystem]::IsMacOS()) {
                        $topOutput = & top -l 1 -n 0 2>$null
                        $cpuLine = $topOutput | Where-Object { $_ -match '^CPU usage:' } | Select-Object -First 1
                        if ($cpuLine -match '([\d.]+)%\s+idle') {
                            $usage = [int][math]::Round(100 - [double]$Matches[1])
                        }
                    }

                    if ($null -ne $usage) {
                        $CpuSharedData.Usage = [math]::Max(0, [math]::Min(100, $usage))
                    }
                    $CpuSharedData.IterationCount++
                    $sw.Stop()
                    $CpuSharedData.UpdateDurationMs = $sw.Elapsed.TotalMilliseconds
                    $CpuSharedData.LastUpdateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                }
                catch {
                    # Silent ignore on error
                    $sw.Stop()
                }
                $sleepMs = $SampleIntervalSec * 1000
                [System.Threading.Thread]::Sleep($sleepMs)
            }
        })

        $global:PPF_CpuRunspace = $rs
        $global:PPF_CpuPowerShell = $ps
        $global:PPF_CpuAsyncResult = $ps.BeginInvoke()
    }
    catch {
        # Fallback to direct query if runspace fails. Release anything that
        # was created before the failure.
        if ($null -ne $ps) {
            try { $ps.Dispose() } catch {}
        }
        if ($null -ne $rs) {
            try {
                $rs.Close()
                $rs.Dispose()
            } catch {}
        }
        $global:PPF_CpuRunspace = $null
        $global:PPF_CpuPowerShell = $null
        $global:PPF_CpuAsyncResult = $null
        Write-Debug "Failed to start CPU Sampler runspace: $_"
    }
}

function Stop-CpuSampler {
    if ($null -ne $global:PPF_CpuSharedData) {
        $global:PPF_CpuSharedData.Stopped = $true
    }
    if ($null -ne $global:PPF_CpuPowerShell) {
        try {
            $global:PPF_CpuPowerShell.Dispose()
        } catch {}
        $global:PPF_CpuPowerShell = $null
    }
    if ($null -ne $global:PPF_CpuRunspace) {
        try {
            $global:PPF_CpuRunspace.Close()
            $global:PPF_CpuRunspace.Dispose()
        } catch {}
        $global:PPF_CpuRunspace = $null
    }
    $global:PPF_CpuAsyncResult = $null
}

function Get-CpuUsage {
    # Ensure sampler is running
    Start-CpuSampler

    # Simply return the shared value
    if ($null -ne $global:PPF_CpuSharedData) {
        return $global:PPF_CpuSharedData.Usage
    }

    # Absolute fallback
    return 0
}

# The sampler is started lazily by Get-CpuUsage or explicit Start-CpuSampler calls.
