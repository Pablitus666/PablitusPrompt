# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Project.ps1
# ============================================================

Register-PromptModule -Name "Project" -Script {

    param(
        [PromptContext]$Context
    )

    $current = Get-Location

    $Context.ProjectName = Split-Path $current -Leaf

    if (Test-Path ".git") {
        $Context.ProjectType = "Git"
    }
    elseif (Test-Path "package.json") {
        $Context.ProjectType = "Node"
    }
    elseif (Test-Path "*.sln") {
        $Context.ProjectType = ".NET"
    }
    elseif (Test-Path "pyproject.toml") {
        $Context.ProjectType = "Python"
    }
    else {
        $Context.ProjectType = "Folder"
    }

}