# ============================================================
# Pablitus Prompt Framework (PPF)
# Regression.Fixes.Tests.ps1
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - Regression Fixes" {

    BeforeAll {
        $global:PPF_InsidePester = $true
        $script:module = Get-Module PablitusPrompt
        $script:gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
    }

    AfterAll {
        Set-PromptTheme -Name "Default"
        Clear-AllPPFCache
    }

    Context "External command working directory" {

        It "Ejecuta comandos externos en el directorio actual de PowerShell" {
            if (-not $script:gitAvailable) {
                Set-ItResult -Skipped -Because "git is not installed"
                return
            }

            $repoPath = Join-Path $TestDrive "external-cwd"
            $null = New-Item -ItemType Directory -Path $repoPath -Force
            Push-Location $repoPath
            try {
                & git init -q 2>$null | Out-Null
                $expected = (Resolve-Path -LiteralPath $repoPath).ProviderPath
                $result = & $script:module {
                    Invoke-PPFExternalCommand -Command "git" -Arguments @("rev-parse", "--show-toplevel") -TimeoutMs 5000
                }

                $result.Installed | Should -BeTrue
                $result.ExitCode | Should -Be 0
                ($result.Output.Trim() -replace '\\', '/').TrimEnd('/') |
                    Should -Be (($expected -replace '\\', '/').TrimEnd('/'))
            }
            finally {
                Pop-Location
            }
        }

        It "Respeta un WorkingDirectory explícito" {
            if (-not $script:gitAvailable) {
                Set-ItResult -Skipped -Because "git is not installed"
                return
            }

            $repoPath = Join-Path $TestDrive "explicit-cwd"
            $null = New-Item -ItemType Directory -Path $repoPath -Force
            & git -C $repoPath init -q 2>$null | Out-Null

            $result = & $script:module {
                param($Directory)
                Invoke-PPFExternalCommand -Command "git" -Arguments @("rev-parse", "--show-toplevel") -TimeoutMs 5000 -WorkingDirectory $Directory
            } $repoPath

            $result.ExitCode | Should -Be 0
            $expected = (Resolve-Path -LiteralPath $repoPath).ProviderPath
            ($result.Output.Trim() -replace '\\', '/').TrimEnd('/') |
                Should -Be (($expected -replace '\\', '/').TrimEnd('/'))
        }
    }

    Context "Git provider state" {

        It "Detecta rama nonata, estado limpio, cambios y HEAD detached" {
            if (-not $script:gitAvailable) {
                Set-ItResult -Skipped -Because "git is not installed"
                return
            }

            $repoPath = Join-Path $TestDrive "git-state"
            $null = New-Item -ItemType Directory -Path $repoPath -Force
            Push-Location $repoPath
            try {
                & git init -q 2>$null | Out-Null
                & git config user.email "ppf@example.test" 2>$null
                & git config user.name "PPF Tests" 2>$null
                $branchName = (& git symbolic-ref --short HEAD 2>$null).Trim()
                Clear-AllPPFCache

                $context = Invoke-Prompt
                $context.Git.IsRepository | Should -BeTrue
                $context.Git.Branch | Should -Be $branchName
                $context.Git.Dirty | Should -BeFalse

                "initial" | Out-File -FilePath "tracked.txt"
                & git add "tracked.txt" 2>$null
                & git commit -qm "initial" 2>$null
                Clear-AllPPFCache

                $context = Invoke-Prompt
                $context.Git.Branch | Should -Be $branchName
                $context.Git.Dirty | Should -BeFalse

                Add-Content -Path "tracked.txt" -Value "changed"
                Clear-AllPPFCache

                $context = Invoke-Prompt
                $context.Git.Dirty | Should -BeTrue

                & git checkout -q --detach HEAD 2>$null
                Clear-AllPPFCache

                $context = Invoke-Prompt
                $context.Git.Detached | Should -BeTrue
                $context.Git.Branch | Should -Match '^[0-9a-f]{7,}$'
            }
            finally {
                Pop-Location
            }
        }
    }

    Context "Theme isolation" {

        It "Restaura los segmentos ocultos por Kali al volver a Default" {
            Set-PromptTheme -Name "Kali"
            (Get-SegmentConfiguration -Name "Memory").Visible | Should -BeFalse
            (Get-SegmentConfiguration -Name "Docker").Visible | Should -BeFalse

            Set-PromptTheme -Name "Default"
            (Get-SegmentConfiguration -Name "Memory").Visible | Should -BeTrue
            (Get-SegmentConfiguration -Name "Docker").Visible | Should -BeTrue
            (Get-SegmentConfiguration -Name "Project").Visible | Should -BeTrue
        }
    }

    Context "Theme icon resolution" {

        It "Devuelve null para claves no definidas y conserva glifos literales" {
            Set-PromptTheme -Name "Default"

            Resolve-ThemeIcon -IconKey "DefinitelyNotAKey" | Should -BeNullOrEmpty

            $segment = New-PromptSegment -Name "CPU" -Text "10%" -Icon "X"
            $segment.Icon | Should -Be "X"
        }

        It "Resuelve claves definidas por el tema activo" {
            Set-PromptTheme -Name "Default"
            $icon = Resolve-ThemeIcon -IconKey "GitDirty"
            $icon | Should -Be (Get-PromptTheme -Name "Default").Icons["GitDirty"]
        }
    }

    Context "Benchmark metrics" {

        It "No mezcla métricas de caché con los tiempos de providers" {
            $report = Measure-PromptDetailed -Iterations 1 -ExportDir (Join-Path $TestDrive "benchmarks") 6>$null
            $report | Should -Not -BeNullOrEmpty
            @($report.ProviderStats.Keys | Where-Object { $_ -match '_(CacheHit|CacheMiss|TTLExpired|Refresh|ReadTimeMs|UpdateTimeMs)$' }).Count | Should -Be 0
            $report.ProviderStats.Contains("CPU") | Should -BeTrue
        }
    }

    Context "Bootstrap events" {

        It "Registra los módulos cargados también con el bootstrap rápido" {
            $manifestPath = (Resolve-Path (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1")).Path
            $childScript = @"
Remove-Item Env:\PPF_USE_MODULAR_LOADER -ErrorAction SilentlyContinue
Import-Module '$manifestPath' -Force
if (`$global:PPF_BootstrapMode -ne 'Fast') { throw "Expected Fast bootstrap, got '`$(`$global:PPF_BootstrapMode)'" }
if (`$global:PPF_LoadedModules.Count -ne 14) { throw "Expected 14 loaded modules, got `$(`$global:PPF_LoadedModules.Count)" }
'MODULES_OK'
"@
            $output = & pwsh -NoProfile -NoLogo -Command $childScript 2>&1
            $output | Should -Contain "MODULES_OK"
        }
    }
}
