# ============================================================
# Pablitus Prompt Framework (PPF)
# Smoke.CrossPlatform.ps1
#
# Lightweight smoke test for Linux/macOS runners. It validates the
# observable contract of the module (registration counts, rendering,
# theming and configuration round-trips) without Pester.
# ============================================================

[CmdletBinding()]
param(
    [switch]$Modular
)

$ErrorActionPreference = "Stop"

function Assert-PPF {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw "SMOKE FAILED: $Message"
    }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$manifestPath = Join-Path (Join-Path $repoRoot "src") "PablitusPrompt.psd1"

if ($Modular) {
    $env:PPF_USE_MODULAR_LOADER = "1"
}
else {
    Remove-Item Env:\PPF_USE_MODULAR_LOADER -ErrorAction SilentlyContinue
}

Import-Module $manifestPath -Force

Write-Host "PPF smoke test | PowerShell $($PSVersionTable.PSVersion) | $($PSVersionTable.OS)"
Write-Host "Bootstrap mode: $($global:PPF_BootstrapMode)"

# --- Registration contract ---------------------------------
$providers = @(Get-PromptProviders)
$module = Get-Module PablitusPrompt
$segments = @(& $module { $script:PromptSegments })
$renderers = @(Get-PromptRenderers)
$themes = @(Get-PromptThemes)

Write-Host "Providers: $($providers.Count) | Segments: $($segments.Count) | Renderers: $($renderers.Count) | Themes: $($themes.Count)"

Assert-PPF ($providers.Count -eq 13) "expected 13 providers, got $($providers.Count)"
Assert-PPF ($segments.Count -eq 14) "expected 14 segments, got $($segments.Count)"
Assert-PPF ($renderers.Count -eq 8) "expected 8 renderers, got $($renderers.Count)"
Assert-PPF ($themes.Count -eq 5) "expected 5 themes, got $($themes.Count)"

$expectedMode = if ($Modular) { "Modular" } else { "Fast" }
Assert-PPF ($global:PPF_BootstrapMode -eq $expectedMode) "expected bootstrap mode '$expectedMode', got '$($global:PPF_BootstrapMode)'"
Assert-PPF (@($global:PPF_LoadedModules).Count -eq 14) "expected 14 loaded modules, got $(@($global:PPF_LoadedModules).Count)"

# --- Rendering across every theme/renderer pair -------------
$rendered = 0
foreach ($theme in $themes) {
    $themeName = $theme.Name
    Set-PromptTheme -Name $themeName
    foreach ($rendererName in $renderers) {
        $output = Get-PromptString -Renderer $rendererName
        Assert-PPF (-not [string]::IsNullOrWhiteSpace($output)) "empty output for $themeName/$rendererName"
        if ($rendererName -eq "JSON") {
            $null = $output | ConvertFrom-Json
        }
        $rendered++
    }
}
Set-PromptTheme -Name "Default"
Write-Host "Rendered $rendered theme/renderer combinations."

# --- Configuration round-trip -------------------------------
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ppf-smoke-" + [guid]::NewGuid().ToString("N"))
$null = New-Item -ItemType Directory -Path $tempDir -Force
try {
    foreach ($format in @("json", "psd1")) {
        $configPath = Join-Path $tempDir "ppf-config.$format"
        Export-PromptConfiguration -Path $configPath
        Assert-PPF (Test-Path -LiteralPath $configPath) "configuration was not exported to $format"
        Import-PromptConfiguration -Path $configPath
    }
}
finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Theme isolation ----------------------------------------
Set-PromptTheme -Name "Kali"
$null = Get-PromptString
Set-PromptTheme -Name "Default"
$defaultOutput = Get-PromptString
Assert-PPF (-not [string]::IsNullOrWhiteSpace($defaultOutput)) "default theme produced no output after Kali"
Assert-PPF ((Get-ActiveTheme).Name -eq "Default") "active theme did not return to Default"

Write-Host "SMOKE OK ($expectedMode bootstrap)"
