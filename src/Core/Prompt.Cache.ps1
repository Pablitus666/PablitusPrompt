# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Cache.ps1
# ============================================================

$script:PPFMemoryCache = @{}
$script:CacheDir = Join-Path $env:LOCALAPPDATA "PablitusPrompt"
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

    $now = Get-Date
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

    # 2. Check Disk Cache
    if ($UseDisk) {
        $diskCache = Load-PPFDiskCache
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
                Save-PPFDiskCache -Cache $diskCache
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

    $now = Get-Date
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

    # 2. Disk Cache
    if ($UseDisk) {
        $diskCache = Load-PPFDiskCache
        if (-not $diskCache) {
            $diskCache = @{}
        }
        $diskCache[$Key] = $entry
        Save-PPFDiskCache -Cache $diskCache
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

    $diskCache = Load-PPFDiskCache
    if ($diskCache -and $diskCache.ContainsKey($Key)) {
        $diskCache.Remove($Key)
        Save-PPFDiskCache -Cache $diskCache
    }

}

function Clear-AllPPFCache {

    $script:PPFMemoryCache.Clear()
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

function Load-PPFDiskCache {

    if (-not (Test-Path $script:DiskCachePath)) {
        return @{}
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
        if ($json) {
            return ConvertFrom-Json $json -AsHashtable
        }
    }
    catch {
        Write-Verbose "[PPF] Failed to load disk cache: $_"
    }
    return @{}

}

function Save-PPFDiskCache {

    param(
        [Parameter(Mandatory)]
        [hashtable]$Cache
    )
    try {
        if (-not (Test-Path $script:CacheDir)) {
            $null = New-Item -ItemType Directory -Path $script:CacheDir -Force
        }
        $json = $Cache | ConvertTo-Json -Depth 5
        # Attempt to write with retry to handle lock conflicts
        for ($i = 0; $i -lt 3; $i++) {
            try {
                $json | Out-File -FilePath $script:DiskCachePath -Encoding utf8 -ErrorAction Stop
                break
            }
            catch {
                Start-Sleep -Milliseconds 50
            }
        }
    }
    catch {
        Write-Verbose "[PPF] Failed to save disk cache: $_"
    }

}
