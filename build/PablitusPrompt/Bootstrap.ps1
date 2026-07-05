# ============================================================
# Pablitus Prompt Framework (PPF)
# Bootstrap.ps1
# ============================================================

$script:BootstrapStart = [System.Diagnostics.Stopwatch]::StartNew()

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:PPF_InstallRoot = $Root

# Import the PablitusPrompt module globally
Import-Module (Join-Path $Root "PablitusPrompt.psd1") -Force -Global

$script:BootstrapStart.Stop()
$global:PPF_BootstrapTimeMs = $script:BootstrapStart.Elapsed.TotalMilliseconds
if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
    Write-PPFLog -Level "INFO" -Message "PPF bootstrapped via Module Import in $($global:PPF_BootstrapTimeMs) ms."
}