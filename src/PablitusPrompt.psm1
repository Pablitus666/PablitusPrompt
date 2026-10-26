# ============================================================
# Pablitus Prompt Framework (PPF)
# PablitusPrompt.psm1
# ============================================================

$script:BootstrapStart = [System.Diagnostics.Stopwatch]::StartNew()
$Root = $PSScriptRoot
$global:PPF_InstallRoot = $Root
$global:PPF_LoadedModules = @()

# ------------------------------------------------------------
# Fast bootstrap
#
# Loading ~67 small files one by one costs far more than parsing
# the same code once. Read the sources in dependency order and
# execute them as a single script in module scope. The modular
# loader remains available with PPF_USE_MODULAR_LOADER=1.
# ------------------------------------------------------------
function Get-PPFSourceFiles {

    param(
        [Parameter(Mandatory)][string]$InstallRoot
    )

    $CoreLoadOrder = @(
        "Prompt.Context.ps1"
        "Prompt.Builder.ps1"
        "Prompt.Cache.ps1"
        "Prompt.Core.ps1"
        "Prompt.Events.ps1"
        "Prompt.Kernel.ps1"
        "Prompt.ModuleLoader.ps1"
        "Prompt.Pipeline.ps1"
        "Prompt.API.ps1"
        "Prompt.Rendering.ps1"
        "Prompt.Segment.Registry.ps1"
        "Prompt.Telemetry.ps1"
        "Prompt.Theme.ps1"
    )

    $files = [System.Collections.Generic.List[string]]::new()
    $corePath = [System.IO.Path]::Combine($InstallRoot, "Core")

    foreach ($name in $CoreLoadOrder) {
        $path = [System.IO.Path]::Combine($corePath, $name)
        if ([System.IO.File]::Exists($path)) {
            $files.Add($path)
        }
    }

    foreach ($path in ([System.IO.Directory]::GetFiles($corePath, "*.ps1") | Sort-Object)) {
        if (-not $files.Contains($path)) {
            $files.Add($path)
        }
    }

    foreach ($path in ([System.IO.Directory]::GetFiles([System.IO.Path]::Combine($InstallRoot, "Configuration"), "*.ps1") | Sort-Object)) {
        $files.Add($path)
    }

    foreach ($path in ([System.IO.Directory]::GetFiles([System.IO.Path]::Combine($InstallRoot, "Utils"), "*.ps1") | Sort-Object)) {
        $files.Add($path)
    }

    $modulesPath = [System.IO.Path]::Combine($InstallRoot, "Modules")
    foreach ($dir in ([System.IO.Directory]::GetDirectories($modulesPath) | Sort-Object)) {
        $moduleFiles = [System.IO.Directory]::GetFiles($dir, "*.ps1")
        $providers = @($moduleFiles | Where-Object { $_.EndsWith(".Provider.ps1", [System.StringComparison]::OrdinalIgnoreCase) } | Sort-Object)
        $services = @($moduleFiles | Where-Object { $_.EndsWith(".Service.ps1", [System.StringComparison]::OrdinalIgnoreCase) } | Sort-Object)
        $segments = @($moduleFiles | Where-Object { $_.EndsWith(".Segment.ps1", [System.StringComparison]::OrdinalIgnoreCase) } | Sort-Object)
        $others = @($moduleFiles | Where-Object {
            -not $_.EndsWith(".Provider.ps1", [System.StringComparison]::OrdinalIgnoreCase) -and
            -not $_.EndsWith(".Service.ps1", [System.StringComparison]::OrdinalIgnoreCase) -and
            -not $_.EndsWith(".Segment.ps1", [System.StringComparison]::OrdinalIgnoreCase) -and
            -not $_.EndsWith(".Tests.ps1", [System.StringComparison]::OrdinalIgnoreCase)
        } | Sort-Object)

        foreach ($path in $providers) { $files.Add($path) }
        foreach ($path in $services) { $files.Add($path) }
        foreach ($path in $segments) { $files.Add($path) }
        foreach ($path in $others) { $files.Add($path) }
    }

    foreach ($path in ([System.IO.Directory]::GetFiles([System.IO.Path]::Combine($InstallRoot, "Themes"), "*.Theme.ps1") | Sort-Object)) {
        $files.Add($path)
    }

    foreach ($path in ([System.IO.Directory]::GetFiles([System.IO.Path]::Combine($InstallRoot, "Renderers"), "*.ps1", [System.IO.SearchOption]::AllDirectories) | Sort-Object)) {
        $files.Add($path)
    }

    return $files
}

$PPFModularBootstrap = {

    $CorePath = Join-Path $Root "Core"
    $CoreLoadOrder = @(
        "Prompt.Context.ps1"
        "Prompt.Builder.ps1"
        "Prompt.Cache.ps1"
        "Prompt.Core.ps1"
        "Prompt.Events.ps1"
        "Prompt.Kernel.ps1"
        "Prompt.ModuleLoader.ps1"
        "Prompt.Pipeline.ps1"
        "Prompt.API.ps1"
        "Prompt.Rendering.ps1"
        "Prompt.Segment.Registry.ps1"
        "Prompt.Telemetry.ps1"
        "Prompt.Theme.ps1"
    )

    $LoadedCoreFiles = @()

    foreach ($CoreFileName in $CoreLoadOrder) {
        $CoreFilePath = Join-Path $CorePath $CoreFileName
        if (Test-Path -LiteralPath $CoreFilePath) {
            $ResolvedCoreFilePath = (Resolve-Path -LiteralPath $CoreFilePath).Path
            if ($ResolvedCoreFilePath -notin $LoadedCoreFiles) {
                . $ResolvedCoreFilePath
                $LoadedCoreFiles += $ResolvedCoreFilePath
            }
        }
    }

    Get-ChildItem -LiteralPath $CorePath -Filter "*.ps1" -File |
        Sort-Object Name |
        Where-Object { $_.FullName -notin $LoadedCoreFiles } |
        ForEach-Object {
            . $_.FullName
            $LoadedCoreFiles += $_.FullName
        }

    Get-ChildItem -Path (Join-Path $Root "Configuration") -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }

    Get-ChildItem -Path (Join-Path $Root "Utils") -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }

    . Initialize-PPFModules -ModulesPath (Join-Path $Root "Modules")

    Get-ChildItem -Path (Join-Path $Root "Themes") -Filter "*.Theme.ps1" | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }

    Get-ChildItem -Path (Join-Path (Join-Path $Root "Renderers") "*") -Filter "*.ps1" -Recurse | Sort-Object FullName | ForEach-Object {
        . $_.FullName
    }
}

$UseModularLoader = $env:PPF_USE_MODULAR_LOADER -eq "1"

if ($UseModularLoader) {
    $global:PPF_BootstrapMode = "Modular"
    . $PPFModularBootstrap
}
else {
    $global:PPF_BootstrapMode = "Fast"
    try {
        $PPFSourceFiles = Get-PPFSourceFiles -InstallRoot $Root
        $PPFBuilder = [System.Text.StringBuilder]::new(512KB)

        foreach ($PPFFile in $PPFSourceFiles) {
            [void]$PPFBuilder.AppendLine("#region FILE: $PPFFile")
            [void]$PPFBuilder.AppendLine([System.IO.File]::ReadAllText($PPFFile))
            [void]$PPFBuilder.AppendLine("#endregion")
        }

        Invoke-Expression $PPFBuilder.ToString()

        # The fast loader also emits ModuleLoaded events (and records the
        # loaded modules) so its observable behaviour matches the modular one.
        $modulesRoot = [System.IO.Path]::Combine($Root, "Modules")
        if ([System.IO.Directory]::Exists($modulesRoot)) {
            $moduleNames = @(
                [System.IO.Directory]::GetDirectories($modulesRoot) |
                    Sort-Object |
                    ForEach-Object { [System.IO.Path]::GetFileName($_) }
            )
            $global:PPF_LoadedModules = $moduleNames
            if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
                foreach ($moduleName in $moduleNames) {
                    Invoke-PPFEvent -EventName "ModuleLoaded" -EventArgs $moduleName
                }
            }
        }
    }
    catch {
        throw "PPF fast bootstrap failed: $($_.Exception.Message) Start PowerShell with `$env:PPF_USE_MODULAR_LOADER = '1' to use the compatibility loader."
    }
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
# Theme baseline
#
# Capture the pristine segment configuration once the whole module is
# loaded. If this were captured lazily on the first theme switch, any
# user configuration applied before that point would become the baseline
# and could never be restored.
# ------------------------------------------------------------
if (Get-Command Get-PPFThemeBaseline -ErrorAction SilentlyContinue) {
    $null = Get-PPFThemeBaseline
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
    "Import-PromptTheme",
    "Set-PromptTheme",
    "Switch-PromptTheme",
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
    "Import-PromptConfiguration",
    "Export-PromptConfiguration",
    "Register-PPFEventListener",
    "Invoke-PPFEvent",
    "Set-PPFCache",
    "Get-PPFCache",
    "Clear-PPFCache",
    "Clear-AllPPFCache",
    "Write-PPFLog",
    "Set-PPFLogLevel",
    "Test-PPFDotNetCoreAvailable",
    "Enable-PPFDotNetCore",
    "Disable-PPFDotNetCore",
    "Get-PPFDotNetCoreStatus",
    "Import-PPFDotNetTheme",
    "Get-PromptTooltip"
)

Export-ModuleMember -Function $PublicFunctions

# ------------------------------------------------------------
# Module Cleanup (OnRemove)
# ------------------------------------------------------------
if ($null -ne $MyInvocation.MyCommand.Module) {
    $MyInvocation.MyCommand.Module.OnRemove = {
        if (Get-Command Clear-PPFDotNetPluginProviders -ErrorAction SilentlyContinue) {
            Clear-PPFDotNetPluginProviders
        }
        if (Get-Command Sync-PPFDiskCache -ErrorAction SilentlyContinue) {
            Sync-PPFDiskCache
        }
        if (Get-Command Stop-CpuSampler -ErrorAction SilentlyContinue) {
            Stop-CpuSampler
        }
        if (Get-Command Stop-AllGitWatchers -ErrorAction SilentlyContinue) {
            Stop-AllGitWatchers
        }
    }
}
