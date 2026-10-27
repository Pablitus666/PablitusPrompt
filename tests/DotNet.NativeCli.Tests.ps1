# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.NativeCli.Tests.ps1
# Fase 3E: pruebas del ejecutable nativo ppf (.NET)
# ============================================================

$env:PPF_USE_MODULAR_LOADER = "1"

Describe "Pablitus Prompt Framework - ejecutable nativo ppf (.NET)" {

    BeforeAll {
        # Ruta raíz del repositorio: caminamos hacia arriba desde este archivo
        # hasta encontrar build.ps1 (evita depender de $PSScriptRoot, que en
        # Pester 6 puede ser un array).
        $commandPath = $PSCommandPath
        if ($commandPath -is [array]) { $commandPath = $commandPath[0] }
        $scriptDir = Split-Path -Parent $commandPath
        $script:repoRoot = $null
        $cursor = $scriptDir
        while ($cursor) {
            if (Test-Path (Join-Path $cursor "build.ps1") -PathType Leaf) {
                $script:repoRoot = $cursor
                break
            }
            $parent = Split-Path -Parent $cursor
            if (-not $parent -or $parent -eq $cursor) { break }
            $cursor = $parent
        }
        if (-not $script:repoRoot) {
            $script:repoRoot = (Get-Item "$scriptDir\..").FullName
        }
        # Garantizar escalar: Pester 6 puede entregar arrays en estas variables.
        if ($script:repoRoot -is [array]) { $script:repoRoot = $script:repoRoot[0] }

        # Candidatos donde build.ps1 / CI dejan el ejecutable nativo ppf.
        $script:candidateExePaths = @(
            [System.IO.Path]::Combine($script:repoRoot, "build/dotnet-publish/ppf.exe"),
            [System.IO.Path]::Combine($script:repoRoot, "build/dotnet-publish/ppf"),
            [System.IO.Path]::Combine($script:repoRoot, "artifacts/ppf.exe"),
            [System.IO.Path]::Combine($script:repoRoot, "artifacts/ppf"),
            [System.IO.Path]::Combine($script:repoRoot, "build/PablitusPrompt/tools/ppf.exe"),
            [System.IO.Path]::Combine($script:repoRoot, "build/PablitusPrompt/tools/ppf")
        )

        # Si el ejecutable no existe, intentar localizar el proyecto y publicar
        # sobre la marcha para que las pruebas puedan ejecutse de forma local.
        $script:exePath = ($script:candidateExePaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)
        if (-not $script:exePath) {
            $dotnetExe = Get-Command dotnet -ErrorAction SilentlyContinue
            $cliProj = Join-Path $script:repoRoot "dotnet/src/PablitusPrompt.Cli/PablitusPrompt.Cli.csproj"
            $publishOut = Join-Path $script:repoRoot "dotnet/publish-native"
            if ($dotnetExe -and (Test-Path -LiteralPath $cliProj)) {
                $null = New-Item -ItemType Directory -Path $publishOut -Force
                & $dotnetExe publish $cliProj -c Release -o $publishOut --self-contained $false --nologo | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $script:exePath = if ($IsWindows) {
                        Join-Path $publishOut "ppf.exe"
                    } else {
                        Join-Path $publishOut "ppf"
                    }
                }
            }
        }

        # Tema de ejemplo determinista (sin segmento de tiempo) para paridad.
        $script:ppfConfig = Join-Path $script:repoRoot "examples/dotnet/config.ppf.json"
    }

    AfterAll {
        # Nada que limpiar.
    }

    BeforeEach {
        if (-not $script:exePath) {
            Set-ItResult -Skipped -Because "El ejecutable nativo ppf no se encontró ni se pudo publicar."
            return
        }
    }

    It "Existe el ejecutable nativo ppf después del build" {
        $script:exePath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $script:exePath -PathType Leaf | Should -Be $true
    }

    It "ppf --version imprime la versión sin depender de pwsh" {
        $output = & $script:exePath --version 2>&1
        $LASTEXITCODE | Should -Be 0
        $output | Should -Not -BeNullOrEmpty
        $output | Should -Match "^ppf \d"
    }

    It "ppf render imprime una salida no vacía a stdout" {
        $output = & $script:exePath render --config $script:ppfConfig --no-color 2>&1
        $LASTEXITCODE | Should -Be 0
        $output | Should -Not -BeNullOrEmpty
        $output | Should -Not -Be ""
    }

    It "La salida es determinista (mismo input = mismo output)" {
        # Usar un config determinista (sin segmento de tiempo) generado en $TestDrive.
        $deterministicConfig = Join-Path $TestDrive "deterministic.ppf.json"
        @{
            version    = "1.0"
            renderer   = "plain"
            finalSpace = $false
            theme      = @{
                name     = "Deterministic"
                version  = "1.0"
                renderer = "plain"
                palette  = @{ text = "#ffffff" }
                blocks   = @(
                    @{
                        type      = "prompt"
                        alignment = "left"
                        newline   = $false
                        segments  = @(
                            @{
                                type       = "text"
                                name       = "user"
                                style      = "plain"
                                template   = "{{ .UserName }}@{{ .HostName }}"
                                foreground = "text"
                            }
                        )
                    }
                )
            }
        } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $deterministicConfig -Encoding utf8

        $run1 = & $script:exePath render --config $deterministicConfig --no-color 2>&1
        $run2 = & $script:exePath render --config $deterministicConfig --no-color 2>&1

        $LASTEXITCODE | Should -Be 0
        $run1 | Should -Not -BeNullOrEmpty
        $run2 | Should -Not -BeNullOrEmpty
        $run1 | Should -Be $run2
    }

    It "ppf render acepta --transient y --no-cache sin fallar" {
        $output = & $script:exePath render --config $script:ppfConfig --no-color --no-cache --transient 2>&1
        $LASTEXITCODE | Should -Be 0
        # --transient imprime el prompt transitorio (puede estar vacío si el tema no lo define).
    }
}
