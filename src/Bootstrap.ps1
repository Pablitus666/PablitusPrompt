# ============================================================
# Pablitus Prompt Framework (PPF)
# Bootstrap.ps1
# ============================================================

$script:BootstrapStart = [System.Diagnostics.Stopwatch]::StartNew()

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:PPF_InstallRoot = $Root

# ------------------------------------------------------------
# Core
# ------------------------------------------------------------

Get-ChildItem "$Root\Core\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

Get-ChildItem "$Root\Configuration\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------

Get-ChildItem "$Root\Utils\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Modules (Discovery & Import)
# ------------------------------------------------------------

. Initialize-PPFModules -ModulesPath "$Root\Modules"

# ------------------------------------------------------------
# Themes
# ------------------------------------------------------------

Get-ChildItem "$Root\Themes\*.Theme.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Renderers
# ------------------------------------------------------------

Get-ChildItem "$Root\Renderers\*\*.ps1" |
Sort-Object FullName |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Telemetry Finish
# ------------------------------------------------------------
$script:BootstrapStart.Stop()
$global:PPF_BootstrapTimeMs = $script:BootstrapStart.Elapsed.TotalMilliseconds
if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
    Write-PPFLog -Level "INFO" -Message "PPF bootstrapped in $($global:PPF_BootstrapTimeMs) ms."
}