# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Cache.ps1
# ============================================================

$script:PPFMemoryCache = @{}
$script:PPFDiskCacheInMem = $null
$script:PPFDiskCacheDirty = $false

function script:Get-PPFCacheDirectory {

    $cacheRoot = $null

    try {
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $cacheRoot = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
            if (-not $cacheRoot) { $cacheRoot = $env:LOCALAPPDATA }
            if (-not $cacheRoot) { $cacheRoot = $env:APPDATA }
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
            if ($env:HOME) {
                $cacheRoot = Join-Path (Join-Path $env:HOME "Library") "Caches"
            }
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
            if ($env:XDG_CACHE_HOME) {
                $cacheRoot = $env:XDG_CACHE_HOME
            }
            elseif ($env:HOME) {
                $cacheRoot = Join-Path $env:HOME ".cache"
            }
        }
    }
    catch {
    }

    if (-not $cacheRoot) {
        if ($env:XDG_CACHE_HOME) {
            $cacheRoot = $env:XDG_CACHE_HOME
        }
        elseif ($env:LOCALAPPDATA) {
            $cacheRoot = $env:LOCALAPPDATA
        }
        elseif ($env:HOME) {
            if (Test-Path (Join-Path $env:HOME "Library")) {
                $cacheRoot = Join-Path (Join-Path $env:HOME "Library") "Caches"
            }
            else {
                $cacheRoot = Join-Path $env:HOME ".cache"
            }
        }
        else {
            $cacheRoot = [System.IO.Path]::GetTempPath()
        }
    }

    if (-not $cacheRoot) {
        $cacheRoot = [System.IO.Path]::GetTempPath()
    }

    return (Join-Path $cacheRoot "PablitusPrompt")

}

$script:CacheDir = Get-PPFCacheDirectory
$script:DiskCachePath = Join-Path $script:CacheDir "cache.json"

if ($null -eq $global:PPF_CacheHits) { $global:PPF_CacheHits = 0 }
if ($null -eq $global:PPF_CacheMisses) { $global:PPF_CacheMisses = 0 }
if ($null -eq $global:PPF_CacheTTLExpired) { $global:PPF_CacheTTLExpired = 0 }
if ($null -eq $global:PPF_CacheRefreshes) { $global:PPF_CacheRefreshes = 0 }

if ($null -eq $global:PPF_ProviderCacheStats) {
    $global:PPF_ProviderCacheStats = [ordered]@{}
}

function Get-PPFCache {

    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [switch]$UseDisk
    )

    $now = [datetime]::Now
    $prov = $global:PPF_CurrentExecutingProvider
    if ($null -ne $prov -and -not $global:PPF_ProviderCacheStats.Contains($prov)) {
        $global:PPF_ProviderCacheStats[$prov] = @{ Hits = 0; Misses = 0; Expirations = 0; Refreshes = 0 }
    }

    # 1. Check Memory Cache
    if ($script:PPFMemoryCache.ContainsKey($Key)) {
        $entry = $script:PPFMemoryCache[$Key]
        if (-not $entry.Expiry -or $now -lt $entry.Expiry) {
            $global:PPF_CacheHits++
            if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Hits++ }
            return $entry.Value
        }
        else {
            $global:PPF_CacheTTLExpired++
            if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Expirations++ }
            $script:PPFMemoryCache.Remove($Key)
        }
    }

    # 2. Check Disk Cache (In-Memory copy)
    if ($UseDisk) {
        $diskCache = Import-PPFDiskCache
        if ($diskCache -and $diskCache.ContainsKey($Key)) {
            $entry = $diskCache[$Key]
            $expiry = if ($entry.Expiry) { [datetime]$entry.Expiry } else { $null }
            if (-not $expiry -or $now -lt $expiry) {
                # Memory cache sync
                $script:PPFMemoryCache[$Key] = $entry
                $global:PPF_CacheHits++
                if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Hits++ }
                return $entry.Value
            }
            else {
                # Evict expired
                $global:PPF_CacheTTLExpired++
                if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Expirations++ }
                $diskCache.Remove($Key)
                $script:PPFDiskCacheDirty = $true
            }
        }
    }

    $global:PPF_CacheMisses++
    if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Misses++ }
    return $null

}

function Set-PPFCache {

    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        $Value,

        [int]$TtlSeconds = 0,

        [switch]$UseDisk
    )

    $now = [datetime]::Now
    $prov = $global:PPF_CurrentExecutingProvider
    if ($null -ne $prov -and -not $global:PPF_ProviderCacheStats.Contains($prov)) {
        $global:PPF_ProviderCacheStats[$prov] = @{ Hits = 0; Misses = 0; Expirations = 0; Refreshes = 0 }
    }

    $expiry = $null
    if ($TtlSeconds -gt 0) {
        $expiry = $now.AddSeconds($TtlSeconds)
    }

    $entry = @{
        Value  = $Value
        Expiry = $expiry
    }

    # 1. Memory Cache
    $script:PPFMemoryCache[$Key] = $entry
    $global:PPF_CacheRefreshes++
    if ($null -ne $prov) { $global:PPF_ProviderCacheStats[$prov].Refreshes++ }

    # 2. Disk Cache (In-Memory)
    if ($UseDisk) {
        $diskCache = Import-PPFDiskCache
        $diskCache[$Key] = $entry
        $script:PPFDiskCacheDirty = $true
    }

}

function Clear-PPFCache {

    param(
        [Parameter(Mandatory)]
        [string]$Key
    )

    if ($script:PPFMemoryCache.ContainsKey($Key)) {
        $script:PPFMemoryCache.Remove($Key)
    }

    $diskCache = Import-PPFDiskCache
    if ($diskCache -and $diskCache.ContainsKey($Key)) {
        $diskCache.Remove($Key)
        $script:PPFDiskCacheDirty = $true
    }

}

function Clear-AllPPFCache {

    $script:PPFMemoryCache.Clear()
    $script:PPFDiskCacheInMem = @{}
    $script:PPFDiskCacheDirty = $false

    if (Test-Path $script:DiskCachePath) {
        try {
            Remove-Item $script:DiskCachePath -Force -ErrorAction Stop
        }
        catch {
            # Retry after a small delay to handle transient locks
            Start-Sleep -Milliseconds 100
            try {
                Remove-Item $script:DiskCachePath -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }

}

function Import-PPFDiskCache {

    if ($null -ne $script:PPFDiskCacheInMem) {
        return $script:PPFDiskCacheInMem
    }

    if (-not (Test-Path $script:DiskCachePath)) {
        $script:PPFDiskCacheInMem = @{}
        return $script:PPFDiskCacheInMem
    }

    try {
        $json = $null
        for ($i = 0; $i -lt 3; $i++) {
            try {
                $json = Get-Content -Raw -Path $script:DiskCachePath -ErrorAction Stop
                break
            }
            catch {
                Start-Sleep -Milliseconds 50
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($json)) {
            $parsed = ConvertFrom-Json $json -AsHashtable -ErrorAction Stop
            # A corrupted or unexpected payload must not replace the cache
            # with a non-dictionary object.
            if ($parsed -is [System.Collections.IDictionary]) {
                $script:PPFDiskCacheInMem = $parsed
                return $script:PPFDiskCacheInMem
            }
            Write-Verbose "[PPF] Ignoring disk cache with unexpected format."
        }
    }
    catch {
        Write-Verbose "[PPF] Failed to load disk cache: $_"
    }

    $script:PPFDiskCacheInMem = @{}
    return $script:PPFDiskCacheInMem

}

function Save-PPFDiskCache {

    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Cache
    )

    # Use the passed cache or the in-memory one
    $dataToSave = if ($null -ne $Cache) { $Cache } else { $script:PPFDiskCacheInMem }

    if ($null -eq $dataToSave -or (-not $script:PPFDiskCacheDirty -and $null -eq $Cache)) {
        return
    }

    try {
        $json = $dataToSave | ConvertTo-Json -Depth 5

        $candidatePaths = @(
            @{
                CacheDir = $script:CacheDir
                DiskPath = $script:DiskCachePath
            },
            @{
                CacheDir = (Join-Path ([System.IO.Path]::GetTempPath()) "PablitusPrompt")
                DiskPath = (Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) "PablitusPrompt") "cache.json")
            }
        )

        foreach ($candidate in $candidatePaths) {
            try {
                if (-not (Test-Path $candidate.CacheDir)) {
                    $null = New-Item -ItemType Directory -Path $candidate.CacheDir -Force
                }

                # Write to a temporary file and move it into place so readers
                # never observe a partially written cache. Retry on transient
                # lock conflicts.
                for ($i = 0; $i -lt 3; $i++) {
                    $tempPath = "{0}.{1}.tmp" -f $candidate.DiskPath, [guid]::NewGuid().ToString("N")
                    try {
                        $json | Out-File -LiteralPath $tempPath -Encoding utf8 -ErrorAction Stop
                        [System.IO.File]::Move($tempPath, $candidate.DiskPath, $true)
                        $script:CacheDir = $candidate.CacheDir
                        $script:DiskCachePath = $candidate.DiskPath
                        $script:PPFDiskCacheDirty = $false
                        return
                    }
                    catch {
                        if (Test-Path -LiteralPath $tempPath) {
                            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                        }
                        Start-Sleep -Milliseconds 50
                    }
                }
            }
            catch {
            }
        }
    }
    catch {
        Write-Verbose "[PPF] Failed to save disk cache: $_"
    }

}

function Sync-PPFDiskCache {
    # Persist pending disk-cache changes. This is a no-op when nothing has
    # changed, so it is safe to call on every prompt render.
    if ($script:PPFDiskCacheDirty) {
        Save-PPFDiskCache
    }
}
