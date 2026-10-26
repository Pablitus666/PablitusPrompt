# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Tests.ps1 (Regresion, Pipeline & Renderers)
# ============================================================

# Pester instruments script files, not the in-memory fast bundle.
$env:PPF_USE_MODULAR_LOADER = "1"

# Import at discovery time: InModuleScope requires the module to be loaded
# before Pester resolves the test tree.
Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "Pablitus Prompt Framework - Regression & Integration Tests" {

    BeforeAll {
        $bootstrapPath = Resolve-Path (Join-Path $PSScriptRoot "..\src\Bootstrap.ps1")
        . $bootstrapPath
        $global:PPF_InsidePester = $true
    }

    InModuleScope PablitusPrompt {
    Context "Kernel, Modules & Pipeline" {

        It "Carga Bootstrap.ps1 sin errores y define las funciones clave" {
            $keyFunctions = @(
                "Invoke-Prompt", "Get-PromptString", "New-PromptContext", 
                "Initialize-PPFModules", "Register-PPFPipelineStep", "Invoke-PPFPipeline",
                "Get-Prompt", "Get-PromptProviders", "Get-PromptSegments", 
                "Get-PromptRenderers", "Get-PromptThemes", "Get-ActiveTheme", 
                "Import-PromptTheme", "Set-PromptTheme", "Measure-Prompt", "Measure-PromptDetailed", 
                "Test-PromptFramework"
            )
            foreach ($func in $keyFunctions) {
                (Get-Command $func -ErrorAction SilentlyContinue) | Should -Not -Be $null
            }
        }

        It "Registra los proveedores modularizados" {
            $expectedProviders = @("Session", "Project", "Path", "Git", "Python", "Node", "Docker", "WSL", "Battery", "CPU", "Memory", "Kubernetes", "DotNet")

            foreach ($providerName in $expectedProviders) {
                $provider = $script:PromptProviders | Where-Object Name -eq $providerName
                $provider | Should -Not -Be $null
            }
        }

        It "Registra los segmentos modularizados" {
            $expectedSegments = @("Session", "Project", "Path", "Git", "Python", "Node", "Docker", "WSL", "Battery", "CPU", "Memory", "Kubernetes", "DotNet", "Time")

            foreach ($segmentName in $expectedSegments) {
                $segment = $script:PromptSegments | Where-Object Name -eq $segmentName
                $segment | Should -Not -Be $null
            }
        }

        It "Omite providers ocultos pero conserva las dependencias de providers visibles" {
            $oldTheme = Get-ActiveTheme
            $oldSkip = $global:PPF_SkipHiddenProviders
            $kaliTheme = Get-PromptTheme -Name Kali
            $oldSegmentConfigs = @{}
            foreach ($segmentName in $kaliTheme.Segments.Keys) {
                $oldSegmentConfigs[$segmentName] = Get-SegmentConfiguration -Name $segmentName
            }

            try {
                Set-PromptTheme -Name Kali
                $global:PPF_SkipHiddenProviders = $true
                $context = Invoke-Prompt

                $context.Metrics.ContainsKey("Provider_Memory_TimeMs") | Should -Be $false
                $context.Metrics.ContainsKey("Provider_Battery_TimeMs") | Should -Be $false
                $context.Metrics.ContainsKey("Provider_Git_TimeMs") | Should -Be $true
                $context.Metrics.ContainsKey("Provider_Project_TimeMs") | Should -Be $true
            }
            finally {
                if ($oldTheme) {
                    Set-PromptTheme -Name $oldTheme.Name
                }
                foreach ($segmentName in $oldSegmentConfigs.Keys) {
                    Set-SegmentConfiguration -Name $segmentName -Configuration $oldSegmentConfigs[$segmentName]
                }
                $global:PPF_SkipHiddenProviders = $oldSkip
            }
        }

        It "Ejecuta el paso de Profiling en el Pipeline y añade métricas" {
            $context = Invoke-Prompt
            $context.Metrics.ContainsKey("ExecutionTimeMs") | Should -Be $true
            $context.Metrics["ExecutionTimeMs"] | Should -BeGreaterThan -1
        }

        It "Permite llamar a Get-PromptSegments de forma aislada sin pasar Context" {
            $segments = Get-PromptSegments
            $segments | Should -Not -Be $null
            $segments.Count | Should -BeGreaterThan 0
        }

        It "Permite obtener proveedores con Get-PromptProviders" {
            $providers = Get-PromptProviders
            $providers | Should -Not -Be $null
            $providers.Count | Should -BeGreaterThan 0
        }

    }

    Context "Rendering Engine & Renderers (Fase 2)" {

        $renderers = @("Plain", "Minimal", "JSON", "ANSI", "PowerLine", "Markdown", "HTML", "Rich")

        It "Tiene registrados todos los renderers previstos" {
            foreach ($rName in $renderers) {
                $renderer = Get-PromptRenderer -Name $rName
                $renderer | Should -Not -Be $null
            }
        }

        It "El renderer Plain genera una salida correcta" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Plain"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Not -Match "`e\[" # No debe tener códigos ANSI
        }

        It "El renderer Minimal genera una salida simplificada" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Minimal"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "[>#]$" # Debe terminar con char de prompt
        }

        It "El renderer JSON genera un JSON válido" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "JSON"
            $prompt | Should -Not -BeNullOrEmpty
            $parsed = $prompt | ConvertFrom-Json -ErrorAction SilentlyContinue
            $parsed | Should -Not -Be $null
            $parsed.Session.User | Should -Be $env:USERNAME
        }

        It "El renderer ANSI contiene secuencias de escape ANSI" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "ANSI"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "`e\[\d+m"
        }

        It "El renderer PowerLine contiene el glifo separador triangular de PowerLine" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "PowerLine"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match ""
        }

        It "El renderer Markdown genera una salida con formato markdown bold (**)" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Markdown"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "\*\*"
        }

        It "El renderer HTML contiene etiquetas HTML span" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "HTML"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "<span style="
        }

        It "El renderer Rich contiene secuencias de escape ANSI y corchetes" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Rich"
            $prompt | Should -Not -BeNullOrEmpty
            $prompt | Should -Match "\["
            $prompt | Should -Match "➔"
        }

    }

    Context "Theme Manager (Fase 3)" {

        It "Tiene registrados temas por defecto (Default, Nord, Dracula, Catppuccin, Kali)" {
            $themes = Get-PromptTheme
            $themes | Should -Not -Be $null
            $themes.Count | Should -BeGreaterThan 2
        }

        It "Registra el tema Kali con paleta, usuario@host y segmentos ocultos" {
            $kali = Get-PromptTheme -Name "Kali"
            $kali | Should -Not -BeNullOrEmpty
            $kali.Name | Should -Be "Kali"
            $kali.Palette["Primary"] | Should -Be "Green"
            $kali.Segments["Session"]["ShowHost"] | Should -BeTrue
            $kali.Segments["Memory"]["Visible"] | Should -BeFalse
            $kali.Segments["Project"]["Visible"] | Should -BeFalse
        }

        It "Permite cambiar de tema con Set-PromptTheme" {
            Set-PromptTheme -Name "Dracula"
            $active = Get-ActiveTheme
            $active.Name | Should -Be "Dracula"
        }

        It "Resuelve colores de la paleta dinámicamente" {
            Set-PromptTheme -Name "Nord"
            $resolved = Resolve-ThemeColor -ColorName "Primary"
            $resolved | Should -Be "Blue" # Nord palette Primary is Blue

            Set-PromptTheme -Name "Dracula"
            $resolved = Resolve-ThemeColor -ColorName "Primary"
            $resolved | Should -Be "Magenta" # Dracula palette Primary is Magenta
        }

        It "Resuelve iconos dinámicamente si coinciden con las claves del tema" {
            Set-PromptTheme -Name "Nord"
            $resolved = Resolve-ThemeIcon -IconKey "GitDirty"
            $resolved | Should -Be "" # Nord GitDirty icon

            Set-PromptTheme -Name "Dracula"
            $resolved = Resolve-ThemeIcon -IconKey "GitDirty"
            $resolved | Should -Be "" # Dracula GitDirty icon
        }

        It "Expone bloques PowerLine truecolor con diamantes en Nord, Catppuccin y Kali" {
            $oldTheme = Get-ActiveTheme

            try {
                foreach ($themeName in @("Nord", "Catppuccin", "Kali")) {
                    Set-PromptTheme -Name $themeName
                    $theme = Get-PromptTheme -Name $themeName

                    foreach ($segmentName in $theme.Segments.Keys) {
                        $override = $theme.Segments[$segmentName]
                        if (-not $override.Visible) {
                            continue
                        }

                        $override.ContainsKey("Foreground") | Should -BeTrue
                        $override.ContainsKey("Background") | Should -BeTrue
                        $theme.Palette.ContainsKey($override["Foreground"]) | Should -BeTrue
                        $theme.Palette.ContainsKey($override["Background"]) | Should -BeTrue
                        $theme.Palette[$override["Background"]] | Should -Match '^#[0-9a-fA-F]{6}$'
                    }

                    $context = Invoke-Prompt
                    $prompt = Get-PromptString -Context $context -Renderer "PowerLine"
                    $prompt | Should -Match "`e\[38;2;"
                    $prompt | Should -Match "`e\[48;2;"
                    $prompt | Should -Match ""
                    $prompt | Should -Match ""
                }
            }
            finally {
                if ($oldTheme) {
                    Set-PromptTheme -Name $oldTheme.Name
                }
            }
        }

        It "Importa temas personalizados desde un archivo .Theme.ps1" {
            $oldTheme = Get-ActiveTheme
            $testThemeName = "ImportedTheme$([guid]::NewGuid().ToString('N'))"
            $themePath = Join-Path $TestDrive "$testThemeName.Theme.ps1"
            $themeScript = @'
Register-PromptTheme `
    -Name "__NAME__" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Cyan"
    } `
    -Icons @{
        "Session" = ">"
    } `
    -Segments @{
        "Session" = @{
            Visible    = $true
            Icon       = "Session"
            Foreground = "Primary"
        }
    }
'@
            $themeScript.Replace("__NAME__", $testThemeName) |
                Set-Content -LiteralPath $themePath -Encoding utf8

            try {
                $imported = Import-PromptTheme -Path $themePath -PassThru
                $imported | Should -Not -BeNullOrEmpty
                $imported.Name | Should -Be $testThemeName

                Set-PromptTheme -Name $testThemeName
                (Get-ActiveTheme).Name | Should -Be $testThemeName
            }
            finally {
                if ($oldTheme) {
                    Set-PromptTheme -Name $oldTheme.Name
                }
            }
        }

    }

    Context "Tema caliente / Hot Theme Switching (Fase 3E)" {

        BeforeAll {
            $script:hotThemeOriginal = Get-ActiveTheme
        }

        AfterAll {
            if ($script:hotThemeOriginal) {
                Set-PromptTheme -Name $script:hotThemeOriginal.Name
            }
        }

        It "Exporta Switch-PromptTheme y la función está disponible sin reiniciar PowerShell" {
            (Get-Command Switch-PromptTheme -ErrorAction SilentlyContinue) | Should -Not -Be $null
        }

        It "Cambia de tema activo inmediatamente sin reiniciar PowerShell" {
            $result = Switch-PromptTheme -Name "Dracula"

            $result | Should -Not -Be $null
            $result.Name | Should -Be "Dracula"
            (Get-ActiveTheme).Name | Should -Be "Dracula"
            (Get-PromptTheme -Name "Dracula").Name | Should -Be "Dracula"
        }

        It "Lanza error al intentar cambiar a un tema que no está registrado" {
            { Switch-PromptTheme -Name "TemaQueNoExiste$([guid]::NewGuid().ToString('N'))" } | Should -Throw
        }

        It "Devuelve información del tema activado (tema, paleta, iconos, segmentos, previo)" {
            Set-PromptTheme -Name "Nord"

            $result = Switch-PromptTheme -Name "Dracula"

            $result.PreviousTheme | Should -Be "Nord"
            $result.Name | Should -Be "Dracula"
            $result.SwitchedAt | Should -BeGreaterThan ([datetime]::Now.AddMinutes(-1))
            $result.Palette["Primary"] | Should -Be "Magenta" # Dracula palette
            $result.Icons["GitDirty"] | Should -Be ""       # Dracula icon
            $result.Segments["Session"]["Visible"] | Should -Be $true
        }

        It "El siguiente Invoke-Prompt renderiza con el nuevo tema (sin reinicio)" {
            Switch-PromptTheme -Name "Nord"

            $context = Invoke-Prompt
            $prompt = Get-PromptString -Context $context -Renderer "PowerLine"

            # Nord SessionBg = #5e81ac → truecolor de fondo 48;2;94;129;172
            $prompt | Should -Match "`e\[48;2;94;129;172"
            # Nord usa diamante de apertura (LeadingDiamond) en Session
            $prompt | Should -Match ""

            # Cambiar a otro tema y volver a renderizar: el nuevo tema se refleja
            Switch-PromptTheme -Name "Dracula"
            $context2 = Invoke-Prompt
            $prompt2 = Get-PromptString -Context $context2 -Renderer "PowerLine"
            $prompt2 | Should -Match "`e\[48;2;68;71;90" # Dracula SessionBg #44475a
        }

        It "No hay fuga de configuración entre temas (visibilidad, iconos y colores)" {
            $oldTheme = Get-ActiveTheme
            try {
                # Línea base (Default): Memory y Project visibles
                Set-PromptTheme -Name "Default"
                (Get-SegmentConfiguration -Name "Memory").Visible | Should -Be $true
                (Get-SegmentConfiguration -Name "Project").Visible | Should -Be $true
                (Get-SegmentConfiguration -Name "Session").Icon | Should -Be ""
                (Get-SegmentConfiguration -Name "Session").Foreground | Should -Be "Cyan"

                # Cambiar a Kali: oculta Memory, Project, DotNet, etc.
                Switch-PromptTheme -Name "Kali"
                (Get-SegmentConfiguration -Name "Memory").Visible | Should -Be $false
                (Get-SegmentConfiguration -Name "Project").Visible | Should -Be $false
                (Get-SegmentConfiguration -Name "Session").Icon | Should -Be "Session" # clave de icono de Kali
                (Get-SegmentConfiguration -Name "Session").Foreground | Should -Be "DarkText"

                # Volver a Default: nada del tema Kali debe persistir (sin fugas)
                Switch-PromptTheme -Name "Default"
                (Get-SegmentConfiguration -Name "Memory").Visible | Should -Be $true
                (Get-SegmentConfiguration -Name "Project").Visible | Should -Be $true
                (Get-SegmentConfiguration -Name "Session").Icon | Should -Be ""
                (Get-SegmentConfiguration -Name "Session").Foreground | Should -Be "Cyan"

                # Renderizar con Default no debe contener el truecolor de Kali SessionBg (#00a86b)
                $context = Invoke-Prompt
                $prompt = Get-PromptString -Context $context -Renderer "PowerLine"
                $prompt | Should -Not -Match "48;2;0;168;107"

                # Set-PromptTheme también debe invalidar estado y no filtrar configuración
                Set-PromptTheme -Name "Nord"
                (Get-SegmentConfiguration -Name "Memory").Visible | Should -Be $false
                Set-PromptTheme -Name "Default"
                (Get-SegmentConfiguration -Name "Memory").Visible | Should -Be $true
            }
            finally {
                if ($oldTheme) { Set-PromptTheme -Name $oldTheme.Name }
            }
        }

        It "El cambio de tema tarda menos de 100 ms" {
            $themes = @("Default", "Nord", "Dracula", "Catppuccin", "Kali")
            $null = Switch-PromptTheme -Name $themes[0] # calentamiento

            $maxMs = 0.0
            for ($i = 0; $i -lt 10; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                $null = Switch-PromptTheme -Name $themes[$i % $themes.Count]
                $sw.Stop()
                if ($sw.Elapsed.TotalMilliseconds -gt $maxMs) {
                    $maxMs = $sw.Elapsed.TotalMilliseconds
                }
            }

            Write-Verbose "[PPF] Tiempo máximo de cambio de tema: $maxMs ms"
            $maxMs | Should -BeLessThan 100
        }

    }

    Context "Configuration Manager (Fase 4)" {

        BeforeAll {
            $script:tempJson = Join-Path $PSScriptRoot "temp_config.json"
            $script:tempPsd1 = Join-Path $PSScriptRoot "temp_config.psd1"
        }

        AfterAll {
            if ($script:tempJson -and (Test-Path $script:tempJson)) { Remove-Item $script:tempJson -Force }
            if ($script:tempPsd1 -and (Test-Path $script:tempPsd1)) { Remove-Item $script:tempPsd1 -Force }
            Disable-PromptConfigHotReload
        }

        It "Exporta e Importa configuraciones JSON correctamente" {
            Set-PromptTheme -Name "Nord"
            $config = Get-PromptConfiguration
            $config.Renderer["Default"] = "Plain"
            Set-SegmentConfiguration -Name "Node" -Configuration @{ Visible = $false }

            Export-PromptConfiguration -Path $script:tempJson
            (Test-Path $script:tempJson) | Should -Be $true

            Set-PromptTheme -Name "Default"
            $config.Renderer["Default"] = "Minimal"
            Set-SegmentConfiguration -Name "Node" -Configuration @{ Visible = $true }

            Import-PromptConfiguration -Path $script:tempJson
            $config.Renderer["Default"] | Should -Be "Plain"
            (Get-ActiveTheme).Name | Should -Be "Nord"
            (Get-SegmentConfiguration -Name "Node").Visible | Should -Be $false
        }

        It "Exporta e Importa configuraciones PSD1 correctamente" {
            Set-PromptTheme -Name "Dracula"
            $config = Get-PromptConfiguration
            $config.Renderer["Default"] = "ANSI"
            Set-SegmentConfiguration -Name "Git" -Configuration @{ Visible = $true; Foreground = "Yellow" }

            Export-PromptConfiguration -Path $script:tempPsd1
            (Test-Path $script:tempPsd1) | Should -Be $true

            Set-PromptTheme -Name "Default"
            $config.Renderer["Default"] = "Minimal"

            Import-PromptConfiguration -Path $script:tempPsd1
            $config.Renderer["Default"] | Should -Be "ANSI"
            (Get-ActiveTheme).Name | Should -Be "Dracula"
            (Get-SegmentConfiguration -Name "Git").Foreground | Should -Be "Yellow"
        }

        It "Realiza recarga en caliente (Hot Reload) cuando el archivo es modificado" {
            $initHash = @{
                theme = "Nord"
                renderer = "PowerLine"
                segments = @{
                    Python = @{ Visible = $true }
                }
            }
            $initHash | ConvertTo-Json | Out-File -FilePath $script:tempJson -Encoding utf8

            Enable-PromptConfigHotReload -Path $script:tempJson
            (Get-ActiveTheme).Name | Should -Be "Nord"

            Start-Sleep -Seconds 1
            $updatedHash = @{
                theme = "Dracula"
                renderer = "Plain"
                segments = @{
                    Python = @{ Visible = $false }
                }
            }
            $updatedHash | ConvertTo-Json | Out-File -FilePath $script:tempJson -Encoding utf8

            $context = Invoke-Prompt
            (Get-ActiveTheme).Name | Should -Be "Dracula"
            (Get-SegmentConfiguration -Name "Python").Visible | Should -Be $false
        }

    }

    Context "Event System (Fase 9)" {

        It "Permite registrar oyentes y disparar eventos personalizados" {
            $state = @{ called = $false; argVal = $null }
            Register-PPFEventListener -EventName "CustomTestEvent" -Script {
                param($data)
                $state.called = $true
                $state.argVal = $data
            }

            Invoke-PPFEvent -EventName "CustomTestEvent" -EventArgs "HelloEvents"
            $state.called | Should -Be $true
            $state.argVal | Should -Be "HelloEvents"
        }

        It "Dispara eventos integrados automáticamente (BeforeRender, AfterRender, ThemeChanged)" {
            $state = @{ themeEventCalled = $false; beforeCalled = $false; afterCalled = $false }
            Register-PPFEventListener -EventName "ThemeChanged" -Script {
                $state.themeEventCalled = $true
            }

            Set-PromptTheme -Name "Nord"
            $state.themeEventCalled | Should -Be $true

            Register-PPFEventListener -EventName "BeforeRender" -Script { $state.beforeCalled = $true }
            Register-PPFEventListener -EventName "AfterRender" -Script { $state.afterCalled = $true }

            $context = Invoke-Prompt
            # Rendering happens in Get-PromptString, so both hooks fire there.
            $null = Get-PromptString -Context $context -Renderer "Plain"
            $state.beforeCalled | Should -Be $true
            $state.afterCalled | Should -Be $true
        }

    }

    Context "Cache System (Fase 10)" {

        AfterEach {
            Clear-AllPPFCache
        }

        It "Guarda y recupera valores de la caché en memoria" {
            Set-PPFCache -Key "TestKey" -Value "TestVal"
            $val = Get-PPFCache -Key "TestKey"
            $val | Should -Be "TestVal"
        }

        It "Respeta el Time-To-Live (TTL) en memoria" {
            Set-PPFCache -Key "TtlKey" -Value "TtlVal" -TtlSeconds 1
            Get-PPFCache -Key "TtlKey" | Should -Be "TtlVal"
            Start-Sleep -Seconds 2
            Get-PPFCache -Key "TtlKey" | Should -Be $null
        }

        It "Guarda y recupera valores de la caché en disco" {
            Set-PPFCache -Key "DiskKey" -Value "DiskVal" -UseDisk
            # Limpiar memoria para forzar lectura de disco
            $script:PPFMemoryCache.Clear()

            $val = Get-PPFCache -Key "DiskKey" -UseDisk
            $val | Should -Be "DiskVal"
        }

        It "Elimina entradas y limpia la caché correctamente" {
            Set-PPFCache -Key "KeyToClear" -Value "SomeVal"
            Clear-PPFCache -Key "KeyToClear"
            Get-PPFCache -Key "KeyToClear" | Should -Be $null
        }

    }

    Context "CPU Sampler & Health Diagnostics" {
        It "Inicia y detiene el Sampler CPU sin errores" {
            { Start-CpuSampler } | Should -Not -Throw
            $usage = Get-CpuUsage
            $usage | Should -BeGreaterThan -1
            { Stop-CpuSampler } | Should -Not -Throw
        }

        It "Retorna el diagnóstico del framework en Test-PromptFramework" {
            $diag = Test-PromptFramework
            $diag | Should -Not -Be $null
            $diag.Checks.Count | Should -BeGreaterThan 0
        }

        It "Retorna el estado de salud en Get-PromptHealth" {
            $health = Get-PromptHealth
            $health | Should -Not -Be $null
            $health.ActiveProviders.Count | Should -BeGreaterThan 0
        }
    }

    Context "Statistical Benchmarks" {
        It "Ejecuta Measure-PromptDetailed exitosamente" {
            $rep = Measure-PromptDetailed -Iterations 2
            $rep | Should -Not -Be $null
            $rep.TotalStats.Average | Should -BeGreaterThan -1
        }

        It "Ejecuta Measure-PromptCacheComparison exitosamente" {
            $comp = Measure-PromptCacheComparison -Iterations 2
            $comp | Should -Not -Be $null
            $comp.SpeedupFactor | Should -BeGreaterThan -1
        }

        It "Ejecuta benchmarks individuales exitosamente" {
            $stats = Measure-CpuProvider -Iterations 2
            $stats | Should -Not -Be $null
            $stats.Average | Should -BeGreaterThan -1
        }
    }

    Context "Hardening & Coverage Updates (Fase 5)" {
        It "Testea Get-Prompt para recuperar segmentos" {
            $segments = Get-Prompt
            $segments | Should -Not -Be $null
        }

        It "Testea el logger con todos los niveles (Trace, Debug, Info, Warn, Error)" {
            # Save current log level
            $oldLevel = $script:LogLevel
            
            # Set to TRACE to allow all logs
            Set-PPFLogLevel -Level "TRACE"
            $script:LogLevel | Should -Be "TRACE"
            
            { Write-PPFLog -Level "TRACE" -Message "Test Trace" } | Should -Not -Throw
            { Write-PPFLog -Level "DEBUG" -Message "Test Debug" } | Should -Not -Throw
            { Write-PPFLog -Level "INFO" -Message "Test Info" } | Should -Not -Throw
            { Write-PPFLog -Level "INFORMATION" -Message "Test Info alias" } | Should -Not -Throw
            { Write-PPFLog -Level "WARN" -Message "Test Warn" } | Should -Not -Throw
            { Write-PPFLog -Level "WARNING" -Message "Test Warn alias" } | Should -Not -Throw
            { Write-PPFLog -Level "ERROR" -Message "Test Error" } | Should -Not -Throw

            # Restore log level
            Set-PPFLogLevel -Level $oldLevel
        }

        It "Ejecuta Measure-Prompt con diferentes renderers" {
            $m = Measure-Prompt -Renderer "Minimal"
            $m | Should -Not -Be $null
            $m.TotalPromptTimeMs | Should -BeGreaterThan -1
        }

        It "Cubre metodos adicionales de cache y disco" {
            # Force disk cache loading/saving test cases
            $testKey = "TempDiskTest"
            Set-PPFCache -Key $testKey -Value "Val" -UseDisk -TtlSeconds 10
            $val = Get-PPFCache -Key $testKey -UseDisk
            $val | Should -Be "Val"

            # Trigger TTL Expirations via Disk Cache manual load/save
            $diskCache = Import-PPFDiskCache
            $diskCache[$testKey].Expiry = (Get-Date).AddSeconds(-10) # Expire manually
            Save-PPFDiskCache -Cache $diskCache
            $script:PPFMemoryCache.Remove($testKey) # Clear memory

            $valExpired = Get-PPFCache -Key $testKey -UseDisk
            $valExpired | Should -Be $null
        }

        It "Ejecuta todos los benchmarks individuales de los proveedores" {
            $benchmarks = @(
                "Session", "Project", "Path", "Git", "Python", "Node", 
                "Docker", "WSL", "Battery", "CPU", "Memory", "Kubernetes", "DotNet"
            )
            foreach ($b in $benchmarks) {
                $cmdName = "Measure-${b}Provider"
                if (Get-Command $cmdName -ErrorAction SilentlyContinue) {
                    $res = & $cmdName -Iterations 1
                    $res | Should -Not -Be $null
                }
            }
        }

        It "Prueba New-PromptSegment con configuracion de visibilidad y resolucion de color explicita" {
            $cfg = Get-PromptConfiguration
            $oldSegments = $cfg.Segments.Clone()
            $cfg.Segments["TestUncoveredSeg"] = @{ Visible = $false }
            $seg = New-PromptSegment -Name "TestUncoveredSeg" -Text "Hello"
            $seg | Should -Be $null
            $cfg.Segments = $oldSegments

            $seg2 = New-PromptSegment -Name "Session" -Text "User" -Foreground "Red" -Background "Blue"
            $seg2 | Should -Not -Be $null
            $seg2.Foreground | Should -Not -BeNullOrEmpty
            $seg2.Background | Should -Not -BeNullOrEmpty
        }

        It "Prueba el registro y recuperacion de componentes PPF (Fase 5)" {
            Register-PPFComponent -Category "Themes" -Name "CoverageTheme" -Value @{ Name = "CoverageTheme" }
            $retTheme = Get-PPFComponent -Category "Themes" -Name "CoverageTheme"
            $retTheme.Name | Should -Be "CoverageTheme"

            $dummyProv = @{ Name = "DummyProv" }
            Register-PPFComponent -Category "Providers" -Name "DummyProv" -Value $dummyProv
            $dummyProv2 = @{ Name = "DummyProv"; Check = $true }
            Register-PPFComponent -Category "Providers" -Name "DummyProv" -Value $dummyProv2
            $retProv = Get-PPFComponent -Category "Providers" -Name "DummyProv"
            $retProv.Check | Should -Be $true

            $dummySeg = @{ Name = "DummySeg" }
            Register-PPFComponent -Category "Segments" -Name "DummySeg" -Value $dummySeg
            $dummySeg2 = @{ Name = "DummySeg"; Check = $true }
            Register-PPFComponent -Category "Segments" -Name "DummySeg" -Value $dummySeg2
            $retSeg = Get-PPFComponent -Category "Segments" -Name "DummySeg"
            $retSeg.Check | Should -Be $true

            $allProvs = Get-PPFComponent -Category "Providers"
            $allProvs | Should -Not -Be $null
            $allThemes = Get-PPFComponent -Category "Themes"
            $allThemes | Should -Not -Be $null
        }

        It "Prueba la importacion/exportacion y Hot Reload del ConfigManager" {
            $t1 = $false; try { Import-PromptConfiguration -Path "test.invalid" } catch { $t1 = $true }; $t1 | Should -Be $true
            $t2 = $false; try { Export-PromptConfiguration -Path "test.invalid" } catch { $t2 = $true }; $t2 | Should -Be $true

            $ret = Import-PromptConfiguration -Path "nonexistent.json"
            $ret | Should -Be $null

            $tempPathJson = Join-Path $env:TEMP "temp_cov_config.json"
            @{ theme = "Nord"; renderer = "Plain"; segments = @{ Session = $true } } | ConvertTo-Json | Out-File $tempPathJson -Encoding utf8
            $t3 = $false; try { Import-PromptConfiguration -Path $tempPathJson } catch { $t3 = $true; Write-Host "DEBUG: Import failed: $_" } ; $t3 | Should -Be $false
            Remove-Item $tempPathJson -ErrorAction SilentlyContinue

            $tempReload = Join-Path $env:TEMP "temp_cov_reload.json"
            "invalid-json-content" | Out-File $tempReload -Encoding utf8
            $t4 = $false; try { Enable-PromptConfigHotReload -Path $tempReload } catch { $t4 = $true }; $t4 | Should -Be $false
            (Get-Item $tempReload).LastWriteTime = (Get-Date).AddMinutes(1)
            $t5 = $false; try { Test-PromptConfigReload } catch { $t5 = $true }; $t5 | Should -Be $false
            $t6 = $false; try { Disable-PromptConfigHotReload } catch { $t6 = $true }; $t6 | Should -Be $false
            Remove-Item $tempReload -ErrorAction SilentlyContinue
        }

        It "Prueba el manejo de errores en renderers, providers y segments" {
            $t1 = $false; try { Get-PromptRenderer -Name "NonExistentRenderer" } catch { $t1 = $true }; $t1 | Should -Be $true

            Register-PromptRenderer -Name "ThrowingRenderer" -Script { throw "Simulated renderer error" }
            $context = New-PromptContext
            $t2 = $false; try { Invoke-PromptRenderer -Context $context -Renderer "ThrowingRenderer" } catch { $t2 = $true }; $t2 | Should -Be $true

            Register-PromptProvider -Name "ThrowingProvider" -Priority 1 -Script { throw "Simulated provider error" }
            $context2 = Invoke-Prompt
            $context2.Metrics.ContainsKey("Provider_ThrowingProvider_TimeMs") | Should -Be $true

            Register-PromptSegment -Name "ThrowingSegment" -Priority 1 -Script { throw "Simulated segment error" }
            $segs = Get-PromptSegments
            $segs | Should -Not -Be $null
        }

        It "Prueba la generacion de estadisticas de Telemetria con valores vacios y outliers" {
            $statsOutliers = Get-PPFStatistics -Values @(1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 100.0)
            $statsOutliers.OutliersCount | Should -Be 1
            $statsOutliers.BoxPlot | Should -Not -BeNullOrEmpty
            $statsOutliers.Histogram.Count | Should -BeGreaterThan 0

            $statsEmpty = Get-PPFStatistics -Values @()
            $statsEmpty.Min | Should -Be 0.0
        }

        It "Ejecuta Test-PromptFramework con la suite de pruebas completa" {
            $diag = Test-PromptFramework -RunTests
            $diag | Should -Not -Be $null
            $diag.HealthScore | Should -BeGreaterThan -1
        }
    }

    Context "External Runtimes Mocking (Fase V & Resiliency)" {

        # --- Node.js tests ---
        It "Detecta Node.js correctamente cuando está instalado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "v18.12.1"
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-NodeVersion
            $version | Should -Be "18.12.1"
        }

        It "Maneja elegantemente cuando Node.js no está instalado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "CommandNotFoundException"
                    TimedOut  = $false
                    Installed = $false
                }
            } -ModuleName PablitusPrompt

            $version = Get-NodeVersion
            $version | Should -Be $null
        }

        It "Maneja errores de Node.js de ejecución" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 1
                    Output    = "Some fatal startup error"
                    Error     = "Some stderr"
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-NodeVersion
            $version | Should -Be $null
        }

        It "Maneja Node.js con timeout" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "Process timed out"
                    TimedOut  = $true
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-NodeVersion
            $version | Should -Be $null
        }

        It "Maneja una salida de Node.js con formato inesperado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "   v20.0.0-rc.1 with custom patches   "
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-NodeVersion
            $version | Should -Be "20.0.0-rc.1 with custom patches"
        }

        # --- Python tests ---
        It "Detecta Python correctamente con salida estándar" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "Python 3.13.5"
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-PythonVersion
            $version | Should -Be "3.13.5"
        }

        It "Maneja elegantemente cuando Python no está instalado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "CommandNotFoundException"
                    TimedOut  = $false
                    Installed = $false
                }
            } -ModuleName PablitusPrompt

            $version = Get-PythonVersion
            $version | Should -Be $null
        }

        It "Maneja errores de Python de ejecución" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 127
                    Output    = ""
                    Error     = "library loading error"
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-PythonVersion
            $version | Should -Be $null
        }

        It "Maneja Python con timeout" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "Process timed out"
                    TimedOut  = $true
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-PythonVersion
            $version | Should -Be $null
        }

        It "Maneja Python con formato inesperado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "   Py version: 3.14.0   "
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-PythonVersion
            $version | Should -Be "Py version: 3.14.0"
        }

        # --- DotNet tests ---
        It "Detecta DotNet correctamente cuando está instalado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "8.0.301"
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-DotNetVersion
            $version | Should -Be "8.0.301"
        }

        It "Maneja elegantemente cuando DotNet no está instalado" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "CommandNotFoundException"
                    TimedOut  = $false
                    Installed = $false
                }
            } -ModuleName PablitusPrompt

            $version = Get-DotNetVersion
            $version | Should -Be $null
        }

        It "Maneja errores de DotNet de ejecución" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 1
                    Output    = ""
                    Error     = "Configuration error"
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-DotNetVersion
            $version | Should -Be $null
        }

        It "Maneja DotNet con timeout" {
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "Process timed out"
                    TimedOut  = $true
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $version = Get-DotNetVersion
            $version | Should -Be $null
        }

        # --- Docker tests ---
        It "Maneja Docker con timeout y devuelve estado de error" {
            $oldDockerHost = $env:DOCKER_HOST
            $env:DOCKER_HOST = "tcp://localhost:2375"
            try {
                Mock Invoke-PPFExternalCommand {
                    return [pscustomobject]@{
                        ExitCode  = -1
                        Output    = ""
                        Error     = "Process timed out"
                        TimedOut  = $true
                        Installed = $true
                    }
                } -ModuleName PablitusPrompt

                $info = Get-DockerInfo
                $info.Active | Should -Be $false
                $info.Count | Should -Be 0
            } finally {
                $env:DOCKER_HOST = $oldDockerHost
            }
        }

        It "Maneja Docker cuando la salida contiene IDs de contenedores válidos" {
            $oldDockerHost = $env:DOCKER_HOST
            $env:DOCKER_HOST = "tcp://localhost:2375"
            try {
                Mock Invoke-PPFExternalCommand {
                    return [pscustomobject]@{
                        ExitCode  = 0
                        Output    = "a1b2c3d4e5f6`r`n1234567890ab"
                        Error     = ""
                        TimedOut  = $false
                        Installed = $true
                    }
                } -ModuleName PablitusPrompt

                $info = Get-DockerInfo
                $info.Active | Should -Be $true
                $info.Count | Should -Be 2
            } finally {
                $env:DOCKER_HOST = $oldDockerHost
            }
        }

        It "Maneja elegantemente cuando Docker no está instalado" {
            $oldDockerHost = $env:DOCKER_HOST
            $env:DOCKER_HOST = "tcp://localhost:2375"
            try {
                Mock Invoke-PPFExternalCommand {
                    return [pscustomobject]@{
                        ExitCode  = -1
                        Output    = $null
                        Error     = "CommandNotFoundException"
                        TimedOut  = $false
                        Installed = $false
                    }
                } -ModuleName PablitusPrompt

                $info = Get-DockerInfo
                $info.Active | Should -Be $false
                $info.Count | Should -Be 0
            } finally {
                $env:DOCKER_HOST = $oldDockerHost
            }
        }

        It "Maneja elegantemente cuando Docker daemon devuelve un error" {
            $oldDockerHost = $env:DOCKER_HOST
            $env:DOCKER_HOST = "tcp://localhost:2375"
            try {
                Mock Invoke-PPFExternalCommand {
                    return [pscustomobject]@{
                        ExitCode  = 1
                        Output    = ""
                        Error     = "docker daemon is not running"
                        TimedOut  = $false
                        Installed = $true
                    }
                } -ModuleName PablitusPrompt

                $info = Get-DockerInfo
                $info.Active | Should -Be $false
                $info.Count | Should -Be 0
            } finally {
                $env:DOCKER_HOST = $oldDockerHost
            }
        }

        # --- Git tests ---
        It "Maneja Git cuando está instalado y el repositorio está limpio" {
            Mock Get-GitDir { return "C:\test\.git" } -ModuleName PablitusPrompt
            Mock Test-GitRepository { return $true } -ModuleName PablitusPrompt
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "## main...origin/main"
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $gitStatus = Get-GitStatusAndBranch
            $gitStatus.IsRepository | Should -Be $true
            $gitStatus.Branch | Should -Be "main"
            $gitStatus.Dirty | Should -Be $false
        }

        It "Maneja Git cuando está instalado y el repositorio está sucio con archivos modificados" {
            Mock Get-GitDir { return "C:\test\.git" } -ModuleName PablitusPrompt
            Mock Test-GitRepository { return $true } -ModuleName PablitusPrompt
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 0
                    Output    = "## main...origin/main`r`n M src/File.ps1`r`n?? untracked.txt"
                    Error     = ""
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $gitStatus = Get-GitStatusAndBranch
            $gitStatus.IsRepository | Should -Be $true
            $gitStatus.Branch | Should -Be "main"
            $gitStatus.Dirty | Should -Be $true
        }

        It "Maneja elegantemente cuando Git no está instalado" {
            Mock Get-GitDir { return "C:\test\.git" } -ModuleName PablitusPrompt
            Mock Test-GitRepository { return $true } -ModuleName PablitusPrompt
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "CommandNotFoundException"
                    TimedOut  = $false
                    Installed = $false
                }
            } -ModuleName PablitusPrompt

            $gitStatus = Get-GitStatusAndBranch
            $gitStatus.IsRepository | Should -Be $true
            $gitStatus.Branch | Should -Be "HEAD"
            $gitStatus.Dirty | Should -Be $false
        }

        It "Maneja errores de Git (ej. repositorio corrupto) y se degrada elegantemente" {
            Mock Get-GitDir { return "C:\test\.git" } -ModuleName PablitusPrompt
            Mock Test-GitRepository { return $true } -ModuleName PablitusPrompt
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = 128
                    Output    = ""
                    Error     = "fatal: repository corrupted"
                    TimedOut  = $false
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $gitStatus = Get-GitStatusAndBranch
            $gitStatus.IsRepository | Should -Be $true
            $gitStatus.Branch | Should -Be "HEAD"
            $gitStatus.Dirty | Should -Be $false
        }

        It "Maneja Git con timeout y se degrada elegantemente" {
            Mock Get-GitDir { return "C:\test\.git" } -ModuleName PablitusPrompt
            Mock Test-GitRepository { return $true } -ModuleName PablitusPrompt
            Mock Invoke-PPFExternalCommand {
                return [pscustomobject]@{
                    ExitCode  = -1
                    Output    = $null
                    Error     = "Process timed out"
                    TimedOut  = $true
                    Installed = $true
                }
            } -ModuleName PablitusPrompt

            $gitStatus = Get-GitStatusAndBranch
            $gitStatus.IsRepository | Should -Be $true
            $gitStatus.Branch | Should -Be "HEAD"
            $gitStatus.Dirty | Should -Be $false
        }
    }

    Context "Pipeline Resiliency & Failure Recovery" {
        It "Maneja paso Recoverable: Falla un provider pero el pipeline continúa y el prompt se genera" {
            Register-PromptProvider -Name "RecoverableProvider" -Priority 10 -Script {
                throw "Recoverable connection error"
            }

            $global:logMsgs = @()
            Mock Write-PPFLog {
                param($Level, $Message)
                $global:logMsgs += "$($Level): $Message"
            } -ModuleName PablitusPrompt

            $context = Invoke-Prompt

            # 1. Excepción capturada (no explotó)
            $context | Should -Not -Be $null

            ($global:logMsgs -match "Recoverable connection error").Count | Should -BeGreaterThan 0

            # 3. Contexto íntegro
            $context.Timestamp | Should -Not -Be $null
            $context.Session.User | Should -Be $env:USERNAME

            # 4. Prompt renderizado
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Plain"
            $prompt | Should -Not -BeNullOrEmpty

            # 5. Métricas registradas
            $context.Metrics.ContainsKey("Provider_RecoverableProvider_TimeMs") | Should -Be $true
        }

        It "Maneja paso Partial: Falla un segmento visual y solo ese segmento desaparece" {
            Register-PromptSegment -Name "FailingSegment" -Priority 5 -Script {
                throw "Visual rendering failure"
            }

            Register-PromptSegment -Name "HealthySegment" -Priority 10 -Script {
                return New-PromptSegment -Name "HealthySegment" -Text "OK"
            }

            $global:logMsgs = @()
            Mock Write-PPFLog {
                param($Level, $Message)
                $global:logMsgs += "$($Level): $Message"
            } -ModuleName PablitusPrompt

            $context = Invoke-Prompt
            
            # El segmento que falló no está, el sano sí
            ($context.Segments | Where-Object Name -eq "FailingSegment") | Should -Be $null
            ($context.Segments | Where-Object Name -eq "HealthySegment") | Should -Not -Be $null

            # Log escrito
            ($global:logMsgs -match "Visual rendering failure").Count | Should -BeGreaterThan 0

            # Prompt renderizado incluye "OK" pero no falla
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Plain"
            $prompt | Should -Match "OK"
        }

        It "Maneja paso Fatal: Error explicito al fallar la inicializacion crítica" {
            $thrown = $false
            try {
                Import-PromptConfiguration -Path "invalid_extension.txt"
            } catch {
                $thrown = $true
            }
            $thrown | Should -Be $true
        }
    }

    Context "Golden Snapshot Regression Tests" {
        It "Compara la salida de los renderizadores con snapshots estáticos para evitar regresiones" {
            # Asegurar tema activo consistente para pruebas deterministas
            $oldTheme = Get-ActiveTheme
            Set-PromptTheme -Name "Default"

            try {
                $mockContext = New-PromptContext
                $mockContext.Session.User = "testuser"
                $mockContext.Session.Host = "testhost"
                $mockContext.Session.IsAdmin = $false
                
                # Segmento con icono, sin color
                $seg1 = [PSCustomObject]@{ Name = "Session"; Text = "testuser@testhost"; Icon = "👤"; Foreground = $null; Background = $null; Visible = $true }
                # Segmento sin icono, con color
                $seg2 = [PSCustomObject]@{ Name = "Path"; Text = "~/Projects/MyProject"; Icon = $null; Foreground = "Blue"; Background = "Black"; Visible = $true }
                # Segmento con icono y color
                $seg3 = [PSCustomObject]@{ Name = "Git"; Text = "feature/coverage"; Icon = ""; Foreground = "Red"; Background = "Black"; Visible = $true }
                # Segmento invisible
                $seg4 = [PSCustomObject]@{ Name = "Hidden"; Text = "invisible"; Icon = "X"; Foreground = "White"; Background = "White"; Visible = $false }

                $mockContext.Segments = @($seg1, $seg2, $seg3, $seg4)

                # Golden Snapshots Esperados para cada renderer
                $goldens = @{
                    "Plain" = "👤 testuser@testhost  ~/Projects/MyProject   feature/coverage"
                    "Minimal" = "\[feature/coverage\] ~/Projects/MyProject >"
                    "JSON" = '"Name":\s*"Session",\s*"Text":\s*"testuser@testhost"'
                    "Markdown" = "👤 testuser@testhost \| \*\*~/Projects/MyProject\*\* \| \*\* feature/coverage\*\*"
                    "HTML" = '<span>👤 testuser@testhost</span> <span style="color: Blue; background-color: Black;">~/Projects/MyProject</span> <span style="color: Red; background-color: Black;"> feature/coverage</span>'
                    "ANSI" = '👤 testuser@testhost  .*~/Projects/MyProject.*  .* feature/coverage.*'
                }

                foreach ($rendererName in $goldens.Keys) {
                    $output = Invoke-PromptRenderer -Context $mockContext -Renderer $rendererName
                    $cleanOutput = $output.Trim()
                    
                    if ($rendererName -in @("JSON", "HTML", "Markdown", "ANSI", "Minimal")) {
                        $cleanOutput | Should -Match $goldens[$rendererName]
                    } else {
                        $cleanOutput | Should -Be $goldens[$rendererName]
                    }
                }

                # Probar prompt de Admin en minimal para cubrir la rama de la línea 27 de minimal
                $mockContext.Session.IsAdmin = $true
                $minOutputAdmin = Invoke-PromptRenderer -Context $mockContext -Renderer "Minimal"
                $minOutputAdmin.Trim() | Should -Match "#$"

                # Probar prompt sin segmentos en minimal
                $mockContext.Segments = @()
                $minOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "Minimal"
                $minOutputNoSegs.Trim() | Should -Be "#"

                # Probar prompt sin segmentos en plain
                $plainOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "Plain"
                $plainOutputNoSegs.Trim() | Should -Be ""

                # Probar prompt sin segmentos en HTML
                $htmlOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "HTML"
                $htmlOutputNoSegs.Trim() | Should -Be ""

                # Probar prompt sin segmentos en Markdown
                $mdOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "Markdown"
                $mdOutputNoSegs.Trim() | Should -Be ""

                # Probar prompt sin segmentos en ANSI
                $ansiOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "ANSI"
                $ansiOutputNoSegs.Trim() | Should -Be ""

                # Probar prompt sin segmentos en Rich (debe retornar el símbolo de prompt de flecha)
                $richOutputNoSegs = Invoke-PromptRenderer -Context $mockContext -Renderer "Rich"
                $richOutputNoSegs.Trim() | Should -Be "`e[32m➔`e[0m"

                # Probar prompt con un segmento vacío y sin color en ANSI
                $segEmpty = [PSCustomObject]@{ Name = "Empty"; Text = ""; Icon = $null; Foreground = $null; Background = $null; Visible = $true }
                $mockContext.Segments = @($segEmpty)
                $ansiEmpty = Invoke-PromptRenderer -Context $mockContext -Renderer "ANSI"
                $ansiEmpty.Trim() | Should -Be ""

                # Probar prompt con un segmento vacío y sin color en Rich
                $richEmpty = Invoke-PromptRenderer -Context $mockContext -Renderer "Rich"
                $richEmpty.Trim() | Should -Be "[] `e[32m➔`e[0m"

                # Probar prompt de PowerLine sin segmentos visibles
                $mockContext.Segments = @()
                $plEmpty = Invoke-PromptRenderer -Context $mockContext -Renderer "PowerLine"
                $plEmpty | Should -Be "> "

                # PowerLine con segmentos sin background definidos
                $segNoBg = [PSCustomObject]@{ Name = "TestNoBg"; Text = "NoBg"; Icon = $null; Foreground = "Green"; Background = $null; Visible = $true }
                $segNoBgNext = [PSCustomObject]@{ Name = "TestNoBgNext"; Text = "NoBg2"; Icon = $null; Foreground = "Yellow"; Background = $null; Visible = $true }
                $mockContext.Segments = @($segNoBg, $segNoBgNext)
                
                $plOutput = Invoke-PromptRenderer -Context $mockContext -Renderer "PowerLine"
                $plOutput | Should -Not -BeNullOrEmpty

                # Golden check for PowerShell Objects (PromptContext structure & integrity)
                $mockContext.Session.User | Should -Be "testuser"
                $mockContext.Session.Host | Should -Be "testhost"
                $mockContext.Segments.Count | Should -Be 2
                $mockContext.Segments[0].Name | Should -Be "TestNoBg"
                $mockContext.Segments[1].Name | Should -Be "TestNoBgNext"
            }
            finally {
                if ($oldTheme) {
                    Set-PromptTheme -Name $oldTheme.Name
                }
            }
        }
    }

    }

    Context "Fast bootstrap path" {
        It "Carga el modulo con el bundle rapido en un proceso limpio" {
            $manifestPath = (Resolve-Path (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1")).Path
            $childScript = @"
Remove-Item Env:\PPF_USE_MODULAR_LOADER -ErrorAction SilentlyContinue
Import-Module '$manifestPath' -Force
Set-PromptTheme -Name Kali
`$context = Invoke-Prompt
`$text = Get-PromptString -Context `$context -Renderer ANSI
`$themeCount = (Get-PromptThemes | Measure-Object).Count
if (`$global:PPF_BootstrapMode -ne 'Fast') { throw "Expected Fast bootstrap, got '`$(`$global:PPF_BootstrapMode)'" }
if (`$themeCount -ne 5) { throw "Expected 5 themes, got `$themeCount" }
if (`$text -notmatch '@') { throw "Prompt does not contain user@host: `$text" }
'FAST_BOOTSTRAP_OK'
"@
            $output = & pwsh -NoProfile -NoLogo -Command $childScript 2>&1
            $LASTEXITCODE | Should -Be 0
            ($output -join "`n") | Should -Match "FAST_BOOTSTRAP_OK"
        }
    }

    AfterAll {
        $global:PPF_InsidePester = $null
    }
}

