# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Cache.ps1
# ============================================================

$script:PPFMemoryCache = @{}
$script:CacheDir = Join-Path $env:LOCALAPPDATA "PablitusPrompt"
$script:DiskCachePath = Join-Path $script:CacheDir "cache.json"

function Get-PPFCache {

    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [switch]$UseDisk
    )

    $now = Get-Date

    # 1. Check Memory Cache
    if ($script:PPFMemoryCache.ContainsKey($Key)) {
        $entry = $script:PPFMemoryCache[$Key]
        if (-not $entry.Expiry -or $now -lt $entry.Expiry) {
            $global:PPF_CacheHits++
            return $entry.Value
        }
        else {
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
                return $entry.Value
            }
            else {
                # Evict expired
                $diskCache.Remove($Key)
                Save-PPFDiskCache -Cache $diskCache
            }
        }
    }

    $global:PPF_CacheMisses++
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

    $expiry = $null
    if ($TtlSeconds -gt 0) {
        $expiry = (Get-Date).AddSeconds($TtlSeconds)
    }

    $entry = @{
        Value  = $Value
        Expiry = $expiry
    }

    # 1. Memory Cache
    $script:PPFMemoryCache[$Key] = $entry

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
        Remove-Item $script:DiskCachePath -Force
    }

}

function Load-PPFDiskCache {

    if (-not (Test-Path $script:DiskCachePath)) {
        return @{}
    }
    try {
        $json = Get-Content -Raw -Path $script:DiskCachePath -ErrorAction SilentlyContinue
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
        $json | Out-File -FilePath $script:DiskCachePath -Encoding utf8
    }
    catch {
        Write-Verbose "[PPF] Failed to save disk cache: $_"
    }

}
