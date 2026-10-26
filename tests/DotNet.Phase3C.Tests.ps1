# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Phase3C.Tests.ps1
# Fase 3C: prompt transitorio, tooltips y right prompt en .NET
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - Fase 3C (transient, tooltip, right prompt)" {

    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $script:nordTheme = (Resolve-Path (Join-Path $script:repoRoot "examples\dotnet\theme.nord.ppf.json")).Path
        $script:ompTheme = (Resolve-Path (Join-Path $script:repoRoot "examples\dotnet\theme.omp.json")).Path
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

    Context "Contrato público Fase 3C" {

        It "Exporta Get-PromptTooltip" {
            Get-Command Get-PromptTooltip -Module PablitusPrompt -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It "Get-PromptString -Transient devuelve el prompt transitorio" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $path = Join-Path $TestDrive "transient.ppf.json"
            @'
{
  "renderer": "plain",
  "template": {
    "transientPrompt": "{{ .Shell }}> "
  },
  "theme": {
    "blocks": [
      { "segments": [ { "type": "text", "template": "left" } ] }
    ]
  }
}
'@ | Set-Content -LiteralPath $path -Encoding utf8

            $null = Enable-PPFDotNetCore -ThemePath $path
            $env:PPF_USE_DOTNET_CORE = "1"

            $output = Get-PromptString -Transient -TerminalWidth 80

            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "pwsh> "
        }

        It "Get-PromptTooltip devuelve el tooltip alineado a la derecha" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $path = Join-Path $TestDrive "tooltip.ppf.json"
            @'
{
  "renderer": "plain",
  "tooltipsAction": "replace",
  "tooltips": [
    { "type": "text", "tips": ["git"], "template": "git" }
  ],
  "theme": {
    "blocks": [
      { "segments": [ { "type": "text", "template": "left" } ] }
    ]
  }
}
'@ | Set-Content -LiteralPath $path -Encoding utf8

            $null = Enable-PPFDotNetCore -ThemePath $path
            $env:PPF_USE_DOTNET_CORE = "1"

            $output = Get-PromptTooltip -Command "git status" -TerminalWidth 60 -Column 2

            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "git"
            # El texto del tooltip, sin los espacios de alineación a la derecha
            $output.Trim() | Should -Be "git"
        }

        It "Get-PromptTooltip devuelve vacío cuando no coincide ningún tip" {
            if (-not $script:hasCore) {
                Set-ItResult -Skipped -Because "PablitusPrompt.Core.dll no está compilada"
                return
            }

            $path = Join-Path $TestDrive "tooltip-nomatch.ppf.json"
            @'
{
  "renderer": "plain",
  "tooltips": [
    { "type": "text", "tips": ["git"], "template": "git" }
  ],
  "theme": {
    "blocks": [
      { "segments": [ { "type": "text", "template": "left" } ] }
    ]
  }
}
'@ | Set-Content -LiteralPath $path -Encoding utf8

            $null = Enable-PPFDotNetCore -ThemePath $path
            $env:PPF_USE_DOTNET_CORE = "1"

            $output = Get-PromptTooltip -Command "dotnet build" -TerminalWidth 60

            $output | Should -BeNullOrEmpty
        }

        It "Cae al motor PowerShell cuando el núcleo .NET no está disponible" {
            $env:PPF_USE_DOTNET_CORE = "1"

            $output = Get-PromptString
            $output | Should -BeOfType [string]
        }
    }
}
