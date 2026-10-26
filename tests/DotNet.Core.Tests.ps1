# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Core.Tests.ps1
# Fase 2: adaptador PowerShell -> núcleo .NET
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - .NET core adapter" {

    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $script:nordTheme = (Resolve-Path (Join-Path $script:repoRoot "examples\dotnet\theme.nord.ppf.json")).Path
        $script:ompTheme = (Resolve-Path (Join-Path $script:repoRoot "examples\dotnet\theme.omp.json")).Path
        $script:configExample = (Resolve-Path (Join-Path $script:repoRoot "examples\dotnet\config.ppf.json")).Path
        $script:initialStatus = Get-PPFDotNetCoreStatus
        $script:hasCore = [bool]$script:initialStatus.Available

        $script:originalEnv = @{
            PPF_USE_DOTNET_CORE = $env:PPF_USE_DOTNET_CORE
            PPF_DOTNET_THEME    = $env:PPF_DOTNET_THEME
            PPF_DOTNET_CORE_DLL = $env:PPF_DOTNET_CORE_DLL
        }
    }

    AfterAll {
        Remove-Item Env:\PPF_USE_DOTNET_CORE -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_THEME -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_CORE_DLL -ErrorAction SilentlyContinue

        foreach ($name in $script:originalEnv.Keys) {
            if ($null -ne $script:originalEnv[$name]) {
                Set-Item -Path "Env:\$name" -Value $script:originalEnv[$name]
            }
        }

        $null = Disable-PPFDotNetCore
    }

    BeforeEach {
        Remove-Item Env:\PPF_USE_DOTNET_CORE -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_THEME -ErrorAction SilentlyContinue
        Remove-Item Env:\PPF_DOTNET_CORE_DLL -ErrorAction SilentlyContinue
        $null = Disable-PPFDotNetCore
    }

    Context "Contrato público" {

        It "Exporta las funciones del adaptador" {
            foreach ($name in @(
                "Test-PPFDotNetCoreAvailable",
                "Enable-PPFDotNetCore",
                "Disable-PPFDotNetCore",
                "Get-PPFDotNetCoreStatus",
                "Import-PPFDotNetTheme"
            )) {
                Get-Command $name -Module PablitusPrompt -ErrorAction SilentlyContinue |
                    Should -Not -BeNullOrEmpty
            }
        }

        It "Informa disponibilidad y estado coherentes" {
            $status = Get-PPFDotNetCoreStatus
            $status.PSObject.Properties.Name | Should -Contain "Enabled"
            $status.PSObject.Properties.Name | Should -Contain "Available"
            $status.Enabled | Should -BeFalse
            (Test-PPFDotNetCoreAvailable) | Should -BeOfType [bool]
        }

        It "Disable-PPFDotNetCore deja el adaptador inactivo" {
            $status = Disable-PPFDotNetCore
            $status.Enabled | Should -BeFalse
            $status.EngineReady | Should -BeFalse
            $status.ThemePath | Should -BeNullOrEmpty
        }
    }

    Context "Carga de temas" {

        It "Activa un tema PPF JSON" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $status = Enable-PPFDotNetCore -ThemePath $script:nordTheme

            $status.Enabled | Should -BeTrue
            $status.AssemblyLoaded | Should -BeTrue
            $status.EngineReady | Should -BeTrue
            $status.ThemeKind | Should -Be "PpfTheme"
            $status.ThemePath | Should -Be $script:nordTheme
            $status.LastError | Should -BeNullOrEmpty
        }

        It "Detecta y activa un tema de Oh My Posh" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $status = Enable-PPFDotNetCore -ThemePath $script:ompTheme

            $status.Enabled | Should -BeTrue
            $status.ThemeKind | Should -Be "Omp"
            $status.EngineReady | Should -BeTrue
        }

        It "Activa una configuración PPF con tema embebido" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $status = Enable-PPFDotNetCore -ThemePath $script:configExample

            $status.Enabled | Should -BeTrue
            $status.ThemeKind | Should -Be "PpfConfig"
        }

        It "Import-PPFDotNetTheme -Activate carga y activa el tema" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $config = Import-PPFDotNetTheme -Path $script:nordTheme -Activate

            $config | Should -Not -BeNullOrEmpty
            $config.Theme | Should -Not -BeNullOrEmpty
            (Get-PPFDotNetCoreStatus).Enabled | Should -BeTrue
        }

        It "Rechaza segmentos OMP no soportados salvo con -IgnoreUnsupported" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $path = Join-Path $TestDrive "unsupported.omp.json"
            @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        { "type": "os", "style": "plain", "template": "OS" },
        { "type": "text", "style": "plain", "template": "OK" }
      ]
    }
  ]
}
'@ | Set-Content -LiteralPath $path -Encoding utf8

            { Enable-PPFDotNetCore -ThemePath $path } | Should -Throw "*Unsupported*"

            $status = Enable-PPFDotNetCore -ThemePath $path -IgnoreUnsupported
            $status.Enabled | Should -BeTrue
            $status.ThemeKind | Should -Be "Omp"
        }
    }

    Context "Get-PromptString" {

        It "Usa el núcleo .NET cuando PPF_USE_DOTNET_CORE=1" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $null = Enable-PPFDotNetCore -ThemePath $script:nordTheme
            $env:PPF_USE_DOTNET_CORE = "1"

            $output = Get-PromptString
            $status = Get-PPFDotNetCoreStatus

            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "@"
            $output | Should -Match ([regex]::Escape([string][char]27))
            $status.RenderCount | Should -BeGreaterThan 0
            $status.FallbackCount | Should -Be 0
        }

        It "Mantiene el motor legacy cuando se pasa -Context explícito" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $null = Enable-PPFDotNetCore -ThemePath $script:nordTheme
            $env:PPF_USE_DOTNET_CORE = "1"

            $context = Invoke-Prompt
            $renderCountBefore = (Get-PPFDotNetCoreStatus).RenderCount
            $legacy = Get-PromptString -Context $context -Renderer Plain

            $legacy | Should -BeOfType [string]
            (Get-PPFDotNetCoreStatus).RenderCount | Should -Be $renderCountBefore
        }

        It "Mantiene los renderers legacy no soportados en PowerShell" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $null = Enable-PPFDotNetCore -ThemePath $script:nordTheme
            $env:PPF_USE_DOTNET_CORE = "1"
            $renderCountBefore = (Get-PPFDotNetCoreStatus).RenderCount

            $output = Get-PromptString -Renderer Minimal

            $output | Should -BeOfType [string]
            (Get-PPFDotNetCoreStatus).RenderCount | Should -Be $renderCountBefore
            $output | Should -Not -Match ([regex]::Escape([string][char]27))
        }

        It "Cae al motor PowerShell si el tema configurado no existe" {
            $env:PPF_USE_DOTNET_CORE = "1"
            $env:PPF_DOTNET_THEME = (Join-Path $TestDrive "missing-theme.json")

            $output = Get-PromptString
            $status = Get-PPFDotNetCoreStatus

            $output | Should -Not -BeNullOrEmpty
            $status.Enabled | Should -BeFalse
            $status.LastError | Should -Not -BeNullOrEmpty
        }

        It "Cae al motor PowerShell si la DLL no existe" {
            $env:PPF_DOTNET_CORE_DLL = Join-Path $TestDrive "missing-core.dll"
            $env:PPF_USE_DOTNET_CORE = "1"
            $env:PPF_DOTNET_THEME = $script:nordTheme

            (Test-PPFDotNetCoreAvailable -Refresh) | Should -BeFalse

            $output = Get-PromptString
            $status = Get-PPFDotNetCoreStatus

            $output | Should -Not -BeNullOrEmpty
            $status.Enabled | Should -BeFalse
            $status.LastError | Should -Match "assembly not found"
        }

        It "Respeta un tema OMP activado por entorno" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $env:PPF_USE_DOTNET_CORE = "1"
            $env:PPF_DOTNET_THEME = $script:ompTheme

            $output = Get-PromptString

            $output | Should -Not -BeNullOrEmpty
            (Get-PPFDotNetCoreStatus).ThemeKind | Should -Be "Omp"
        }
    }
}
