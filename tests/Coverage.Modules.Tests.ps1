# ============================================================
# Pablitus Prompt Framework (PPF)
# Coverage.Modules.Tests.ps1
# ============================================================

# Pester instruments script files, not the in-memory fast bundle.
$env:PPF_USE_MODULAR_LOADER = "1"

# Import at discovery time: InModuleScope requires the module to be loaded
# before Pester resolves the test tree.
Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "PPF Coverage - Git, ConfigManager, Providers & Command Utils" {

    BeforeAll {
        $global:PPF_InsidePester = $true
    }

    InModuleScope PablitusPrompt {

        # ------------------------------------------------------------
        # Git.Service
        # ------------------------------------------------------------

        Context "Git.Service - Estado del repositorio y resolucion de .git" {

            BeforeAll {
                $script:CovGitRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PPF_Cov_Git_" + [guid]::NewGuid().ToString("N"))
                $null = New-Item -ItemType Directory -Path $script:CovGitRoot -Force
            }

            AfterAll {
                Stop-AllGitWatchers
                if (Test-Path -LiteralPath $script:CovGitRoot) {
                    Remove-Item -LiteralPath $script:CovGitRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It "Devuelve un estado vacio cuando el directorio no es un repositorio" {
                Mock Test-GitRepository { $false } -ModuleName PablitusPrompt

                $result = Get-GitStatusAndBranch

                $result.IsRepository | Should -BeFalse
                $result.Branch | Should -BeNullOrEmpty
                $result.Dirty | Should -BeFalse
                $result.Ahead | Should -Be 0
                $result.Behind | Should -Be 0
                $result.Detached | Should -BeFalse
                $result.Root | Should -BeNullOrEmpty
            }

            It "Resuelve rama, ahead/behind y estado sucio sin root" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Get-GitDir { $null } -ModuleName PablitusPrompt
                Mock Invoke-Git { @("## main...origin/main [ahead 2, behind 3]", " M src/File.ps1") } -ModuleName PablitusPrompt

                $result = Get-GitStatusAndBranch

                $result.IsRepository | Should -BeTrue
                $result.Branch | Should -Be "main"
                $result.Ahead | Should -Be 2
                $result.Behind | Should -Be 3
                $result.Dirty | Should -BeTrue
                $result.Detached | Should -BeFalse
                $result.Root | Should -BeNullOrEmpty
            }

            It "Resuelve el SHA corto cuando el HEAD esta detached" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Get-GitDir { "C:\fake\.git" } -ModuleName PablitusPrompt
                Mock Invoke-Git {
                    if ($Arguments[0] -eq "rev-parse") { return @("deadbee") }
                    return @("## HEAD (no branch)")
                } -ModuleName PablitusPrompt

                $result = Get-GitStatusAndBranch

                $result.Detached | Should -BeTrue
                $result.Branch | Should -Be "deadbee"
            }

            It "Usa HEAD (no branch) cuando rev-parse no devuelve SHA" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Invoke-Git {
                    if ($Arguments[0] -eq "rev-parse") { return $null }
                    return @("## HEAD (no branch)")
                } -ModuleName PablitusPrompt

                $result = Get-GitStatusAndBranch

                $result.Detached | Should -BeTrue
                $result.Branch | Should -Be "HEAD (no branch)"
            }

            It "Devuelve null en rama y commit fuera de un repositorio" {
                Mock Test-GitRepository { $false } -ModuleName PablitusPrompt

                Get-GitBranch | Should -BeNullOrEmpty
                Get-GitCommit | Should -BeNullOrEmpty
                Get-GitCommitShort | Should -BeNullOrEmpty
            }

            It "Consulta rama y commit cuando existe repositorio" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Invoke-Git { @("feature/coverage") } -ModuleName PablitusPrompt

                Get-GitBranch | Should -Be "feature/coverage"
                Get-GitCommit | Should -Be "feature/coverage"
                Get-GitCommitShort | Should -Be "feature/coverage"
            }

            It "Devuelve estado vacio fuera de un repositorio" {
                Mock Test-GitRepository { $false } -ModuleName PablitusPrompt

                $status = Get-GitStatus

                $status.Dirty | Should -BeFalse
                $status.Modified | Should -BeFalse
                $status.Staged | Should -BeFalse
                $status.Untracked | Should -BeFalse
            }

            It "Detecta archivos modificados, staged y no rastreados" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Invoke-Git { @(" M src/File.ps1", "M  src/Other.ps1", "?? notes.txt") } -ModuleName PablitusPrompt

                $status = Get-GitStatus

                $status.Dirty | Should -BeTrue
                $status.Modified | Should -BeTrue
                $status.Staged | Should -BeTrue
                $status.Untracked | Should -BeTrue
            }

            It "Reporta repositorio limpio cuando status no devuelve lineas" {
                Mock Test-GitRepository { $true } -ModuleName PablitusPrompt
                Mock Invoke-Git { @() } -ModuleName PablitusPrompt

                (Get-GitStatus).Dirty | Should -BeFalse
            }

            It "Encuentra el directorio .git subiendo por el arbol de directorios" {
                $repoDir = Join-Path $script:CovGitRoot "repo"
                $gitDir = Join-Path $repoDir ".git"
                $deepDir = Join-Path (Join-Path $repoDir "sub") "deep"
                $null = New-Item -ItemType Directory -Path $gitDir -Force
                $null = New-Item -ItemType Directory -Path $deepDir -Force

                Push-Location -LiteralPath $deepDir
                try {
                    $resolved = Get-GitDir
                    $cached = Get-GitDir
                }
                finally {
                    Pop-Location
                }

                $resolved | Should -Be $gitDir
                $cached | Should -Be $gitDir
            }

            It "Resuelve un worktree con gitdir relativo" {
                $repoDir = Join-Path $script:CovGitRoot "repo"
                $worktree = Join-Path $script:CovGitRoot "worktree-relative"
                $null = New-Item -ItemType Directory -Path $repoDir -Force
                $null = New-Item -ItemType Directory -Path $worktree -Force
                Set-Content -LiteralPath (Join-Path $worktree ".git") -Value "gitdir: ../repo/.git"

                Push-Location -LiteralPath $worktree
                try {
                    $resolved = Get-GitDir
                }
                finally {
                    Pop-Location
                }

                $resolved | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $repoDir ".git")))
            }

            It "Resuelve un worktree con gitdir absoluto" {
                $target = Join-Path $script:CovGitRoot "absolute-gitdir"
                $worktree = Join-Path $script:CovGitRoot "worktree-absolute"
                $null = New-Item -ItemType Directory -Path $target -Force
                $null = New-Item -ItemType Directory -Path $worktree -Force
                Set-Content -LiteralPath (Join-Path $worktree ".git") -Value "gitdir: $target"

                Push-Location -LiteralPath $worktree
                try {
                    $resolved = Get-GitDir
                }
                finally {
                    Pop-Location
                }

                $resolved | Should -Be $target
            }

            It "Devuelve null y cachea NONE cuando no hay repositorio" {
                $plainDir = Join-Path $script:CovGitRoot "plain-dir"
                $null = New-Item -ItemType Directory -Path $plainDir -Force
                Set-Content -LiteralPath (Join-Path $plainDir ".git") -Value "no es un gitdir valido"

                Push-Location -LiteralPath $plainDir
                try {
                    $first = Get-GitDir
                    $second = Get-GitDir
                }
                finally {
                    Pop-Location
                }

                $first | Should -BeNullOrEmpty
                $second | Should -BeNullOrEmpty
            }

            It "Devuelve null en la firma de estado cuando no hay repositorio" {
                Mock Get-GitDir { $null } -ModuleName PablitusPrompt

                Get-GitStateSignature | Should -BeNullOrEmpty
            }

            It "Construye la firma con los tiempos de HEAD e index" {
                $fakeGit = Join-Path $script:CovGitRoot "signature-git"
                $null = New-Item -ItemType Directory -Path $fakeGit -Force
                Set-Content -LiteralPath (Join-Path $fakeGit "HEAD") -Value "ref: refs/heads/main"
                Set-Content -LiteralPath (Join-Path $fakeGit "index") -Value "binary-index"
                Mock Get-GitDir { $fakeGit } -ModuleName PablitusPrompt

                $signature = Get-GitStateSignature
                $signature | Should -Match '^Dir:.+\|Head:\d+\|Index:\d+$'

                Remove-Item -LiteralPath (Join-Path $fakeGit "index") -Force
                $withoutIndex = Get-GitStateSignature
                $withoutIndex | Should -Match '\|Index:0$'

                Remove-Item -LiteralPath (Join-Path $fakeGit "HEAD") -Force
                $withoutHead = Get-GitStateSignature
                $withoutHead | Should -Match '\|Head:0\|Index:0$'
            }

            It "Registra y detiene el watcher de un repositorio" {
                $watchDir = Join-Path $script:CovGitRoot "watched-repo"
                $null = New-Item -ItemType Directory -Path $watchDir -Force
                $global:PPF_GitWatchers.Clear()
                $global:PPF_GitWatcherDirty.Clear()

                Start-GitWatcher -RepoRoot $watchDir
                Start-GitWatcher -RepoRoot $watchDir

                $global:PPF_GitWatchers.Contains($watchDir) | Should -BeTrue
                @($global:PPF_GitWatchers[$watchDir].Handlers).Count | Should -Be 4

                Stop-AllGitWatchers

                $global:PPF_GitWatchers.Count | Should -Be 0
                $global:PPF_GitWatcherDirty.Count | Should -Be 0
            }

            It "Ignora rutas inexistentes al crear el watcher" {
                $missing = Join-Path $script:CovGitRoot "missing-repo"

                Start-GitWatcher -RepoRoot $missing

                $global:PPF_GitWatchers.Contains($missing) | Should -BeFalse
            }

            It "Ignora entradas incompletas al detener los watchers" {
                $global:PPF_GitWatchers["incomplete-entry"] = @{ Watcher = $null; Handlers = @() }

                { Stop-AllGitWatchers } | Should -Not -Throw

                $global:PPF_GitWatchers.Count | Should -Be 0
            }
        }

        # ------------------------------------------------------------
        # ConfigManager
        # ------------------------------------------------------------

        Context "ConfigManager - Importacion, exportacion y hot reload" {

            BeforeAll {
                $script:CovCfgRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PPF_Cov_Cfg_" + [guid]::NewGuid().ToString("N"))
                $null = New-Item -ItemType Directory -Path $script:CovCfgRoot -Force

                # Se trabaja sobre una configuracion sandbox para no alterar la real
                $script:CovCfgOriginalConfig = Get-PromptConfiguration
                $script:CovCfgOriginalTheme = $script:ActiveThemeName

                $sandbox = [PromptConfiguration]::new()
                $sandbox.Segments["Git"] = @{ Visible = $true; Icon = "G"; Foreground = "Yellow"; CacheTimeoutMs = 5000 }
                $sandbox.Segments["Node"] = @{ Visible = $true; Icon = "N"; Foreground = "Green" }
                $sandbox.Renderer["Default"] = "Plain"
                $sandbox.Theme["Name"] = "Default"
                $sandbox.Performance = @{ CpuSampleInterval = 2; History = @(1, 2, 3); Flags = @($true, $false, $null) }
                Set-PromptConfiguration -Configuration $sandbox
            }

            AfterAll {
                Disable-PromptConfigHotReload
                Set-PromptTheme -Name $script:CovCfgOriginalTheme
                Set-PromptConfiguration -Configuration $script:CovCfgOriginalConfig
                if (Test-Path -LiteralPath $script:CovCfgRoot) {
                    Remove-Item -LiteralPath $script:CovCfgRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It "Get-PPFConfigValue devuelve null sin tabla y resuelve claves sin distinguir mayusculas" {
                Get-PPFConfigValue -Table $null -Name "Renderer" | Should -BeNullOrEmpty
                Get-PPFConfigValue -Table @{ Renderer = "Plain" } -Name "renderer" | Should -Be "Plain"
            }

            It "Importa JSON con Theme y Renderer en formato cadena" {
                $path = Join-Path $script:CovCfgRoot "import-strings.json"
                $json = @'
{
    "Theme": "Default",
    "Renderer": "Minimal",
    "Segments": {
        "Git": { "Visible": false, "Foreground": "Cyan" },
        "Node": true
    },
    "Performance": {
        "CpuSampleInterval": 4,
        "History": [ 1, 2, 3 ],
        "Flags": [ true, false, null ]
    }
}
'@
                Set-Content -LiteralPath $path -Value $json

                Import-PromptConfiguration -Path $path

                $config = Get-PromptConfiguration
                $config.Renderer["Default"] | Should -Be "Minimal"
                (Get-SegmentConfiguration -Name "Git").Visible | Should -BeFalse
                (Get-SegmentConfiguration -Name "Git").Foreground | Should -Be "Cyan"
                (Get-SegmentConfiguration -Name "Node").Visible | Should -BeTrue
                $config.Performance["CpuSampleInterval"] | Should -Be 4
                @($config.Performance["History"]).Count | Should -Be 3
                @($config.Performance["Flags"]).Count | Should -Be 3
            }

            It "Importa PSD1 y aplica los segmentos" {
                $path = Join-Path $script:CovCfgRoot "import.psd1"
                $content = @'
@{
    Renderer = 'ANSI'
    Segments = @{
        Git = @{
            Visible    = $true
            Foreground = 'Magenta'
        }
    }
}
'@
                Set-Content -LiteralPath $path -Value $content

                Import-PromptConfiguration -Path $path

                $config = Get-PromptConfiguration
                $config.Renderer["Default"] | Should -Be "ANSI"
                (Get-SegmentConfiguration -Name "Git").Foreground | Should -Be "Magenta"
            }

            It "Avisa y no lanza cuando el JSON es invalido" {
                $path = Join-Path $script:CovCfgRoot "broken.json"
                Set-Content -LiteralPath $path -Value "{ esto no es json"
                $WarningPreference = 'SilentlyContinue'

                { Import-PromptConfiguration -Path $path } | Should -Not -Throw
            }

            It "Devuelve sin cambios cuando el archivo de configuracion no existe" {
                $path = Join-Path $script:CovCfgRoot "missing.json"

                { Import-PromptConfiguration -Path $path } | Should -Not -Throw
            }

            It "Usa una configuracion por defecto cuando el segmento importado no existe" {
                Mock Get-SegmentConfiguration { $null } -ModuleName PablitusPrompt
                Mock Set-SegmentConfiguration { } -ModuleName PablitusPrompt

                $path = Join-Path $script:CovCfgRoot "import-new-segment.json"
                Set-Content -LiteralPath $path -Value '{ "Segments": { "Custom": { "Visible": true } } }'

                Import-PromptConfiguration -Path $path

                Should -Invoke Set-SegmentConfiguration -ModuleName PablitusPrompt -Times 1 -Exactly -ParameterFilter { $Name -eq "Custom" }
            }

            It "Exporta la configuracion actual a JSON" {
                $path = Join-Path $script:CovCfgRoot "export.json"

                Export-PromptConfiguration -Path $path

                Test-Path -LiteralPath $path | Should -BeTrue
                $content = Get-Content -LiteralPath $path -Raw
                $content | Should -Match '"Renderer"'
                $content | Should -Match '"History"'
                $content | Should -Match '"Flags"'
            }

            It "Exporta a PSD1 arrays, buleanos y null y los reimporta" {
                $path = Join-Path $script:CovCfgRoot "export.psd1"
                $config = Get-PromptConfiguration
                $previousRenderer = $config.Renderer["Default"]
                $previousInterval = $config.Performance["CpuSampleInterval"]

                Export-PromptConfiguration -Path $path

                $content = Get-Content -LiteralPath $path -Raw
                $content | Should -Match '\$null'
                $content | Should -Match '\$false'
                $content | Should -Match '@\(1, 2, 3\)'

                $config.Renderer["Default"] = "ANSI"
                $config.Performance["CpuSampleInterval"] = 99

                Import-PromptConfiguration -Path $path

                $config = Get-PromptConfiguration
                $config.Renderer["Default"] | Should -Be $previousRenderer
                $config.Performance["CpuSampleInterval"] | Should -Be $previousInterval
                @($config.Performance["Flags"]).Count | Should -Be 3
            }

            It "Exporta a PSD1 cuando un diccionario contiene un valor null" {
                $path = Join-Path $script:CovCfgRoot "export-null.psd1"
                $config = Get-PromptConfiguration
                $config.Performance["CovNullValue"] = $null

                try {
                    { Export-PromptConfiguration -Path $path } | Should -Not -Throw
                    $content = Get-Content -LiteralPath $path -Raw
                    $content | Should -Match 'CovNullValue = \$null'
                }
                finally {
                    $null = $config.Performance.Remove("CovNullValue")
                }
            }

            It "Avisa y no lanza cuando el tema importado no se puede aplicar" {
                Mock Set-PromptTheme { throw "tema no registrado" } -ModuleName PablitusPrompt

                $path = Join-Path $script:CovCfgRoot "import-bad-theme.json"
                Set-Content -LiteralPath $path -Value '{ "Theme": "NoExiste" }'
                $WarningPreference = 'SilentlyContinue'

                { Import-PromptConfiguration -Path $path } | Should -Not -Throw
                (Get-PromptConfiguration).Theme["Name"] = "Default"
            }

            It "No recarga cuando el hot reload esta deshabilitado" {
                Disable-PromptConfigHotReload

                { Test-PromptConfigReload } | Should -Not -Throw
            }

            It "Recarga la configuracion cuando el archivo cambia" {
                $path = Join-Path $script:CovCfgRoot "hot-reload.json"
                Set-Content -LiteralPath $path -Value '{ "Renderer": "Plain" }'

                Enable-PromptConfigHotReload -Path $path
                $script:ConfigFileLastWriteTime = [datetime]::MinValue

                Test-PromptConfigReload

                $script:ConfigFileLastWriteTime | Should -Be (Get-Item -LiteralPath $path).LastWriteTime
            }

            It "Avisa y no lanza cuando la recarga falla" {
                $path = Join-Path $script:CovCfgRoot "hot-reload-error.json"
                Set-Content -LiteralPath $path -Value '{ "Renderer": "Plain" }'
                Enable-PromptConfigHotReload -Path $path
                $script:ConfigFileLastWriteTime = [datetime]::MinValue

                Mock Import-PromptConfiguration { throw "fallo simulado" } -ModuleName PablitusPrompt
                $WarningPreference = 'SilentlyContinue'

                { Test-PromptConfigReload } | Should -Not -Throw
            }
        }

        # ------------------------------------------------------------
        # Kubernetes.Service
        # ------------------------------------------------------------

        Context "Kubernetes.Service - Lectura de kubeconfig" {

            BeforeAll {
                $script:CovKubeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PPF_Cov_Kube_" + [guid]::NewGuid().ToString("N"))
                $null = New-Item -ItemType Directory -Path $script:CovKubeRoot -Force
            }

            AfterAll {
                if (Test-Path -LiteralPath $script:CovKubeRoot) {
                    Remove-Item -LiteralPath $script:CovKubeRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It "Devuelve null cuando no existe kubeconfig" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-without-config"
                $null = New-Item -ItemType Directory -Path $fakeHome -Force
                $previous = $env:USERPROFILE

                try {
                    $env:USERPROFILE = $fakeHome
                    Get-KubeContext | Should -BeNullOrEmpty
                }
                finally {
                    $env:USERPROFILE = $previous
                }
            }

            It "Devuelve null cuando el kubeconfig esta vacio" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-empty-config"
                $null = New-Item -ItemType Directory -Path (Join-Path $fakeHome ".kube") -Force
                Set-Content -LiteralPath (Join-Path $fakeHome ".kube\config") -Value ""
                $previous = $env:USERPROFILE

                try {
                    $env:USERPROFILE = $fakeHome
                    Get-KubeContext | Should -BeNullOrEmpty
                }
                finally {
                    $env:USERPROFILE = $previous
                }
            }

            It "Lee el contexto actual y su namespace" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-with-namespace"
                $null = New-Item -ItemType Directory -Path (Join-Path $fakeHome ".kube") -Force
                $kubeConfig = @'
apiVersion: v1
current-context: my-context
contexts:
- name: my-context
  context:
    namespace: kube-system
'@
                Set-Content -LiteralPath (Join-Path $fakeHome ".kube\config") -Value $kubeConfig
                $previous = $env:USERPROFILE

                try {
                    $env:USERPROFILE = $fakeHome
                    $result = Get-KubeContext
                }
                finally {
                    $env:USERPROFILE = $previous
                }

                $result.Context | Should -Be "my-context"
                $result.Namespace | Should -Be "kube-system"
            }

            It "Usa el namespace default cuando el contexto no lo define" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-default-namespace"
                $null = New-Item -ItemType Directory -Path (Join-Path $fakeHome ".kube") -Force
                $kubeConfig = @'
apiVersion: v1
current-context: other-context
contexts:
- name: another-context
  context:
    namespace: not-used
'@
                Set-Content -LiteralPath (Join-Path $fakeHome ".kube\config") -Value $kubeConfig
                $previous = $env:USERPROFILE

                try {
                    $env:USERPROFILE = $fakeHome
                    $result = Get-KubeContext
                }
                finally {
                    $env:USERPROFILE = $previous
                }

                $result.Context | Should -Be "other-context"
                $result.Namespace | Should -Be "default"
            }

            It "Devuelve null cuando el kubeconfig no tiene current-context" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-without-context"
                $null = New-Item -ItemType Directory -Path (Join-Path $fakeHome ".kube") -Force
                Set-Content -LiteralPath (Join-Path $fakeHome ".kube\config") -Value "apiVersion: v1"
                $previous = $env:USERPROFILE

                try {
                    $env:USERPROFILE = $fakeHome
                    Get-KubeContext | Should -BeNullOrEmpty
                }
                finally {
                    $env:USERPROFILE = $previous
                }
            }

            It "Devuelve null cuando la lectura del kubeconfig falla" {
                $fakeHome = Join-Path $script:CovKubeRoot "home-read-error"
                $null = New-Item -ItemType Directory -Path (Join-Path $fakeHome ".kube") -Force
                Set-Content -LiteralPath (Join-Path $fakeHome ".kube\config") -Value "current-context: broken"
                $previous = $env:USERPROFILE
                Mock Get-Content { throw "acceso denegado" } -ModuleName PablitusPrompt

                try {
                    $env:USERPROFILE = $fakeHome
                    Get-KubeContext | Should -BeNullOrEmpty
                }
                finally {
                    $env:USERPROFILE = $previous
                }
            }
        }

        # ------------------------------------------------------------
        # Project.Service
        # ------------------------------------------------------------

        Context "Project.Service - Deteccion del tipo de proyecto" {

            BeforeAll {
                $script:CovProjectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PPF_Cov_Project_" + [guid]::NewGuid().ToString("N"))
                $null = New-Item -ItemType Directory -Path $script:CovProjectRoot -Force
            }

            AfterAll {
                if (Test-Path -LiteralPath $script:CovProjectRoot) {
                    Remove-Item -LiteralPath $script:CovProjectRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It "Detecta un proyecto Node por package.json" {
                $projectDir = Join-Path $script:CovProjectRoot "node-project"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "package.json") -Value "{}"

                Push-Location -LiteralPath $projectDir
                try {
                    $info = Get-ProjectInfo
                }
                finally {
                    Pop-Location
                }

                $info.Type | Should -Be "Node"
                $info.Root | Should -Be $projectDir
                $info.Name | Should -Be "node-project"
            }

            It "Detecta un proyecto Python desde un subdirectorio" {
                $projectDir = Join-Path $script:CovProjectRoot "python-project"
                $subDir = Join-Path $projectDir "src"
                $null = New-Item -ItemType Directory -Path $subDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "requirements.txt") -Value "pytest"

                Push-Location -LiteralPath $subDir
                try {
                    $info = Get-ProjectInfo
                }
                finally {
                    Pop-Location
                }

                $info.Type | Should -Be "Python"
                $info.Root | Should -Be $projectDir
            }

            It "Detecta un proyecto .NET por el archivo .sln" {
                $projectDir = Join-Path $script:CovProjectRoot "dotnet-project"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "app.sln") -Value "Microsoft Visual Studio Solution File"

                Push-Location -LiteralPath $projectDir
                try {
                    $info = Get-ProjectInfo
                }
                finally {
                    Pop-Location
                }

                $info.Type | Should -Be ".NET"
                $info.Root | Should -Be $projectDir
            }

            It "Devuelve Folder cuando no encuentra marcadores de proyecto" {
                $plainDir = Join-Path $script:CovProjectRoot "plain-project"
                $null = New-Item -ItemType Directory -Path $plainDir -Force

                Push-Location -LiteralPath $plainDir
                try {
                    $info = Get-ProjectInfo
                }
                finally {
                    Pop-Location
                }

                $info.Type | Should -Be "Folder"
                $info.Root | Should -Be $plainDir
            }
        }

        # ------------------------------------------------------------
        # Node / Python / DotNet Providers
        # ------------------------------------------------------------

        Context "Runtime Providers - Cache y deteccion por directorio" {

            BeforeAll {
                $script:CovRuntimeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("PPF_Cov_Runtime_" + [guid]::NewGuid().ToString("N"))
                $null = New-Item -ItemType Directory -Path $script:CovRuntimeRoot -Force
            }

            AfterAll {
                if (Test-Path -LiteralPath $script:CovRuntimeRoot) {
                    Remove-Item -LiteralPath $script:CovRuntimeRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It "Detecta Node por .node-version y reutiliza la cache" {
                $projectDir = Join-Path $script:CovRuntimeRoot "node-version-file"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir ".node-version") -Value "20.1.0"
                Mock Get-CommandPath { "C:\fake\node.exe" } -ModuleName PablitusPrompt
                Mock Get-NodeVersion { "20.1.0" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                $context.Project.Type = "Folder"
                Invoke-NodeProvider -Context $context

                $secondContext = [PromptContext]::new()
                $secondContext.Path.Current = $projectDir
                Invoke-NodeProvider -Context $secondContext

                $context.Runtime.Node | Should -Be "20.1.0"
                $secondContext.Runtime.Node | Should -Be "20.1.0"
                Should -Invoke Get-NodeVersion -ModuleName PablitusPrompt -Times 1 -Exactly

                Clear-PPFCache -Key "NodeVersion_$projectDir"
            }

            It "Detecta Node por .nvmrc" {
                $projectDir = Join-Path $script:CovRuntimeRoot "node-nvmrc"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir ".nvmrc") -Value "18.19.0"
                Mock Get-CommandPath { "C:\fake\node.exe" } -ModuleName PablitusPrompt
                Mock Get-NodeVersion { "18.19.0" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                Invoke-NodeProvider -Context $context

                $context.Runtime.Node | Should -Be "18.19.0"
                Clear-PPFCache -Key "NodeVersion_$projectDir"
            }

            It "Detecta Python por requirements.txt y reutiliza la cache" {
                $projectDir = Join-Path $script:CovRuntimeRoot "python-requirements"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "requirements.txt") -Value "requests"
                Mock Get-CommandPath { "C:\fake\python.exe" } -ModuleName PablitusPrompt
                Mock Get-PythonVersion { "3.12.1" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                Invoke-PythonProvider -Context $context

                $secondContext = [PromptContext]::new()
                $secondContext.Path.Current = $projectDir
                Invoke-PythonProvider -Context $secondContext

                $context.Runtime.Python | Should -Be "3.12.1"
                $secondContext.Runtime.Python | Should -Be "3.12.1"
                Should -Invoke Get-PythonVersion -ModuleName PablitusPrompt -Times 1 -Exactly

                Clear-PPFCache -Key "PythonVersion_$projectDir"
            }

            It "Detecta Python por .venv\\pyvenv.cfg" {
                $projectDir = Join-Path $script:CovRuntimeRoot "python-venv"
                $venvDir = Join-Path $projectDir ".venv"
                $null = New-Item -ItemType Directory -Path $venvDir -Force
                Set-Content -LiteralPath (Join-Path $venvDir "pyvenv.cfg") -Value "home = C:\Python312"
                Mock Get-CommandPath { "C:\fake\python.exe" } -ModuleName PablitusPrompt
                Mock Get-PythonVersion { "3.11.0" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                Invoke-PythonProvider -Context $context

                $context.Runtime.Python | Should -Be "3.11.0"
                Clear-PPFCache -Key "PythonVersion_$projectDir"
            }

            It "Detecta DotNet por global.json y reutiliza la cache" {
                $projectDir = Join-Path $script:CovRuntimeRoot "dotnet-global-json"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "global.json") -Value '{ "sdk": { "version": "8.0.100" } }'
                Mock Get-CommandPath { "C:\fake\dotnet.exe" } -ModuleName PablitusPrompt
                Mock Get-DotNetVersion { "8.0.100" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                Invoke-DotNetProvider -Context $context

                $secondContext = [PromptContext]::new()
                $secondContext.Path.Current = $projectDir
                Invoke-DotNetProvider -Context $secondContext

                $context.Runtime.DotNet | Should -Be "8.0.100"
                $secondContext.Runtime.DotNet | Should -Be "8.0.100"
                Should -Invoke Get-DotNetVersion -ModuleName PablitusPrompt -Times 1 -Exactly

                Clear-PPFCache -Key "DotNetVersion_$projectDir"
            }

            It "Detecta DotNet por archivos de proyecto" {
                $projectDir = Join-Path $script:CovRuntimeRoot "dotnet-csproj"
                $null = New-Item -ItemType Directory -Path $projectDir -Force
                Set-Content -LiteralPath (Join-Path $projectDir "app.csproj") -Value "<Project />"
                Mock Get-CommandPath { "C:\fake\dotnet.exe" } -ModuleName PablitusPrompt
                Mock Get-DotNetVersion { "7.0.400" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $projectDir
                Invoke-DotNetProvider -Context $context

                $context.Runtime.DotNet | Should -Be "7.0.400"
                Clear-PPFCache -Key "DotNetVersion_$projectDir"
            }

            It "No consulta la version cuando el directorio no es un proyecto" {
                $plainDir = Join-Path $script:CovRuntimeRoot "plain-runtime"
                $null = New-Item -ItemType Directory -Path $plainDir -Force
                Mock Get-CommandPath { "" } -ModuleName PablitusPrompt
                Mock Get-NodeVersion { "20.1.0" } -ModuleName PablitusPrompt
                Mock Get-PythonVersion { "3.12.1" } -ModuleName PablitusPrompt
                Mock Get-DotNetVersion { "8.0.100" } -ModuleName PablitusPrompt

                $context = [PromptContext]::new()
                $context.Path.Current = $plainDir
                $context.Project.Type = "Folder"

                Invoke-NodeProvider -Context $context
                Invoke-PythonProvider -Context $context
                Invoke-DotNetProvider -Context $context

                $context.Runtime.Node | Should -BeNullOrEmpty
                $context.Runtime.Python | Should -BeNullOrEmpty
                $context.Runtime.DotNet | Should -BeNullOrEmpty
                Should -Invoke Get-NodeVersion -ModuleName PablitusPrompt -Times 0 -Exactly
                Should -Invoke Get-PythonVersion -ModuleName PablitusPrompt -Times 0 -Exactly
                Should -Invoke Get-DotNetVersion -ModuleName PablitusPrompt -Times 0 -Exactly
            }
        }

        # ------------------------------------------------------------
        # Command.Utils
        # ------------------------------------------------------------

        Context "Command.Utils - Ejecucion segura de comandos externos" {

            # Se evalua en discovery porque -Skip se resuelve al construir el arbol
            $CovOnWindows = [System.OperatingSystem]::IsWindows()

            It "Invoke-CommandSafe devuelve null cuando el comando no existe" {
                Mock Test-CommandExists { $false } -ModuleName PablitusPrompt

                Invoke-CommandSafe -Command "ppf-missing-command" | Should -BeNullOrEmpty
            }

            It "Invoke-CommandSafe devuelve la salida del proceso" -Skip:(-not $CovOnWindows) {
                $output = Invoke-CommandSafe -Command "cmd" -Arguments @("/c", "echo hello")

                $output | Should -Be "hello"
            }

            It "Invoke-CommandSafe devuelve null cuando el proceso falla" -Skip:(-not $CovOnWindows) {
                Invoke-CommandSafe -Command "cmd" -Arguments @("/c", "exit 3") | Should -BeNullOrEmpty
            }

            It "Invoke-CommandSafe captura excepciones de ejecucion" {
                Mock Test-CommandExists { $true } -ModuleName PablitusPrompt

                Invoke-CommandSafe -Command "ppf-command-that-does-not-exist" | Should -BeNullOrEmpty
            }

            It "Get-CommandVersion delega en Invoke-CommandSafe" {
                Mock Invoke-CommandSafe { "1.2.3" } -ModuleName PablitusPrompt

                Get-CommandVersion -Command "any-command" | Should -Be "1.2.3"
            }

            It "Invoke-CommandWithTimeout devuelve null cuando el comando no existe" {
                Mock Test-CommandExists { $false } -ModuleName PablitusPrompt

                Invoke-CommandWithTimeout -Command "ppf-missing-command" | Should -BeNullOrEmpty
            }

            It "Invoke-CommandWithTimeout resuelve el ejecutable desde Source" {
                Mock Test-CommandExists { $true } -ModuleName PablitusPrompt
                Mock Get-Command {
                    [pscustomobject]@{
                        CommandType = 'ExternalScript'
                        Path        = $null
                        Source      = 'ppf-missing-script.ps1'
                    }
                } -ModuleName PablitusPrompt

                $result = Invoke-CommandWithTimeout -Command "ppf-script" -Arguments @("--version") -TimeoutMs 500

                $result | Should -Not -BeNullOrEmpty
                $result.ExitCode | Should -Be -1
                $result.TimedOut | Should -BeFalse
            }

            It "Invoke-CommandWithTimeout marca TimedOut cuando el proceso no termina" -Skip:(-not $CovOnWindows) {
                $result = Invoke-CommandWithTimeout -Command "ping" -Arguments @("-n", "20", "127.0.0.1") -TimeoutMs 200

                $result.TimedOut | Should -BeTrue
                $result.ExitCode | Should -Be -1
            }

            It "Get-CommandPath devuelve cadena vacia si el comando no existe" {
                Get-CommandPath -Command "ppf-missing-command" | Should -Be ""
            }

            It "Invoke-PPFExternalCommand marca Installed false cuando no existe el comando" {
                Mock Test-CommandExists { $false } -ModuleName PablitusPrompt

                $result = Invoke-PPFExternalCommand -Command "git"

                $result.Installed | Should -BeFalse
                $result.ExitCode | Should -Be -1
                $result.Error | Should -Be "CommandNotFoundException"
            }

            It "Invoke-PPFExternalCommand degrada cuando la ejecucion no devuelve resultado" {
                Mock Test-CommandExists { $true } -ModuleName PablitusPrompt
                Mock Invoke-CommandWithTimeout { $null } -ModuleName PablitusPrompt

                $result = Invoke-PPFExternalCommand -Command "git"

                $result.Installed | Should -BeTrue
                $result.ExitCode | Should -Be -1
                $result.Error | Should -Be "Execution failed"
            }
        }
    }
}

Describe "PPF Public Configuration API" {

    It "Exporta e importa la configuracion mediante comandos publicos" {
        $path = Join-Path $env:TEMP ("ppf-public-" + [guid]::NewGuid().ToString('N') + ".json")

        try {
            Export-PromptConfiguration -Path $path
            Test-Path -LiteralPath $path | Should -BeTrue

            { Import-PromptConfiguration -Path $path } | Should -Not -Throw
        }
        finally {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }

    It "Expone los comandos de configuracion en el manifiesto" {
        Get-Command Import-PromptConfiguration -Module PablitusPrompt | Should -Not -BeNullOrEmpty
        Get-Command Export-PromptConfiguration -Module PablitusPrompt | Should -Not -BeNullOrEmpty
    }
}
