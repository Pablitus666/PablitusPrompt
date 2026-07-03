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

    return (Test-Path ".git")

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

    [PSCustomObject]@{

        Dirty     = ($status.Count -gt 0)
        Modified  = ($status -match "^.M").Count -gt 0
        Staged    = ($status -match "^M.").Count -gt 0
        Untracked = ($status -match "^\?\?").Count -gt 0

    }

}