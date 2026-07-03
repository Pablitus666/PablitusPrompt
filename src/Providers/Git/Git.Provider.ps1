# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Provider.ps1
# ============================================================

function Invoke-GitProvider {

    param(
        [PromptContext]$Context
    )

    if (-not (Test-GitRepository)) {

        $Context.Git.IsRepository = $false
        return

    }

    $status = Get-GitStatus

    $Context.Git.IsRepository = $true
    $Context.Git.Branch = Get-GitBranch
    $Context.Git.Dirty = $status.Dirty

}

Register-PromptProvider `
    -Name "Git" `
    -Priority 400 `
    -Script ${function:Invoke-GitProvider}