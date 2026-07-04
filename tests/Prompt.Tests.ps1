# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Tests.ps1 (Regresion, Pipeline & Renderers)
# ============================================================

Describe "Pablitus Prompt Framework - Regression & Integration Tests" {

    BeforeAll {
        $bootstrapPath = Resolve-Path (Join-Path $PSScriptRoot "..\src\Bootstrap.ps1")
        . $bootstrapPath
    }

    Context "Kernel, Modules & Pipeline" {

        It "Carga Bootstrap.ps1 sin errores y define las funciones clave" {
            $keyFunctions = @(
                "Invoke-Prompt", "Get-PromptString", "New-PromptContext", 
                "Initialize-PPFModules", "Register-PPFPipelineStep", "Invoke-PPFPipeline",
                "Get-Prompt", "Get-PromptProviders", "Get-PromptSegments", 
                "Get-PromptRenderers", "Get-PromptThemes", "Get-ActiveTheme", 
                "Set-PromptTheme", "Measure-Prompt", "Measure-PromptDetailed", 
                "Test-PromptFramework"
            )
            foreach ($func in $keyFunctions) {
                (Get-Command $func -ErrorAction SilentlyContinue) | Should Not Be $null
            }
        }

        It "Registra los 12 proveedores modularizados" {
            $expectedProviders = @("Session", "Project", "Path", "Git", "Python", "Node", "Docker", "WSL", "Battery", "CPU", "Memory", "Kubernetes")

            foreach ($providerName in $expectedProviders) {
                $provider = $script:PromptProviders | Where-Object Name -eq $providerName
                $provider | Should Not Be $null
            }
        }

        It "Registra los 12 segmentos modularizados" {
            $expectedSegments = @("Session", "Project", "Path", "Git", "Python", "Node", "Docker", "WSL", "Battery", "CPU", "Memory", "Kubernetes")

            foreach ($segmentName in $expectedSegments) {
                $segment = $script:PromptSegments | Where-Object Name -eq $segmentName
                $segment | Should Not Be $null
            }
        }

        It "Ejecuta el paso de Profiling en el Pipeline y añade métricas" {
            $context = Invoke-Prompt
            $context.Metrics.ContainsKey("ExecutionTimeMs") | Should Be $true
            $context.Metrics["ExecutionTimeMs"] | Should BeGreaterThan -1
        }

        It "Permite llamar a Get-PromptSegments de forma aislada sin pasar Context" {
            $segments = Get-PromptSegments
            $segments | Should Not Be $null
            $segments.Count | Should BeGreaterThan 0
        }

        It "Permite obtener proveedores con Get-PromptProviders" {
            $providers = Get-PromptProviders
            $providers | Should Not Be $null
            $providers.Count | Should BeGreaterThan 0
        }

    }

    Context "Rendering Engine & Renderers (Fase 2)" {

        $renderers = @("Plain", "Minimal", "JSON", "ANSI", "PowerLine", "Markdown", "HTML", "Rich")

        It "Tiene registrados todos los renderers previstos" {
            foreach ($rName in $renderers) {
                $renderer = Get-PromptRenderer -Name $rName
                $renderer | Should Not Be $null
            }
        }

        It "El renderer Plain genera una salida correcta" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Plain"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Not Match "`e\[" # No debe tener códigos ANSI
        }

        It "El renderer Minimal genera una salida simplificada" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Minimal"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match "[>#]$" # Debe terminar con char de prompt
        }

        It "El renderer JSON genera un JSON válido" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "JSON"
            $prompt | Should Not BeNullOrEmpty
            $parsed = $prompt | ConvertFrom-Json -ErrorAction SilentlyContinue
            $parsed | Should Not Be $null
            $parsed.Session.User | Should Be $env:USERNAME
        }

        It "El renderer ANSI contiene secuencias de escape ANSI" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "ANSI"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match "`e\[\d+m"
        }

        It "El renderer PowerLine contiene el glifo separador triangular de PowerLine" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "PowerLine"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match ""
        }

        It "El renderer Markdown genera una salida con formato markdown bold (**)" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Markdown"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match "\*\*"
        }

        It "El renderer HTML contiene etiquetas HTML span" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "HTML"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match "<span style="
        }

        It "El renderer Rich contiene secuencias de escape ANSI y corchetes" {
            $context = Invoke-Prompt
            $prompt = Invoke-PromptRenderer -Context $context -Renderer "Rich"
            $prompt | Should Not BeNullOrEmpty
            $prompt | Should Match "\["
            $prompt | Should Match "➔"
        }

    }

    Context "Theme Manager (Fase 3)" {

        It "Tiene registrados temas por defecto (Default, Nord, Dracula, Catppuccin)" {
            $themes = Get-PromptTheme
            $themes | Should Not Be $null
            $themes.Count | Should BeGreaterThan 2
        }

        It "Permite cambiar de tema con Set-PromptTheme" {
            Set-PromptTheme -Name "Dracula"
            $active = Get-ActiveTheme
            $active.Name | Should Be "Dracula"
        }

        It "Resuelve colores de la paleta dinámicamente" {
            Set-PromptTheme -Name "Nord"
            $resolved = Resolve-ThemeColor -ColorName "Primary"
            $resolved | Should Be "Blue" # Nord palette Primary is Blue

            Set-PromptTheme -Name "Dracula"
            $resolved = Resolve-ThemeColor -ColorName "Primary"
            $resolved | Should Be "Magenta" # Dracula palette Primary is Magenta
        }

        It "Resuelve iconos dinámicamente si coinciden con las claves del tema" {
            Set-PromptTheme -Name "Nord"
            $resolved = Resolve-ThemeIcon -IconKey "GitDirty"
            $resolved | Should Be "" # Nord GitDirty icon

            Set-PromptTheme -Name "Dracula"
            $resolved = Resolve-ThemeIcon -IconKey "GitDirty"
            $resolved | Should Be "" # Dracula GitDirty icon
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
            (Test-Path $script:tempJson) | Should Be $true

            Set-PromptTheme -Name "Default"
            $config.Renderer["Default"] = "Minimal"
            Set-SegmentConfiguration -Name "Node" -Configuration @{ Visible = $true }

            Import-PromptConfiguration -Path $script:tempJson
            $config.Renderer["Default"] | Should Be "Plain"
            (Get-ActiveTheme).Name | Should Be "Nord"
            (Get-SegmentConfiguration -Name "Node").Visible | Should Be $false
        }

        It "Exporta e Importa configuraciones PSD1 correctamente" {
            Set-PromptTheme -Name "Dracula"
            $config = Get-PromptConfiguration
            $config.Renderer["Default"] = "ANSI"
            Set-SegmentConfiguration -Name "Git" -Configuration @{ Visible = $true; Foreground = "Yellow" }

            Export-PromptConfiguration -Path $script:tempPsd1
            (Test-Path $script:tempPsd1) | Should Be $true

            Set-PromptTheme -Name "Default"
            $config.Renderer["Default"] = "Minimal"

            Import-PromptConfiguration -Path $script:tempPsd1
            $config.Renderer["Default"] | Should Be "ANSI"
            (Get-ActiveTheme).Name | Should Be "Dracula"
            (Get-SegmentConfiguration -Name "Git").Foreground | Should Be "Yellow"
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
            (Get-ActiveTheme).Name | Should Be "Nord"

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
            (Get-ActiveTheme).Name | Should Be "Dracula"
            (Get-SegmentConfiguration -Name "Python").Visible | Should Be $false
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
            $state.called | Should Be $true
            $state.argVal | Should Be "HelloEvents"
        }

        It "Dispara eventos integrados automáticamente (BeforeRender, AfterRender, ThemeChanged)" {
            $state = @{ themeEventCalled = $false; beforeCalled = $false; afterCalled = $false }
            Register-PPFEventListener -EventName "ThemeChanged" -Script {
                $state.themeEventCalled = $true
            }

            Set-PromptTheme -Name "Nord"
            $state.themeEventCalled | Should Be $true

            Register-PPFEventListener -EventName "BeforeRender" -Script { $state.beforeCalled = $true }
            Register-PPFEventListener -EventName "AfterRender" -Script { $state.afterCalled = $true }

            $null = Invoke-Prompt
            $state.beforeCalled | Should Be $true
            $state.afterCalled | Should Be $true
        }

    }

    Context "Cache System (Fase 10)" {

        AfterEach {
            Clear-AllPPFCache
        }

        It "Guarda y recupera valores de la caché en memoria" {
            Set-PPFCache -Key "TestKey" -Value "TestVal"
            $val = Get-PPFCache -Key "TestKey"
            $val | Should Be "TestVal"
        }

        It "Respeta el Time-To-Live (TTL) en memoria" {
            Set-PPFCache -Key "TtlKey" -Value "TtlVal" -TtlSeconds 1
            Get-PPFCache -Key "TtlKey" | Should Be "TtlVal"
            Start-Sleep -Seconds 2
            Get-PPFCache -Key "TtlKey" | Should Be $null
        }

        It "Guarda y recupera valores de la caché en disco" {
            Set-PPFCache -Key "DiskKey" -Value "DiskVal" -UseDisk
            # Limpiar memoria para forzar lectura de disco
            $script:PPFMemoryCache.Clear()

            $val = Get-PPFCache -Key "DiskKey" -UseDisk
            $val | Should Be "DiskVal"
        }

        It "Elimina entradas y limpia la caché correctamente" {
            Set-PPFCache -Key "KeyToClear" -Value "SomeVal"
            Clear-PPFCache -Key "KeyToClear"
            Get-PPFCache -Key "KeyToClear" | Should Be $null
        }

    }

}
