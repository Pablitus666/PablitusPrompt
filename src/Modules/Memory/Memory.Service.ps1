$script:FastestMemoryMethod = $null

function script:Get-MemoryUsageFromWindows {

    try {
        if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os -and $os.TotalVisibleMemorySize -gt 0) {
                return [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
            }
        }
    }
    catch {
    }

    try {
        if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
            $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os -and $os.TotalVisibleMemorySize -gt 0) {
                return [int]((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
            }
        }
    }
    catch {
    }

    $win32MemorySource = @"
using System;
using System.Runtime.InteropServices;

public static class PPF_Win32MemoryStatus {
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

    try {
        if ($null -eq ("PPF_Win32MemoryStatus" -as [type])) {
            Add-Type -TypeDefinition $win32MemorySource -ErrorAction SilentlyContinue | Out-Null
        }

        if ($null -ne ("PPF_Win32MemoryStatus" -as [type])) {
            return [PPF_Win32MemoryStatus]::GetMemoryLoad()
        }
    }
    catch {
    }

    return $null

}

function script:Get-MemoryUsageFromLinux {

    try {
        $meminfo = Get-Content -Path "/proc/meminfo" -ErrorAction Stop
        $stats = @{
            MemTotal     = 0.0
            MemAvailable = $null
            MemFree      = 0.0
            Buffers      = 0.0
            Cached       = 0.0
        }

        foreach ($line in $meminfo) {
            if ($line -match '^(MemTotal|MemAvailable|MemFree|Buffers|Cached):\s+(\d+)') {
                $stats[$Matches[1]] = [double]$Matches[2]
            }
        }

        if ($stats.MemTotal -gt 0) {
            $available = $stats.MemAvailable
            if ($null -eq $available) {
                $available = $stats.MemFree + $stats.Buffers + $stats.Cached
            }

            $used = [math]::Max(0, $stats.MemTotal - $available)
            return [int](($used / $stats.MemTotal) * 100)
        }
    }
    catch {
    }

    return $null

}

function script:Get-MemoryUsageFromMacOS {

    try {
        $totalBytesRaw = & sysctl -n hw.memsize 2>$null
        if (-not $totalBytesRaw) {
            return $null
        }

        $totalBytes = [int64]$totalBytesRaw
        $vmStat = & vm_stat 2>$null
        if (-not $vmStat) {
            return $null
        }

        $pageSize = 4096
        $freePages = 0.0
        $inactivePages = 0.0
        $speculativePages = 0.0
        $purgeablePages = 0.0

        foreach ($line in $vmStat) {
            if ($line -match 'page size of (\d+) bytes') {
                $pageSize = [int64]$Matches[1]
            }
            elseif ($line -match '^Pages free:\s+(\d+)') {
                $freePages = [double]$Matches[1]
            }
            elseif ($line -match '^Pages inactive:\s+(\d+)') {
                $inactivePages = [double]$Matches[1]
            }
            elseif ($line -match '^Pages speculative:\s+(\d+)') {
                $speculativePages = [double]$Matches[1]
            }
            elseif ($line -match '^Pages purgeable:\s+(\d+)') {
                $purgeablePages = [double]$Matches[1]
            }
        }

        $availableBytes = ($freePages + $inactivePages + $speculativePages + $purgeablePages) * $pageSize
        $usedBytes = [math]::Max(0, $totalBytes - $availableBytes)
        return [int](($usedBytes / $totalBytes) * 100)
    }
    catch {
    }

    return $null

}

function script:Select-FastestMemoryMethod {

    try {
        if ([System.OperatingSystem]::IsWindows()) {
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
                $script:FastestMemoryMethod = "Windows-Cim"
                return
            }

            if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
                $script:FastestMemoryMethod = "Windows-Wmi"
                return
            }

            $script:FastestMemoryMethod = "Windows"
            return
        }

        if ([System.OperatingSystem]::IsMacOS()) {
            $script:FastestMemoryMethod = "MacOS"
            return
        }

        if ([System.OperatingSystem]::IsLinux()) {
            $script:FastestMemoryMethod = "Linux"
            return
        }
    }
    catch {
    }

    $script:FastestMemoryMethod = "Fallback"

}

function Get-MemoryUsage {

    if ($null -eq $script:FastestMemoryMethod) {
        Select-FastestMemoryMethod
    }

    switch ($script:FastestMemoryMethod) {
        "Windows-Cim" {
            $usage = Get-MemoryUsageFromWindows
            if ($null -ne $usage) {
                return $usage
            }
        }
        "Windows-Wmi" {
            $usage = Get-MemoryUsageFromWindows
            if ($null -ne $usage) {
                return $usage
            }
        }
        "Windows" {
            $usage = Get-MemoryUsageFromWindows
            if ($null -ne $usage) {
                return $usage
            }
        }
        "MacOS" {
            $usage = Get-MemoryUsageFromMacOS
            if ($null -ne $usage) {
                return $usage
            }
        }
        "Linux" {
            $usage = Get-MemoryUsageFromLinux
            if ($null -ne $usage) {
                return $usage
            }
        }
        default {
            if ([System.OperatingSystem]::IsWindows()) {
                $usage = Get-MemoryUsageFromWindows
                if ($null -ne $usage) {
                    return $usage
                }
            }
            elseif ([System.OperatingSystem]::IsMacOS()) {
                $usage = Get-MemoryUsageFromMacOS
                if ($null -ne $usage) {
                    return $usage
                }
            }
            elseif ([System.OperatingSystem]::IsLinux()) {
                $usage = Get-MemoryUsageFromLinux
                if ($null -ne $usage) {
                    return $usage
                }
            }
        }
    }

    # Absolute fallback
    return 0

}
