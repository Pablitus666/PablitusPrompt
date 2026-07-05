# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Service.ps1
# ============================================================

function Invoke-Git {

    param(
        [string[]]$Arguments
    )

    $res = Invoke-PPFExternalCommand -Command "git" -Arguments $Arguments -TimeoutMs 2000
    if ($res.Installed -and $res.ExitCode -eq 0 -and $null -ne $res.Output) {
        return $res.Output -split "`r?`n" | Where-Object { $_ }
    }
    return $null

}

function Test-GitRepository {

    return $null -ne (Get-GitDir)

}

function Get-GitStatusAndBranch {

    if (-not (Test-GitRepository)) {
        return [PSCustomObject]@{
            IsRepository = $false
            Branch       = $null
            Dirty        = $false
            Ahead        = 0
            Behind       = 0
            Detached     = $false
            Root         = $null
        }
    }

    $gitDir = Get-GitDir
    $root = if ($gitDir) { Split-Path $gitDir -Parent } else { $null }

    $output = Invoke-Git @(
        "status",
        "--porcelain",
        "-b"
    )

    [string[]]$lines = @($output) | Where-Object { $_ }
    if ($lines.Count -eq 0) {
        return [PSCustomObject]@{
            IsRepository = $true
            Branch       = "HEAD"
            Dirty        = $false
            Ahead        = 0
            Behind       = 0
            Detached     = $true
            Root         = $root
        }
    }

    $branchLine = $lines[0]
    $branchName = $branchLine.Replace("## ", "").Trim()
    
    $ahead = 0
    $behind = 0
    if ($branchName -match '\[([^\]]+)\]') {
        $details = $Matches[1]
        if ($details -match 'ahead\s+(\d+)') {
            $ahead = [int]$Matches[1]
        }
        if ($details -match 'behind\s+(\d+)') {
            $behind = [int]$Matches[1]
        }
        $branchName = $branchName.Substring(0, $branchName.IndexOf(" [")).Trim()
    }

    if ($branchName.Contains("...")) {
        $branchName = $branchName.Substring(0, $branchName.IndexOf("..."))
    }

    $detached = $false
    if ($branchName -match "no branch" -or $branchName -eq "HEAD") {
        $detached = $true
        $sha = Invoke-Git @("rev-parse", "--short", "HEAD")
        if ($sha) {
            $branchName = $sha.Trim()
        } else {
            $branchName = "HEAD (no branch)"
        }
    }

    $dirty = $lines.Count -gt 1

    return [PSCustomObject]@{
        IsRepository = $true
        Branch       = $branchName
        Dirty        = $dirty
        Ahead        = $ahead
        Behind       = $behind
        Detached     = $detached
        Root         = $root
    }

}

function Get-GitBranch {

    if (-not (Test-GitRepository)) {
        return $null
    }

    Invoke-Git @(
        "rev-parse",
        "--abbrev-ref",
        "HEAD"
    )

}

function Get-GitCommit {

    if (-not (Test-GitRepository)) {
        return $null
    }

    Invoke-Git @(
        "rev-parse",
        "HEAD"
    )

}

function Get-GitCommitShort {

    if (-not (Test-GitRepository)) {
        return $null
    }

    Invoke-Git @(
        "rev-parse",
        "--short",
        "HEAD"
    )

}

function Get-GitStatus {

    if (-not (Test-GitRepository)) {

        return [PSCustomObject]@{

            Dirty        = $false
            Modified     = $false
            Staged       = $false
            Untracked    = $false

        }

    }

    $status = Invoke-Git @(
        "status",
        "--porcelain"
    )

    [string[]]$statusArray = @($status) | Where-Object { $_ }

    return [PSCustomObject]@{

        Dirty     = ($statusArray.Count -gt 0)
        Modified  = ($statusArray -match "^.M").Count -gt 0
        Staged    = ($statusArray -match "^M.").Count -gt 0
        Untracked = ($statusArray -match "^\?\?").Count -gt 0

    }

}

$script:GitDirCache = @{}

function Get-GitDir {

    $currentPath = (Get-Location).Path
    $cacheKey = "GitDir_$currentPath"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        if ($cached -eq "NONE") {
            return $null
        }
        return $cached
    }

    $dir = $currentPath
    $resolvedGitDir = $null
    while ($dir) {
        $gitPath = [System.IO.Path]::Combine($dir, ".git")
        if ([System.IO.Directory]::Exists($gitPath)) {
            $resolvedGitDir = $gitPath
            break
        }
        elseif ([System.IO.File]::Exists($gitPath)) {
            try {
                $content = [System.IO.File]::ReadAllText($gitPath)
                if ($content -match "gitdir:\s*(.*)") {
                    $relPath = $Matches[1].Trim()
                    if ([System.IO.Path]::IsPathRooted($relPath)) {
                        $resolvedGitDir = $relPath
                    }
                    else {
                        $resolvedGitDir = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($dir, $relPath))
                    }
                    break
                }
            }
            catch {}
        }
        
        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($parent -eq $dir -or -not $parent) {
            break
        }
        $dir = $parent
    }

    if ($null -ne $resolvedGitDir) {
        Set-PPFCache -Key $cacheKey -Value $resolvedGitDir -TtlSeconds 30
    }
    else {
        Set-PPFCache -Key $cacheKey -Value "NONE" -TtlSeconds 30
    }

    return $resolvedGitDir

}

function Get-GitStateSignature {

    $gitDir = Get-GitDir
    if (-not $gitDir) {
        return $null
    }
    $headPath = [System.IO.Path]::Combine($gitDir, "HEAD")
    $indexPath = [System.IO.Path]::Combine($gitDir, "index")
    $headTime = if ([System.IO.File]::Exists($headPath)) { [System.IO.File]::GetLastWriteTime($headPath).Ticks } else { 0 }
    $indexTime = if ([System.IO.File]::Exists($indexPath)) { [System.IO.File]::GetLastWriteTime($indexPath).Ticks } else { 0 }
    return "Dir:$((Get-Location).Path)|Head:$headTime|Index:$indexTime"

}

if ($null -eq $global:PPF_GitWatchers) {
    $global:PPF_GitWatchers = [ordered]@{} # Repository Root -> @{ Watcher = FileSystemWatcher, Handlers = EventJobs }
    $global:PPF_GitWatcherDirty = [ordered]@{} # Repository Root -> Boolean
}

function Start-GitWatcher {
    param(
        [string]$RepoRoot
    )
    if ($global:PPF_GitWatchers.Contains($RepoRoot)) {
        return
    }
    try {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $RepoRoot
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true
        
        # Action when files change: mark repository as dirty
        $action = {
            param($sender, $e)
            $path = $e.FullPath
            # Ignore changes inside the .git directory
            if ($path -notmatch '\\\.git\\') {
                $global:PPF_GitWatcherDirty[$RepoRoot] = $true
            }
        }
        
        $handlers = @()
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action
        
        $global:PPF_GitWatchers[$RepoRoot] = @{
            Watcher = $watcher
            Handlers = $handlers
        }
        $global:PPF_GitWatcherDirty[$RepoRoot] = $true # Start dirty to force first scan
    }
    catch {
        # Fallback gracefully
    }
}

function Stop-AllGitWatchers {
    if ($null -ne $global:PPF_GitWatchers) {
        foreach ($root in $global:PPF_GitWatchers.Keys) {
            $w = $global:PPF_GitWatchers[$root]
            try {
                if ($w.Handlers) {
                    foreach ($h in $w.Handlers) {
                        Unregister-Event -SourceIdentifier $h.Name -ErrorAction SilentlyContinue
                    }
                }
                if ($w.Watcher) {
                    $w.Watcher.EnableRaisingEvents = $false
                    $w.Watcher.Dispose()
                }
            } catch {}
        }
        $global:PPF_GitWatchers.Clear()
        $global:PPF_GitWatcherDirty.Clear()
    }
}


