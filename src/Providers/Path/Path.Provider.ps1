# ============================================================
# Pablitus Prompt Framework (PPF)
# Path.Provider.ps1
# ============================================================

function Invoke-PathProvider {

    param(
        [PromptContext]$Context
    )

    $current = (Get-Location).Path
    $userHome = [System.IO.Path]::GetFullPath($HOME)

    $friendly = $current

    if ($friendly.StartsWith($userHome, [System.StringComparison]::OrdinalIgnoreCase)) {
        $friendly = $friendly.Replace($userHome, "~")
    }

    $Context.Path.Current  = $current
    $Context.Path.Friendly = $friendly

}

Register-PromptProvider `
    -Name "Path" `
    -Priority 200 `
    -Script ${function:Invoke-PathProvider}