# ============================================================
# Pablitus Prompt Framework (PPF)
# PablitusPrompt.psm1
# ============================================================

$script:BootstrapStart = [System.Diagnostics.Stopwatch]::StartNew()
$Root = $PSScriptRoot
$global:PPF_InstallRoot = $Root

# ------------------------------------------------------------
# Core
# ------------------------------------------------------------
Get-ChildItem "$Root\Core\*.ps1" | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
Get-ChildItem "$Root\Configuration\*.ps1" | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------
Get-ChildItem "$Root\Utils\*.ps1" | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Modules (Discovery & Import)
# ------------------------------------------------------------
. Initialize-PPFModules -ModulesPath "$Root\Modules"

# ------------------------------------------------------------
# Themes
# ------------------------------------------------------------
Get-ChildItem "$Root\Themes\*.Theme.ps1" | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Renderers
# ------------------------------------------------------------
Get-ChildItem "$Root\Renderers\*\*.ps1" | Sort-Object FullName | ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Telemetry Finish
# ------------------------------------------------------------
$script:BootstrapStart.Stop()
$global:PPF_BootstrapTimeMs = $script:BootstrapStart.Elapsed.TotalMilliseconds
if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
    Write-PPFLog -Level "INFO" -Message "PPF bootstrapped via Module in $($global:PPF_BootstrapTimeMs) ms."
}

# ------------------------------------------------------------
# Export Module Members
# ------------------------------------------------------------
$PublicFunctions = @(
    "Get-Prompt",
    "Invoke-Prompt",
    "Get-PromptString",
    "New-PromptContext",
    "Initialize-PPFModules",
    "Register-PPFPipelineStep",
    "Invoke-PPFPipeline",
    "Get-PromptProviders",
    "Get-PromptSegments",
    "Get-PromptRenderers",
    "Get-PromptThemes",
    "Get-PromptTheme",
    "Get-ActiveTheme",
    "Set-PromptTheme",
    "Measure-Prompt",
    "Measure-PromptDetailed",
    "Test-PromptFramework",
    "Measure-CpuProvider",
    "Measure-MemoryProvider",
    "Measure-BatteryProvider",
    "Measure-GitProvider",
    "Measure-DockerProvider",
    "Measure-KubernetesProvider",
    "Measure-NodeProvider",
    "Measure-PythonProvider",
    "Measure-SessionProvider",
    "Measure-ProjectProvider",
    "Measure-PathProvider",
    "Measure-WslProvider",
    "Measure-DotNetProvider",
    "Measure-PromptCacheComparison",
    "Measure-PromptProvider",
    "Get-PromptHealth",
    "Set-SegmentConfiguration",
    "Get-SegmentConfiguration",
    "Resolve-ThemeColor",
    "Resolve-ThemeIcon",
    "New-PromptSegment",
    "Register-PromptSegment",
    "Register-PromptProvider",
    "Get-PromptConfiguration",
    "Set-PromptConfiguration",
    "Register-PromptRenderer",
    "Register-PromptTheme",
    "Enable-PromptConfigHotReload",
    "Disable-PromptConfigHotReload",
    "Register-PPFEventListener",
    "Invoke-PPFEvent",
    "Set-PPFCache",
    "Get-PPFCache",
    "Clear-PPFCache",
    "Clear-AllPPFCache",
    "Write-PPFLog",
    "Set-PPFLogLevel"
)

Export-ModuleMember -Function $PublicFunctions

# ------------------------------------------------------------
# Module Cleanup (OnRemove)
# ------------------------------------------------------------
if ($null -ne $MyInvocation.MyCommand.Module) {
    $MyInvocation.MyCommand.Module.OnRemove = {
        if (Get-Command Stop-CpuSampler -ErrorAction SilentlyContinue) {
            Stop-CpuSampler
        }
        if (Get-Command Stop-AllGitWatchers -ErrorAction SilentlyContinue) {
            Stop-AllGitWatchers
        }
    }
}
