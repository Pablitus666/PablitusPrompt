# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Service.ps1
# ============================================================

function Get-ProjectInfo {

    $current = (Get-Location).Path

    $info = [ordered]@{
        Name = Split-Path $current -Leaf
        Type = "Folder"
        Root = $current
        Icon = "📁"
    }

    if (Test-Path ".git") {

        $info.Type = "Git"
        $info.Icon = ""

    }
    elseif (Test-Path "package.json") {

        $info.Type = "Node"
        $info.Icon = ""

    }
    elseif (Test-Path "pyproject.toml") {

        $info.Type = "Python"
        $info.Icon = ""

    }
    elseif (Get-ChildItem *.sln -ErrorAction Ignore) {

        $info.Type = ".NET"
        $info.Icon = "󰪮"

    }

    return [pscustomobject]$info

}