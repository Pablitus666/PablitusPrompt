# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Path.ps1
# ============================================================

function Get-FriendlyPath {

    $current = (Get-Location).Path
    $homePath = [System.IO.Path]::GetFullPath($HOME)

    if ($current.StartsWith($homePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $current.Replace($homePath, "~")
    }

    return $current

}

Register-PromptModule -Name "Path" -Script {

    param(
        [PromptContext]$Context
    )

    $Context.CurrentPath = (Get-Location).Path
    $Context.FriendlyPath = Get-FriendlyPath

}