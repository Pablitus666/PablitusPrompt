# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Provider.ps1
# ============================================================

function Invoke-ProjectProvider {

    param(
        [PromptContext]$Context
    )

    $project = Get-ProjectInfo

    $Context.Project.Name = $project.Name
    $Context.Project.Type = $project.Type
    $Context.Project.Root = $project.Root
    $Context.Project.Icon = $project.Icon

}

Register-PromptProvider `
    -Name "Project" `
    -Priority 300 `
    -Script ${function:Invoke-ProjectProvider}