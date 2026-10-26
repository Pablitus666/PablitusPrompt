# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Parity.Tests.ps1
# Fase 3B: paridad de salida entre el motor legacy y .NET
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) "src/PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - .NET output parity" {

    BeforeAll {
        $script:pluginName = "PpfParityPlugin"
        $script:initialStatus = Get-PPFDotNetCoreStatus
        $script:hasCore = [bool]$script:initialStatus.Available
        $script:originalExitCode = $global:LASTEXITCODE
        $script:originalEnv = @{
            PPF_USE_DOTNET_CORE = $env:PPF_USE_DOTNET_CORE
            PPF_DOTNET_THEME    = $env:PPF_DOTNET_THEME
            PPF_DOTNET_CORE_DLL = $env:PPF_DOTNET_CORE_DLL
        }

        function Remove-ParityPlugin {

            $module = Get-Module PablitusPrompt
            & $module {
                param($name)

                $script:PromptSegments = @(
                    $script:PromptSegments |
                        Where-Object Name -ne $name
                )
                $script:PromptSegmentsSorted = $null
                $script:PromptSegmentsVersion = [int]$script:PromptSegmentsVersion + 1

                if ($script:PromptConfiguration.Segments.ContainsKey($name)) {
                    $null = $script:PromptConfiguration.Segments.Remove($name)
                }
            } $script:pluginName
        }

        function New-ParityTheme {

            $path = Join-Path $TestDrive "ParityTheme.json"
            $document = [ordered]@{
                '$schema'  = "https://pablitus.dev/schemas/theme.schema.json"
                name       = "ParityTheme"
                version    = "1.0"
                renderer   = "plain"
                finalSpace = $false
                palette    = @{ text = "#ffffff" }
                blocks     = @(
                    [ordered]@{
                        type      = "prompt"
                        alignment = "left"
                        newline   = $false
                        segments  = @(
                            [ordered]@{
                                type       = $script:pluginName
                                name       = "parity"
                                style      = "plain"
                                foreground = "text"
                                properties = @{ marker = "same" }
                            }
                        )
                    }
                )
            }

            $document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding utf8
            return $path
        }
    }

    AfterAll {
        $null = Disable-PPFDotNetCore
        Remove-ParityPlugin
        $global:LASTEXITCODE = $script:originalExitCode

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
        Remove-ParityPlugin
    }

    AfterEach {
        $null = Disable-PPFDotNetCore
        Remove-ParityPlugin
        $global:LASTEXITCODE = $script:originalExitCode
    }

    It "Un plugin produce el mismo texto y aparece en ambos renderers" {
        if (-not $script:hasCore) {
            Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
            return
        }

        $global:LASTEXITCODE = 0

        Register-PromptSegment -Name $script:pluginName -Priority 10 -Script {
            param([PromptContext]$Context)

            $config = Get-SegmentConfiguration -Name "PpfParityPlugin"
            $text = @(
                "parity=$($config.Marker)"
                "user=$($Context.Session.User)"
                "host=$($Context.Session.Host)"
                "path=$($Context.Path.Current)"
                "year=$($Context.Timestamp.ToString('yyyy'))"
            ) -join ";"

            New-PromptSegment -Name "PpfParityPlugin" -Text $text
        }

        Set-SegmentConfiguration -Name $script:pluginName -Configuration @{
            Visible    = $true
            Icon       = ""
            Foreground = "White"
            Background = ""
            Marker     = "same"
        }

        $legacyContext = Invoke-Prompt
        $legacySegment = $legacyContext.Segments |
            Where-Object Name -eq $script:pluginName |
            Select-Object -First 1

        $legacySegment | Should -Not -BeNullOrEmpty

        $theme = New-ParityTheme
        $status = Enable-PPFDotNetCore -ThemePath $theme
        $state = & (Get-Module PablitusPrompt) { $script:PPFDotNetCore }
        $dotNetContext = [PablitusPrompt.Core.Segments.PromptContextFactory]::Create(
            (Get-Location).Path,
            0
        )
        $dotNetResult = $state.Engine.RenderAsync(
            $state.Config,
            $dotNetContext,
            $null,
            [System.Threading.CancellationToken]::None
        ).GetAwaiter().GetResult()
        $dotNetSegment = $dotNetResult.Segments |
            Where-Object Type -eq $script:pluginName |
            Select-Object -First 1

        $status.PluginTypes | Should -Contain $script:pluginName
        $dotNetSegment | Should -Not -BeNullOrEmpty
        $dotNetSegment.Status | Should -Be "Success"
        $dotNetSegment.Text | Should -Be $legacySegment.Text
        $dotNetSegment.Text | Should -Match "^parity=same;user=.+;host=.+"

        $global:LASTEXITCODE = 0
        $legacyOutput = Get-PromptString -Context $legacyContext -Renderer Plain
        $dotNetOutput = Get-PromptString

        $legacyOutput | Should -Match ([regex]::Escape($legacySegment.Text))
        $dotNetOutput | Should -Match ([regex]::Escape($dotNetSegment.Text))
    }
}
