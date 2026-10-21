# ============================================================
# Pablitus Prompt Framework (PPF)
# Coverage.Memory.Tests.ps1
# ============================================================

# Import at discovery time: InModuleScope requires the module to be loaded
# before Pester resolves the test tree.
Import-Module (Join-Path $PSScriptRoot "..\src\PablitusPrompt.psd1") -Force

Describe "PPF Coverage - Memory, CPU, Battery & Session" {

    BeforeAll {
        $global:PPF_InsidePester = $true
    }

    InModuleScope PablitusPrompt {

        Context "Memory.Service - Deteccion en Windows" {

            It "Calcula el uso desde CIM cuando TotalVisibleMemorySize es valido" {
                Mock Get-CimInstance {
                    [pscustomobject]@{
                        TotalVisibleMemorySize = 16000000
                        FreePhysicalMemory     = 4000000
                    }
                }

                Get-MemoryUsageFromWindows | Should -Be 75
            }

            It "Cae a WMI cuando CIM devuelve null" {
                Mock Get-CimInstance { $null }
                Mock Get-WmiObject {
                    [pscustomobject]@{
                        TotalVisibleMemorySize = 1000
                        FreePhysicalMemory     = 250
                    }
                }

                Get-MemoryUsageFromWindows | Should -Be 75
            }

            It "Cae a WMI cuando CIM lanza una excepcion" {
                Mock Get-CimInstance { throw "CIM no disponible" }
                Mock Get-WmiObject {
                    [pscustomobject]@{
                        TotalVisibleMemorySize = 2000
                        FreePhysicalMemory     = 1000
                    }
                }

                Get-MemoryUsageFromWindows | Should -Be 50
            }

            It "Cae a WMI cuando TotalVisibleMemorySize es cero" {
                Mock Get-CimInstance {
                    [pscustomobject]@{
                        TotalVisibleMemorySize = 0
                        FreePhysicalMemory     = 0
                    }
                }
                Mock Get-WmiObject {
                    [pscustomobject]@{
                        TotalVisibleMemorySize = 4000
                        FreePhysicalMemory     = 1000
                    }
                }

                Get-MemoryUsageFromWindows | Should -Be 75
            }

            It "Usa Win32MemoryStatus cuando CIM y WMI no devuelven datos" {
                Mock Get-CimInstance { $null }
                Mock Get-WmiObject { $null }

                $usage = Get-MemoryUsageFromWindows
                $usage | Should -BeOfType [int]
                $usage | Should -BeGreaterOrEqual 0
                $usage | Should -BeLessOrEqual 100
            }

            It "Select-FastestMemoryMethod prefiere CIM en Windows" {
                $script:FastestMemoryMethod = $null

                Select-FastestMemoryMethod

                $script:FastestMemoryMethod | Should -Be "Windows-Cim"
            }

            It "Select-FastestMemoryMethod usa WMI cuando CIM no existe" {
                Mock Get-Command { } -ParameterFilter { $Name -eq "Get-CimInstance" }
                $script:FastestMemoryMethod = $null

                Select-FastestMemoryMethod

                $script:FastestMemoryMethod | Should -Be "Windows-Wmi"
            }

            It "Select-FastestMemoryMethod usa la API Win32 cuando no hay CIM ni WMI" {
                Mock Get-Command { } -ParameterFilter { $Name -in @("Get-CimInstance", "Get-WmiObject") }
                $script:FastestMemoryMethod = $null

                Select-FastestMemoryMethod

                $script:FastestMemoryMethod | Should -Be "Windows"
            }
        }

        Context "Memory.Service - Linux /proc/meminfo" {

            AfterEach {
                $script:FastestMemoryMethod = $null
            }

            It "Calcula el porcentaje usando MemAvailable" {
                Mock Get-Content {
                    @(
                        "MemTotal:       16000000 kB"
                        "MemFree:         2000000 kB"
                        "MemAvailable:     8000000 kB"
                        "Buffers:          500000 kB"
                        "Cached:          1000000 kB"
                    )
                }
                $script:FastestMemoryMethod = "Linux"

                Get-MemoryUsage | Should -Be 50
            }

            It "Calcula el porcentaje sin MemAvailable sumando MemFree, Buffers y Cached" {
                Mock Get-Content {
                    @(
                        "MemTotal:       16000000 kB"
                        "MemFree:         2000000 kB"
                        "Buffers:          500000 kB"
                        "Cached:          1000000 kB"
                    )
                }
                $script:FastestMemoryMethod = "Linux"

                Get-MemoryUsage | Should -Be 78
            }

            It "Devuelve el fallback cero cuando MemTotal no esta presente" {
                Mock Get-Content { @("MemFree: 2000000 kB") }
                $script:FastestMemoryMethod = "Linux"

                Get-MemoryUsage | Should -Be 0
            }

            It "Devuelve null cuando la lectura de /proc/meminfo falla" {
                Mock Get-Content { throw "No se puede leer /proc/meminfo" }
                $script:FastestMemoryMethod = "Linux"

                Get-MemoryUsageFromLinux | Should -BeNullOrEmpty
                Get-MemoryUsage | Should -Be 0
            }
        }

        Context "Memory.Service - macOS (sysctl / vm_stat)" {

            BeforeAll {
                $script:MacSysctlRaw = $null
                $script:MacVmStatRaw = $null

                function script:sysctl {
                    return $script:MacSysctlRaw
                }

                function script:vm_stat {
                    return $script:MacVmStatRaw
                }
            }

            AfterAll {
                $script:MacSysctlRaw = $null
                $script:MacVmStatRaw = $null
                Remove-Item -LiteralPath "function:sysctl" -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath "function:vm_stat" -ErrorAction SilentlyContinue
            }

            AfterEach {
                $script:FastestMemoryMethod = $null
            }

            It "Calcula el porcentaje a partir de sysctl y vm_stat" {
                # Valores sinteticos en rango Int32: ver el test "documenta el desbordamiento"
                $script:MacSysctlRaw = [int64]8388608
                $script:MacVmStatRaw = @(
                    "Mach Virtual Memory Statistics: (page size of 16384 bytes)"
                    "Pages free:                                  128."
                    "Pages inactive:                               64."
                    "Pages speculative:                            16."
                    "Pages purgeable:                              16."
                )
                $script:FastestMemoryMethod = "MacOS"

                Get-MemoryUsage | Should -Be 56
            }

            It "Calcula el porcentaje con memoria real sin desbordar Int32" {
                # Regresion: con 8 GiB la resta total-disponible supera Int32.MaxValue y
                # [math]::Max(0, <double>) lanzaba, devolviendo siempre el fallback cero.
                $script:MacSysctlRaw = [int64]8589934592
                $script:MacVmStatRaw = @(
                    "Mach Virtual Memory Statistics: (page size of 16384 bytes)"
                    "Pages free:                               100000."
                    "Pages inactive:                            50000."
                    "Pages speculative:                         10000."
                    "Pages purgeable:                            5000."
                )
                $script:FastestMemoryMethod = "MacOS"

                Get-MemoryUsageFromMacOS | Should -Be 69
                Get-MemoryUsage | Should -Be 69
            }

            It "Devuelve null cuando sysctl no devuelve datos" {
                $script:MacSysctlRaw = $null
                $script:MacVmStatRaw = @("Pages free: 100000.")
                $script:FastestMemoryMethod = "MacOS"

                Get-MemoryUsageFromMacOS | Should -BeNullOrEmpty
            }

            It "Devuelve null cuando vm_stat no devuelve datos" {
                $script:MacSysctlRaw = [int64]8589934592
                $script:MacVmStatRaw = @()
                $script:FastestMemoryMethod = "MacOS"

                Get-MemoryUsageFromMacOS | Should -BeNullOrEmpty
            }
        }

        Context "Memory - Get-MemoryUsage por metodo" {

            AfterEach {
                $script:FastestMemoryMethod = $null
            }

            It "Delega en Windows para el metodo Windows-Cim" {
                Mock Get-MemoryUsageFromWindows { 55 }
                $script:FastestMemoryMethod = "Windows-Cim"

                Get-MemoryUsage | Should -Be 55
            }

            It "Delega en Windows para el metodo Windows-Wmi" {
                Mock Get-MemoryUsageFromWindows { 56 }
                $script:FastestMemoryMethod = "Windows-Wmi"

                Get-MemoryUsage | Should -Be 56
            }

            It "Delega en Windows para el metodo Windows" {
                Mock Get-MemoryUsageFromWindows { 57 }
                $script:FastestMemoryMethod = "Windows"

                Get-MemoryUsage | Should -Be 57
            }

            It "Delega en macOS para el metodo MacOS" {
                Mock Get-MemoryUsageFromMacOS { 61 }
                $script:FastestMemoryMethod = "MacOS"

                Get-MemoryUsage | Should -Be 61
            }

            It "Delega en Linux para el metodo Linux" {
                Mock Get-MemoryUsageFromLinux { 62 }
                $script:FastestMemoryMethod = "Linux"

                Get-MemoryUsage | Should -Be 62
            }

            It "Usa la rama por defecto con el metodo Fallback" {
                Mock Get-MemoryUsageFromWindows { 63 }
                $script:FastestMemoryMethod = "Fallback"

                Get-MemoryUsage | Should -Be 63
            }

            It "Devuelve cero cuando el metodo no aporta datos" {
                Mock Get-MemoryUsageFromWindows { $null }
                $script:FastestMemoryMethod = "Windows-Cim"

                Get-MemoryUsage | Should -Be 0
            }

            It "Selecciona el metodo automaticamente cuando no hay uno fijado" {
                Mock Select-FastestMemoryMethod { $script:FastestMemoryMethod = "Linux" }
                Mock Get-MemoryUsageFromLinux { 33 }
                $script:FastestMemoryMethod = $null

                Get-MemoryUsage | Should -Be 33
            }
        }

        Context "Battery.Service" {

            It "Devuelve porcentaje y estado Charging desde CIM" {
                Mock Get-CimInstance {
                    [pscustomobject]@{
                        BatteryStatus             = 3
                        EstimatedChargeRemaining  = 82
                    }
                }

                $info = Get-BatteryInfo

                $info.Percentage | Should -Be 82
                $info.Status | Should -Be "Charging"
            }

            It "Devuelve estado Discharging para un codigo desconocido" {
                Mock Get-CimInstance {
                    [pscustomobject]@{
                        BatteryStatus             = 99
                        EstimatedChargeRemaining  = 40
                    }
                }

                $info = Get-BatteryInfo

                $info.Percentage | Should -Be 40
                $info.Status | Should -Be "Discharging"
            }

            It "Devuelve null cuando no hay bateria" {
                Mock Get-CimInstance { $null }

                Get-BatteryInfo | Should -BeNullOrEmpty
            }

            It "Devuelve null cuando CIM lanza una excepcion" {
                Mock Get-CimInstance { throw "CIM no disponible" }

                Get-BatteryInfo | Should -BeNullOrEmpty
            }
        }

        Context "Segmentos Memory, CPU y Battery" {

            BeforeEach {
                $script:CoverageContext = New-PromptContext
            }

            It "Renderiza el segmento Memory con el icono del tema" {
                Mock Resolve-ThemeIcon { "ICON-MEM" }
                $script:CoverageContext.Memory.Usage = 42

                $entry = $script:PromptSegments | Where-Object Name -eq "Memory"
                $segment = & $entry.Script $script:CoverageContext

                $segment.Text | Should -Be "42%"
                $segment.Icon | Should -Be "ICON-MEM"
            }

            It "Usa el icono de respaldo en el segmento Memory" {
                Mock Resolve-ThemeIcon { $null } -ParameterFilter { $IconKey -eq "Memory" }
                $script:CoverageContext.Memory.Usage = 12

                $entry = $script:PromptSegments | Where-Object Name -eq "Memory"
                $segment = & $entry.Script $script:CoverageContext

                $segment | Should -Not -BeNullOrEmpty
                $segment.Icon | Should -Not -BeNullOrEmpty
                $segment.Icon | Should -Not -Be "Memory"
            }

            It "Oculta el segmento Memory con uso menor que uno" {
                $script:CoverageContext.Memory.Usage = 0

                $entry = $script:PromptSegments | Where-Object Name -eq "Memory"
                & $entry.Script $script:CoverageContext | Should -BeNullOrEmpty
            }

            It "Usa el icono de respaldo en el segmento CPU" {
                Mock Resolve-ThemeIcon { $null } -ParameterFilter { $IconKey -eq "CPU" }
                $script:CoverageContext.Cpu.Usage = 50

                $entry = $script:PromptSegments | Where-Object Name -eq "CPU"
                $segment = & $entry.Script $script:CoverageContext

                $segment | Should -Not -BeNullOrEmpty
                $segment.Icon | Should -Not -BeNullOrEmpty
                $segment.Icon | Should -Not -Be "CPU"
            }

            It "Renderiza el segmento CPU con el icono del tema" {
                Mock Resolve-ThemeIcon { "ICON-CPU" }
                $script:CoverageContext.Cpu.Usage = 25

                $entry = $script:PromptSegments | Where-Object Name -eq "CPU"
                $segment = & $entry.Script $script:CoverageContext

                $segment.Text | Should -Be "25%"
                $segment.Icon | Should -Be "ICON-CPU"
            }

            It "Oculta el segmento CPU con uso menor que uno" {
                $script:CoverageContext.Cpu.Usage = 0

                $entry = $script:PromptSegments | Where-Object Name -eq "CPU"
                & $entry.Script $script:CoverageContext | Should -BeNullOrEmpty
            }

            It "Renderiza el segmento Battery en carga con el icono del tema" {
                Mock Resolve-ThemeIcon { "ICON-BAT" }
                $script:CoverageContext.Battery.Percentage = 82
                $script:CoverageContext.Battery.Status = "Charging"

                $entry = $script:PromptSegments | Where-Object Name -eq "Battery"
                $segment = & $entry.Script $script:CoverageContext

                $segment.Text | Should -Be "82%"
                $segment.Icon | Should -Be "ICON-BAT"
            }

            It "Usa el icono de respaldo de carga en el segmento Battery" {
                Mock Resolve-ThemeIcon { $null } -ParameterFilter { $IconKey -eq "BatteryCharging" }
                $script:CoverageContext.Battery.Percentage = 64
                $script:CoverageContext.Battery.Status = "Charging"

                $entry = $script:PromptSegments | Where-Object Name -eq "Battery"
                $segment = & $entry.Script $script:CoverageContext

                $segment.Icon | Should -Be ([string][char]0x26A1)
            }

            It "Usa el icono de respaldo de descarga en el segmento Battery" {
                Mock Resolve-ThemeIcon { $null } -ParameterFilter { $IconKey -eq "Battery" }
                $script:CoverageContext.Battery.Percentage = 30
                $script:CoverageContext.Battery.Status = "Discharging"

                $entry = $script:PromptSegments | Where-Object Name -eq "Battery"
                $segment = & $entry.Script $script:CoverageContext

                $segment.Icon | Should -Be ([System.Char]::ConvertFromUtf32(0x1F50B))
            }

            It "Oculta el segmento Battery con porcentaje negativo" {
                $script:CoverageContext.Battery.Percentage = -1

                $entry = $script:PromptSegments | Where-Object Name -eq "Battery"
                & $entry.Script $script:CoverageContext | Should -BeNullOrEmpty
            }
        }

        Context "CPU.Service" {

            BeforeAll {
                $script:CoverageSavedCpuSharedData = $global:PPF_CpuSharedData
                $script:CoverageSavedCpuRunspace = $global:PPF_CpuRunspace
                $script:CoverageSavedCpuPowerShell = $global:PPF_CpuPowerShell
            }

            AfterEach {
                Stop-CpuSampler
                if ($null -ne $script:CoverageSavedCpuSharedData) {
                    $global:PPF_CpuSharedData = $script:CoverageSavedCpuSharedData
                }
            }

            AfterAll {
                Stop-CpuSampler
                if ($null -ne $script:CoverageSavedCpuSharedData) {
                    $global:PPF_CpuSharedData = $script:CoverageSavedCpuSharedData
                }
                if ($null -ne $script:CoverageSavedCpuRunspace) {
                    $global:PPF_CpuRunspace = $script:CoverageSavedCpuRunspace
                    $global:PPF_CpuPowerShell = $script:CoverageSavedCpuPowerShell
                }
            }

            It "Devuelve el valor del contenedor compartido" {
                Mock Start-CpuSampler { }
                $global:PPF_CpuSharedData.Usage = 37

                Get-CpuUsage | Should -Be 37
            }

            It "Devuelve cero cuando no existe contenedor compartido" {
                Mock Start-CpuSampler { }
                $global:PPF_CpuSharedData = $null

                Get-CpuUsage | Should -Be 0
            }

            It "No arranca un segundo sampler si el runspace ya esta abierto" {
                $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
                $runspace.Open()
                $global:PPF_CpuRunspace = $runspace
                $global:PPF_CpuPowerShell = $null
                $global:PPF_CpuSharedData.Stopped = $true

                Start-CpuSampler

                $global:PPF_CpuSharedData.Stopped | Should -BeFalse
                $global:PPF_CpuRunspace | Should -Be $runspace

                Stop-CpuSampler
            }

            It "Arranca el sampler leyendo el intervalo de la configuracion" {
                Mock Get-PromptConfiguration {
                    @{
                        Performance = @{
                            CpuSampleInterval = 0
                        }
                    }
                }

                Start-CpuSampler

                $global:PPF_CpuRunspace | Should -Not -BeNullOrEmpty
                $global:PPF_CpuPowerShell | Should -Not -BeNullOrEmpty

                Stop-CpuSampler

                $global:PPF_CpuRunspace | Should -BeNullOrEmpty
            }

            It "Stop-CpuSampler tolera un estado vacio" {
                $global:PPF_CpuSharedData = $null
                $global:PPF_CpuRunspace = $null
                $global:PPF_CpuPowerShell = $null

                { Stop-CpuSampler } | Should -Not -Throw
            }
        }

        Context "Session.Provider" {

            It "Rellena usuario, host y estado de administrador en Windows" {
                $context = New-PromptContext

                Invoke-SessionProvider -Context $context

                $context.Session.User | Should -BeOfType [string]
                $context.Session.User | Should -Not -BeNullOrEmpty
                $context.Session.Host | Should -Not -BeNullOrEmpty
                $context.Session.IsAdmin | Should -BeOfType [bool]
            }

            It "Usa los valores del entorno del sistema cuando faltan las variables" {
                $originalUser = $env:USERNAME
                $originalHost = $env:COMPUTERNAME
                try {
                    $env:USERNAME = $null
                    $env:COMPUTERNAME = $null
                    $context = New-PromptContext

                    Invoke-SessionProvider -Context $context

                    $context.Session.User | Should -Be ([System.Environment]::UserName)
                    $context.Session.Host | Should -Not -BeNullOrEmpty
                }
                finally {
                    $env:USERNAME = $originalUser
                    $env:COMPUTERNAME = $originalHost
                }
            }

            It "Esta registrado como provider con prioridad 100" {
                $provider = $script:PromptProviders | Where-Object Name -eq "Session"

                $provider | Should -Not -BeNullOrEmpty
                $provider.Priority | Should -Be 100
            }
        }
    }
}
