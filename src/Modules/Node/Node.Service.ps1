# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Service.ps1
# ============================================================

function Get-NodeVersion {

    if (Test-CommandExists node) {

        $version = (node --version 2>$null)
        if ($version) {
            return ($version -join "").TrimStart("v").Trim()
        }

    }

    return $null

}
