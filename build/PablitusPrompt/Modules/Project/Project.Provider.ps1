# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Provider.ps1
# ============================================================

function Invoke-ProjectProvider {

    param(
        [PromptContext]$Context
    )

    $currentPath = (Get-Location).Path
    $cacheKey = "ProjectInfo_$currentPath"
    $project = Get-PPFCache -Key $cacheKey

    if ($null -eq $project) {
        $project = Get-ProjectInfo
        Set-PPFCache -Key $cacheKey -Value $project -TtlSeconds 15
    }

    $Context.Project.Name = $project.Name
    $Context.Project.Type = $project.Type
    $Context.Project.Root = $project.Root
    $Context.Project.Icon = $project.Icon

}

Register-PromptProvider `
    -Name "Project" `
    -Priority 300 `
    -Script ${function:Invoke-ProjectProvider}
