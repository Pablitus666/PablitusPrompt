# ============================================================
# Pablitus Prompt Framework (PPF)
# Command.Service.ps1
# ============================================================

$script:CommandCache = @{}

function Find-Command {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($script:CommandCache.ContainsKey($Name)) {
        return $script:CommandCache[$Name]
    }

    $command = Get-Command $Name -ErrorAction SilentlyContinue

    if ($null -eq $command) {
        $script:CommandCache[$Name] = $null
        return $null
    }

    $script:CommandCache[$Name] = $command.Source

    return $command.Source
}

function Test-Command {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return $null -ne (Find-Command $Name)
}

function Clear-CommandCache {

    $script:CommandCache.Clear()

}