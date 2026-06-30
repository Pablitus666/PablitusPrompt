# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Provider.ps1
# ============================================================

function Invoke-ProjectProvider {

    param(
        [PromptContext]$Context
    )

    $current = Get-Location

    $Context.Project.Name = Split-Path $current -Leaf

    if (Test-Path ".git") {
        $Context.Project.Type = "Git"
    }
    elseif (Test-Path "package.json") {
        $Context.Project.Type = "Node"
    }
    elseif (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue) {
        $Context.Project.Type = ".NET"
    }
    elseif (Test-Path "pyproject.toml") {
        $Context.Project.Type = "Python"
    }
    else {
        $Context.Project.Type = "Folder"
    }

}

Register-PromptProvider `
    -Name "Project" `
    -Priority 300 `
    -Script ${function:Invoke-ProjectProvider}