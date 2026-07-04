# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Service.ps1
# ============================================================

function Invoke-Git {

    param(
        [string[]]$Arguments
    )

    try {

        git @Arguments 2>$null

    }
    catch {

        $null

    }

}

function Test-GitRepository {

    return $null -ne (Get-GitDir)

}

function Get-GitStatusAndBranch {

    if (-not (Test-GitRepository)) {
        return [PSCustomObject]@{
            Branch = $null
            Dirty  = $false
        }
    }

    $output = Invoke-Git @(
        "status",
        "--porcelain",
        "-b"
    )

    $lines = @($output) | Where-Object { $_ }
    if ($lines.Count -eq 0) {
        return [PSCustomObject]@{
            Branch = "HEAD"
            Dirty  = $false
        }
    }

    $branchLine = $lines[0]
    $branchName = $branchLine.Replace("## ", "").Trim()
    if ($branchName.Contains("...")) {
        $branchName = $branchName.Substring(0, $branchName.IndexOf("..."))
    }
    elseif ($branchName -match "no branch") {
        $branchName = "HEAD (no branch)"
    }
    elseif ($branchName -match "on\s+([^\s]+)") {
        $branchName = $Matches[1]
    }

    $dirty = $lines.Count -gt 1

    return [PSCustomObject]@{
        Branch = $branchName
        Dirty  = $dirty
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

    $statusArray = @($status) | Where-Object { $_ }

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

