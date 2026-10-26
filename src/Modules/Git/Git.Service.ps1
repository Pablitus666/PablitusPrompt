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

function Get-GitRoot {

    $currentPath = (Get-Location).Path
    $cacheKey = "GitRoot_$currentPath"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        if ($cached -eq "NONE") {
            return $null
        }
        return $cached
    }

    $root = $null
    $topLevel = Invoke-Git @("rev-parse", "--show-toplevel")
    if ($topLevel) {
        $candidate = ($topLevel | Select-Object -First 1).Trim()
        # Guard against degraded/mocked output that is not a real path.
        if ($candidate -and [System.IO.Path]::IsPathRooted($candidate)) {
            $root = $candidate
        }
    }

    if (-not $root) {
        # Fallback for environments where rev-parse is unavailable.
        $gitDir = Get-GitDir
        if ($gitDir) {
            $root = Split-Path $gitDir -Parent
        }
    }

    Set-PPFCache -Key $cacheKey -Value $(if ($root) { $root } else { "NONE" }) -TtlSeconds 30
    return $root

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

    $root = Get-GitRoot

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

    $detached = $false
    if ($branchName -match '^No commits yet on (.+)$') {
        # Unborn branch: git prints a sentence instead of the branch name.
        $branchName = $Matches[1].Trim()
    }
    elseif ($branchName -match '^Initial commit on (.+)$') {
        $branchName = $Matches[1].Trim()
    }
    elseif ($branchName -match '^HEAD \(no branch\)$' -or $branchName -match '^no branch$') {
        $detached = $true
    }
    elseif ($branchName.Contains("...")) {
        $branchName = $branchName.Substring(0, $branchName.IndexOf("..."))
    }

    if ($detached) {
        $sha = Invoke-Git @("rev-parse", "--short", "HEAD")
        if ($sha) {
            $branchName = ($sha | Select-Object -First 1).Trim()
        }
        else {
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

# Watchers are cheap but not free. Keeping one per visited repository for
# the whole session would eventually exhaust file handles, so evict the
# oldest repository when the cap is reached.
$script:MaxGitWatchers = 8

function Stop-GitWatcher {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    if ($null -eq $global:PPF_GitWatchers -or -not $global:PPF_GitWatchers.Contains($RepoRoot)) {
        return
    }

    $watcherEntry = $global:PPF_GitWatchers[$RepoRoot]
    try {
        if ($watcherEntry.Handlers) {
            foreach ($handler in $watcherEntry.Handlers) {
                Unregister-Event -SourceIdentifier $handler.Name -ErrorAction SilentlyContinue
            }
        }
        if ($watcherEntry.Watcher) {
            $watcherEntry.Watcher.EnableRaisingEvents = $false
            $watcherEntry.Watcher.Dispose()
        }
    }
    catch {
    }

    $global:PPF_GitWatchers.Remove($RepoRoot)
    if ($null -ne $global:PPF_GitWatcherDirty) {
        $global:PPF_GitWatcherDirty.Remove($RepoRoot)
    }
}

function Start-GitWatcher {
    param(
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        return
    }

    if ($null -eq $global:PPF_GitWatchers) {
        $global:PPF_GitWatchers = [ordered]@{}
    }
    if ($null -eq $global:PPF_GitWatcherDirty) {
        $global:PPF_GitWatcherDirty = [ordered]@{}
    }

    if ($global:PPF_GitWatchers.Contains($RepoRoot)) {
        return
    }

    # Evict the least-recently added watcher before adding a new one.
    while ($global:PPF_GitWatchers.Count -ge $script:MaxGitWatchers) {
        $existingRoots = @($global:PPF_GitWatchers.Keys)
        if ($existingRoots.Count -eq 0) {
            break
        }
        Stop-GitWatcher -RepoRoot $existingRoots[0]
    }

    try {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $RepoRoot
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true

        # Action when files change: mark repository as dirty
        $action = {
            $watcherData = $Event.MessageData
            $changedPath = $Event.SourceEventArgs.FullPath
            if (-not $watcherData -or -not $watcherData.RepoRoot -or $null -eq $global:PPF_GitWatcherDirty) {
                return
            }

            try {
                $relativePath = [System.IO.Path]::GetRelativePath($watcherData.RepoRoot, $changedPath)
                $gitSegment = ".git" + [System.IO.Path]::DirectorySeparatorChar
                if ($relativePath -ne ".git" -and -not $relativePath.StartsWith($gitSegment, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $global:PPF_GitWatcherDirty[$watcherData.RepoRoot] = $true
                }
            }
            catch {
                # The path may disappear while the event is being processed;
                # treat it as a change and let the next scan decide.
                $global:PPF_GitWatcherDirty[$watcherData.RepoRoot] = $true
            }
        }

        $messageData = @{ RepoRoot = $RepoRoot }
        $handlers = @()
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Changed" -MessageData $messageData -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Created" -MessageData $messageData -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -MessageData $messageData -Action $action
        $handlers += Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -MessageData $messageData -Action $action

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
    if ($null -eq $global:PPF_GitWatchers) {
        return
    }

    foreach ($root in @($global:PPF_GitWatchers.Keys)) {
        Stop-GitWatcher -RepoRoot $root
    }

    $global:PPF_GitWatchers.Clear()
    if ($null -ne $global:PPF_GitWatcherDirty) {
        $global:PPF_GitWatcherDirty.Clear()
    }
}


