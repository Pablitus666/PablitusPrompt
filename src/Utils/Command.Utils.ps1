# ============================================================
# Pablitus Prompt Framework (PPF)
# Command Utilities
# ============================================================

function Test-CommandExists {

    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)

}

function Invoke-CommandSafe {

    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @()
    )

    if (-not (Test-CommandExists $Command)) {
        return $null
    }

    try {

        $output = & $Command @Arguments 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return ($output | Out-String).Trim()

    }
    catch {

        return $null

    }

}

function Get-CommandVersion {

    param(

        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @("--version")

    )

    return Invoke-CommandSafe `
        -Command $Command `
        -Arguments $Arguments

}