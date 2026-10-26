# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.PluginHost.Tests.ps1
# Fase 3A: host de plugins PowerShell en runspaces
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - PowerShell plugin host" {

    BeforeAll {
        function New-PluginTestTheme {

            param(
                [Parameter(Mandatory)][string]$Name,
                [Parameter(Mandatory)][object[]]$Segments
            )

            $path = Join-Path $TestDrive "$Name.json"
            $document = [ordered]@{
                '$schema'   = 'https://pablitus.dev/schemas/theme.schema.json'
                name        = $Name
                version     = '1.0'
                renderer    = 'plain'
                finalSpace  = $false
                palette     = @{
                    text = '#ffffff'
                    bg   = '#123456'
                }
                blocks      = @(
                    [ordered]@{
                        type      = 'prompt'
                        alignment = 'left'
                        newline   = $false
                        segments  = @($Segments)
                    }
                )
            }

            $document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding utf8
            return $path
        }

        function New-PluginTestSegment {

            param(
                [Parameter(Mandatory)][string]$Type,
                [string]$Name = $Type,
                [hashtable]$Properties,
                [int]$TimeoutMs,
                [string]$Template
            )

            $segment = [ordered]@{
                type       = $Type
                name       = $Name
                style      = 'plain'
                foreground = 'text'
            }

            if ($null -ne $Properties -and $Properties.Count -gt 0) {
                $segment.properties = $Properties
            }

            if ($TimeoutMs -gt 0) {
                $segment.timeoutMs = $TimeoutMs
            }

            if (-not [string]::IsNullOrWhiteSpace($Template)) {
                $segment.template = $Template
            }

            return [pscustomobject]$segment
        }

        function Get-PluginTestState {

            return (& (Get-Module PablitusPrompt) { $script:PPFDotNetCore })
        }

        function Invoke-PluginTestRender {

            param(
                [int]$ExitCode = 0,
                [System.Threading.CancellationToken]$CancellationToken = [System.Threading.CancellationToken]::None
            )

            $state = Get-PluginTestState
            if ($null -eq $state.Engine -or $null -eq $state.Config) {
                throw "The .NET engine is not enabled."
            }

            $context = [PablitusPrompt.Core.Segments.PromptContextFactory]::Create(
                (Get-Location).Path,
                $ExitCode
            )

            return $state.Engine.RenderAsync(
                $state.Config,
                $context,
                $null,
                $CancellationToken
            ).GetAwaiter().GetResult()
        }

        function Remove-PluginTestSegment {

            param(
                [Parameter(Mandatory)][string]$Name
            )

            $module = Get-Module PablitusPrompt
            & $module {
                param($segmentName)

                $script:PromptSegments = @(
                    $script:PromptSegments |
                        Where-Object Name -ne $segmentName
                )
                $script:PromptSegmentsSorted = $null
                $script:PromptSegmentsVersion = [int]$script:PromptSegmentsVersion + 1
            } $Name
        }

        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $script:initialStatus = Get-PPFDotNetCoreStatus
        $script:hasCore = [bool]$script:initialStatus.Available
        $script:testPluginNames = @(
            "PpfTestConfig",
            "PpfTestContext",
            "PpfTestError",
            "PpfTestSlow",
            "text"
        )

        $script:originalEnv = @{
            PPF_USE_DOTNET_CORE = $env:PPF_USE_DOTNET_CORE
            PPF_DOTNET_THEME    = $env:PPF_DOTNET_THEME
            PPF_DOTNET_CORE_DLL = $env:PPF_DOTNET_CORE_DLL
        }
    }

    AfterAll {
        $null = Disable-PPFDotNetCore

        foreach ($name in $script:testPluginNames) {
            Remove-PluginTestSegment -Name $name
        }

        Remove-Item Env:\PPF_USE_DOTNET_CORE -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_THEME -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_CORE_DLL -ErrorAction SilentlyContinue

        foreach ($name in $script:originalEnv.Keys) {
            if ($null -ne $script:originalEnv[$name]) {
                Set-Item -Path "Env:\$name" -Value $script:originalEnv[$name]
            }
        }
    }

    BeforeEach {
        Remove-Item Env:\PPF_USE_DOTNET_CORE -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_THEME -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_CORE_DLL -ErrorAction SilentlyContinue
        $null = Disable-PPFDotNetCore
    }

    AfterEach {
        $null = Disable-PPFDotNetCore

        foreach ($name in $script:testPluginNames) {
            Remove-PluginTestSegment -Name $name
        }
    }

    Context "Descubrimiento y ciclo de vida" {

        It "Registra los plugins PPF y limpia los proveedores al desactivar" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestConfig"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                New-PromptSegment -Name "PpfTestConfig" -Text "discovered"
            }

            $theme = New-PluginTestTheme -Name "PluginLifecycle" -Segments @(
                New-PluginTestSegment -Type $pluginName
            )

            $status = Enable-PPFDotNetCore -ThemePath $theme

            $status.Enabled | Should -BeTrue
            $status.EngineReady | Should -BeTrue
            $status.PluginHostReady | Should -BeTrue
            $status.PluginHostError | Should -BeNullOrEmpty
            $status.PluginCount | Should -BeGreaterThan 0
            $status.PluginTypes | Should -Contain $pluginName

            $disabled = Disable-PPFDotNetCore

            $disabled.Enabled | Should -BeFalse
            $disabled.EngineReady | Should -BeFalse
            $disabled.PluginCount | Should -Be 0
            @($disabled.PluginTypes).Count | Should -Be 0
        }

        It "No permite que un plugin tape un proveedor nativo .NET" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            Register-PromptSegment -Name "text" -Priority 10 -Script {
                param([PromptContext]$Context)

                New-PromptSegment -Name "text" -Text "FROM-PLUGIN"
            }

            $theme = New-PluginTestTheme -Name "PluginShadow" -Segments @(
                New-PluginTestSegment -Type "text" -Name "shadow" -Template "FROM-CORE"
            )

            $status = Enable-PPFDotNetCore -ThemePath $theme
            $result = Invoke-PluginTestRender
            $segment = $result.Segments | Select-Object -First 1

            @($status.PluginTypes | Where-Object { $_ -ieq "text" }).Count | Should -Be 0
            $segment.Status | Should -Be "Success"
            $segment.Text | Should -Be "FROM-CORE"
        }
    }

    Context "Mapeo de contexto y configuración" {

        It "Aplica las propiedades del tema, incluidas las anidadas" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestConfig"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                $config = Get-SegmentConfiguration -Name "PpfTestConfig"
                $text = @(
                    "message=$($config.Message)"
                    "count=$($config.Count)"
                    "enabled=$($config.Enabled)"
                    "nested=$($config.Nested.Value)"
                    "tags=$($config.Tags -join ',')"
                ) -join ";"

                New-PromptSegment -Name "PpfTestConfig" -Text $text
            }

            $properties = @{
                message = "from-config"
                count   = 3
                enabled = $true
                nested  = @{ value = "nested-ok" }
                tags    = @("one", "two")
            }
            $theme = New-PluginTestTheme -Name "PluginConfig" -Segments @(
                New-PluginTestSegment -Type $pluginName -Name "config" -Properties $properties
            )

            $null = Enable-PPFDotNetCore -ThemePath $theme
            $result = Invoke-PluginTestRender
            $segment = $result.Segments | Select-Object -First 1

            $segment.Status | Should -Be "Success"
            $segment.Text | Should -Be "message=from-config;count=3;enabled=True;nested=nested-ok;tags=one,two"
        }

        It "Mapea sesión, path, git, timestamp, exit code y PWD al contexto legacy" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestContext"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                $text = @(
                    "user=$($Context.Session.User)"
                    "host=$($Context.Session.Host)"
                    "path=$($Context.Path.Current)"
                    "friendly=$($Context.Path.Friendly)"
                    "git=$($Context.Git.Branch)"
                    "ts=$($Context.Timestamp.ToString('yyyy'))"
                    "exit=$($global:LASTEXITCODE)"
                    "pwd=$($PWD.Path)"
                ) -join ";"

                New-PromptSegment -Name "PpfTestContext" -Text $text
            }

            $theme = New-PluginTestTheme -Name "PluginContext" -Segments @(
                New-PluginTestSegment -Type $pluginName -Name "context"
            )

            $null = Enable-PPFDotNetCore -ThemePath $theme
            $result = Invoke-PluginTestRender -ExitCode 7
            $segment = $result.Segments | Select-Object -First 1
            $currentPath = [regex]::Escape((Get-Location).Path)

            $segment.Status | Should -Be "Success"
            $segment.Text | Should -Match "user=.+;host=.+"
            $segment.Text | Should -Match "path=$currentPath"
            $segment.Text | Should -Match "friendly=$currentPath"
            $segment.Text | Should -Match "ts=$((Get-Date).Year)"
            $segment.Text | Should -Match "exit=7"
            $segment.Text | Should -Match "pwd=$currentPath"
        }
    }

    Context "Aislamiento de errores y timeouts" {

        It "Aísla un plugin que falla y mantiene el resto del prompt" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestError"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                throw "plugin boom"
            }

            $theme = New-PluginTestTheme -Name "PluginError" -Segments @(
                New-PluginTestSegment -Type $pluginName -Name "broken"
                New-PluginTestSegment -Type "text" -Name "healthy" -Template "OK"
            )

            $null = Enable-PPFDotNetCore -ThemePath $theme
            $result = Invoke-PluginTestRender
            $broken = $result.Segments | Where-Object Name -eq "broken"
            $healthy = $result.Segments | Where-Object Name -eq "healthy"

            $broken.Status | Should -Be "Failed"
            $broken.Visible | Should -BeFalse
            $broken.Error | Should -Match "plugin boom"
            $healthy.Status | Should -Be "Success"
            $healthy.Text | Should -Be "OK"
        }

        It "Aplica el timeout del segmento sin bloquear el prompt" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestSlow"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                Start-Sleep -Milliseconds 5000
                New-PromptSegment -Name "PpfTestSlow" -Text "late"
            }

            $theme = New-PluginTestTheme -Name "PluginTimeout" -Segments @(
                New-PluginTestSegment -Type $pluginName -Name "slow" -TimeoutMs 100
            )

            $null = Enable-PPFDotNetCore -ThemePath $theme
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-PluginTestRender
            $stopwatch.Stop()
            $segment = $result.Segments | Select-Object -First 1

            $stopwatch.Elapsed | Should -BeLessThan ([timespan]::FromSeconds(3))
            $segment.Status | Should -Be "TimedOut"
            $segment.Visible | Should -BeFalse
            $segment.Error | Should -Match "timed out"
        }

        It "Marca como cancelado un render cancelado externamente" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $pluginName = "PpfTestSlow"
            Register-PromptSegment -Name $pluginName -Priority 10 -Script {
                param([PromptContext]$Context)

                Start-Sleep -Milliseconds 5000
                New-PromptSegment -Name "PpfTestSlow" -Text "late"
            }

            $theme = New-PluginTestTheme -Name "PluginCancellation" -Segments @(
                New-PluginTestSegment -Type $pluginName -Name "cancelled" -TimeoutMs 10000
            )

            $null = Enable-PPFDotNetCore -ThemePath $theme
            $cancellation = [System.Threading.CancellationTokenSource]::new(100)

            try {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $result = Invoke-PluginTestRender -CancellationToken $cancellation.Token
                $stopwatch.Stop()
            }
            finally {
                $cancellation.Dispose()
            }

            $segment = $result.Segments | Select-Object -First 1

            $stopwatch.Elapsed | Should -BeLessThan ([timespan]::FromSeconds(3))
            $segment.Status | Should -Be "Cancelled"
            $segment.Visible | Should -BeFalse
        }
    }
}
