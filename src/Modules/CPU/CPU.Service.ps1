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
    if ($global:PPF_CpuSharedData.Stopped) {
        $global:PPF_CpuSharedData.Stopped = $false
    }

    # Verify if the runspace is already running
    if ($null -ne $global:PPF_CpuRunspace) {
        try {
            if ($global:PPF_CpuRunspace.RunspaceStateInfo.State -eq 'Opened') {
                return # Already running
            }
        }
        catch {}
    }

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
            while (-not $CpuSharedData.Stopped) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    if ([System.OperatingSystem]::IsWindows()) {
                        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
                        if ($cpu) {
                            $avg = $cpu.LoadPercentage | Measure-Object -Average | Select-Object -ExpandProperty Average
                            $CpuSharedData.Usage = [int]$avg
                        }
                    } else {
                        # Linux/macOS fallback
                        $CpuSharedData.Usage = 5
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
        # Fallback to direct query if runspace fails
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
