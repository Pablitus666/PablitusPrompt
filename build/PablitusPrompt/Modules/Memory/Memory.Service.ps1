$script:FastestMemoryMethod = $null

# Win32 Memory P/Invoke type definition for high-speed lookup
$win32MemorySource = @"
using System;
using System.Runtime.InteropServices;

public class PPF_Win32Memory {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public class MEMORYSTATUSEX {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
        public MEMORYSTATUSEX() {
            this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
        }
    }

    [return: MarshalAs(UnmanagedType.Bool)]
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    public static int GetMemoryLoad() {
        MEMORYSTATUSEX ms = new MEMORYSTATUSEX();
        if (GlobalMemoryStatusEx(ms)) {
            return (int)ms.dwMemoryLoad;
        }
        return 0;
    }
}
"@

function Select-FastestMemoryMethod {
    if (-not [System.OperatingSystem]::IsWindows()) {
        $script:FastestMemoryMethod = "DotNet"
        return
    }

    # Ensure C# type is loaded
    if ($null -eq ("PPF_Win32Memory" -as [type])) {
        Add-Type -TypeDefinition $win32MemorySource -ErrorAction SilentlyContinue
    }

    # Measure DotNet (.NET API via P/Invoke)
    $timeDotNet = [double]::MaxValue
    if ($null -ne ("PPF_Win32Memory" -as [type])) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $null = [PPF_Win32Memory]::GetMemoryLoad()
            $sw.Stop()
            $timeDotNet = $sw.Elapsed.TotalMilliseconds
        } catch { $sw.Stop() }
    }

    # Measure CIM (Get-CimInstance)
    $timeCim = [double]::MaxValue
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $null = [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
            }
            $sw.Stop()
            $timeCim = $sw.Elapsed.TotalMilliseconds
        } catch { $sw.Stop() }
    }

    # Measure WMI (Get-WmiObject)
    $timeWmi = [double]::MaxValue
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $null = [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
            }
            $sw.Stop()
            $timeWmi = $sw.Elapsed.TotalMilliseconds
        } catch { $sw.Stop() }
    }

    # Choose the fastest
    if ($timeDotNet -le $timeCim -and $timeDotNet -le $timeWmi) {
        $script:FastestMemoryMethod = "DotNet"
    }
    elseif ($timeCim -le $timeWmi) {
        $script:FastestMemoryMethod = "Cim"
    }
    else {
        $script:FastestMemoryMethod = "Wmi"
    }
}

function Get-MemoryUsage {
    if ($null -eq $script:FastestMemoryMethod) {
        Select-FastestMemoryMethod
    }

    switch ($script:FastestMemoryMethod) {
        "DotNet" {
            if ([System.OperatingSystem]::IsWindows()) {
                try {
                    return [PPF_Win32Memory]::GetMemoryLoad()
                } catch {}
            } else {
                # Linux /proc/meminfo fallback
                try {
                    $meminfo = Get-Content -Path "/proc/meminfo" -ErrorAction SilentlyContinue
                    $total = 0.0
                    $free = 0.0
                    $buffers = 0.0
                    $cached = 0.0
                    foreach ($line in $meminfo) {
                        if ($line -match "MemTotal:\s+(\d+)") { $total = [double]$Matches[1] }
                        elseif ($line -match "MemFree:\s+(\d+)") { $free = [double]$Matches[1] }
                        elseif ($line -match "Buffers:\s+(\d+)") { $buffers = [double]$Matches[1] }
                        elseif ($line -match "Cached:\s+(\d+)") { $cached = [double]$Matches[1] }
                    }
                    if ($total -gt 0) {
                        $used = $total - ($free + $buffers + $cached)
                        return [int](($used / $total) * 100)
                    }
                } catch {}
            }
        }
        "Cim" {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($os) {
                    return [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
                }
            } catch {}
        }
        "Wmi" {
            try {
                $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($os) {
                    return [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
                }
            } catch {}
        }
    }
    
    # Absolute fallback
    return 0
}

