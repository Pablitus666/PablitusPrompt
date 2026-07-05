# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Service.ps1
# ============================================================

function Get-ProjectInfo {

    $current = (Get-Location).Path
    $projectRoot = $current
    $projectType = "Folder"
    $projectIcon = "📁"

    $dir = $current
    while ($dir) {
        if ([System.IO.File]::Exists([System.IO.Path]::Combine($dir, "package.json"))) {
            $projectRoot = $dir
            $projectType = "Node"
            $projectIcon = ""
            break
        }
        elseif ([System.IO.File]::Exists([System.IO.Path]::Combine($dir, "pyproject.toml")) -or 
                [System.IO.File]::Exists([System.IO.Path]::Combine($dir, "requirements.txt")) -or 
                [System.IO.File]::Exists([System.IO.Path]::Combine($dir, "setup.py"))) {
            $projectRoot = $dir
            $projectType = "Python"
            $projectIcon = ""
            break
        }
        
        # Check for *.sln files
        try {
            $hasSln = $false
            foreach ($f in [System.IO.Directory]::EnumerateFiles($dir, "*.sln")) {
                $hasSln = $true
                break
            }
            if ($hasSln) {
                $projectRoot = $dir
                $projectType = ".NET"
                $projectIcon = "󰪮"
                break
            }
        }
        catch {}

        if ([System.IO.Directory]::Exists([System.IO.Path]::Combine($dir, ".git"))) {
            $projectRoot = $dir
            $projectType = "Git"
            $projectIcon = ""
            break
        }

        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($parent -eq $dir -or -not $parent) {
            break
        }
        $dir = $parent
    }

    return [pscustomobject]@{
        Name = [System.IO.Path]::GetFileName($projectRoot)
        Type = $projectType
        Root = $projectRoot
        Icon = $projectIcon
    }

}
