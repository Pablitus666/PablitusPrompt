# 🚀 Pablitus Prompt Framework (PPF) v1.5.1 — Prompt modular para PowerShell

> **Lanzamiento estable — Bootstrap rápido, temas PowerLine, núcleo .NET opt-in, Fase 3C (transient, tooltips, right prompt), Fase 3D (multi-shell, packaging), Fase 3E (soporte completo para segmentos de Oh My Posh) y soporte multiplataforma (Windows, macOS, Linux).**

Esta versión consolida **Pablitus Prompt Framework (PPF)** como un framework modular para construir prompts de PowerShell con una arquitectura clara, rápida y personalizable. PPF separa la recolección de datos, la construcción del contexto, el middleware, los segmentos, los temas y el renderizado en capas independientes.

El resultado es un prompt propio, comprensible y extensible, sin depender de servicios externos ni de una configuración opaca.

---

## 🔧 Innovaciones técnicas en v1.5.1

- **Bootstrap rápido:** las fuentes modulares se leen en orden de dependencia, se concatenan y se ejecutan una sola vez. El modo activo se expone en `$global:PPF_BootstrapMode` (`Fast` o `Modular`).
- **Cargador modular de compatibilidad:** se puede forzar con `$env:PPF_USE_MODULAR_LOADER = "1"` para cobertura con Pester o depuración archivo por archivo.
- **Omisión de proveedores ocultos:** `$global:PPF_SkipHiddenProviders = $true` evita ejecutar proveedores cuyos segmentos están ocultos por el tema activo.
- **13 proveedores integrados:** Session, WSL, Path, Project, Git, Docker, Python, Node, DotNet, Kubernetes, Battery, CPU y Memory.
- **14 segmentos visuales:** Session, Project, Path, Git, Python, Node, Docker, WSL, Battery, CPU, Memory, Kubernetes, DotNet y Time.
- **8 renderers:** Plain, Minimal, JSON, ANSI, PowerLine, Markdown, HTML y Rich.
- **12 temas integrados:** Default, Nord, Dracula, Catppuccin, Kali, Pablitus, Pablitus Dark, Pablitus Light, Pablitus Neon, Pablitus Matrix, Pablitus Ocean y Pablitus Sunset.
- **PowerLine truecolor:** bloques con fondos de 24 bits, separadores triangulares y diamantes de apertura/cierre para Dracula, Nord, Catppuccin y Kali.
- **Temas personalizados:** `Import-PromptTheme` permite importar archivos o directorios completos sin modificar el repositorio.
- **Segmento Time con reloj:** el segmento usa el glifo de reloj de Nerd Font (`U+F017`).
- **Caché en memoria y disco:** reutilización de información con TTL y persistencia opcional.
- **Configuración flexible:** importación/exportación JSON y PSD1, además de recarga en caliente.
- **Sistema de eventos:** hooks para `BeforeRender`, `AfterRender`, `ThemeChanged`, `ConfigurationChanged` y `ModuleLoaded`.
- **Sampler de CPU:** recolección en segundo plano respaldado por runspaces.
- **Git watcher:** seguimiento del estado del repositorio sin bloquear el prompt.
- **Diagnóstico y benchmarks:** `Get-PromptHealth`, `Test-PromptFramework`, `Measure-Prompt`, `Measure-PromptDetailed` y `Measure-PromptCacheComparison`.
- **Multiplataforma:** Windows, Linux y macOS con PowerShell 7+.
- **Calidad:** suite de Pester, pruebas de resiliencia, smoke tests Fast/Modular y PSScriptAnalyzer.

---

## 🆕 Fase 3C — Prompt transitorio, tooltips y right prompt

- **Right prompt:** bloque `type: "rprompt"` alineado a la derecha del prompt principal. Soporta `filler` (texto repetido entre bloques) y `overflow` (`hide` u `break`). Se compone con el prompt principal cuando se conoce el ancho de terminal (`TerminalWidth`).
- **Prompt transitorio:** `template.transientPrompt` define el prompt que se muestra tras aceptar un comando. Soporta `template`, `right_template`, `filler`, `newline`, `foreground` y `background`. Se expone con `Get-PromptString -Transient`.
- **Tooltips:** `tooltips` define segmentos right-aligned que se muestran al escribir palabras clave (`tips`). `tooltips_action` controla si reemplazan (`replace`, predeterminado), extienden (`extend`) o anteponen (`prepend`) el right prompt actual. Se expone con `Get-PromptTooltip -Command <cmd>`.
- **Núcleo .NET:** `PromptEngine.RenderTransient()` y `PromptEngine.RenderTooltipAsync()` renderizan estas funcionalidades de forma determinista y testeable.
- **CLI:** `ppf render --transient`, `ppf render --tooltip <comando>`, `ppf render --terminal-width <n>`.

#### Ejemplos rápidos

```powershell
# Habilitar el núcleo .NET (requerido para Fase 3C)
$env:PPF_USE_DOTNET_CORE = "1"
Import-Module PablitusPrompt -Force

# Right prompt: se combina con el prompt principal usando TerminalWidth
Get-PromptString -TerminalWidth 80

# Prompt transitorio: se muestra tras aceptar un comando
Get-PromptString -Transient -TerminalWidth 80

# Tooltip activado por la palabra clave "git", alineado a derecha desde la columna 5
Get-PromptTooltip -Command "git" -TerminalWidth 80 -Column 5
```

`tooltipsAction` controla cómo se combina el tooltip con el right prompt actual: `replace` (predeterminado, reemplaza), `extend` (añade al final) o `prepend` (antepone al inicio).

---

## 🆕 Fase 3D — Multi-shell y packaging

- **Empaquetado para PowerShell Gallery:** el módulo se distribuye como `.nupkg` además del ZIP tradicional. Generado con `build.ps1`.
- **Instalación desde PowerShell Gallery:** `Install-Module -Name PablitusPrompt -Scope CurrentUser`.
- **Multi-shell:** scripts de inicialización en `src/ShellInit/` para usar PPF desde bash, zsh, fish y cmd invocando a `pwsh`:
  - `ppf.bash` — `source` en `~/.bashrc`
  - `ppf.zsh` — `source` en `~/.zshrc`
  - `ppf.fish` — `source` en `~/.config/fish/config.fish`
  - `ppf.cmd` — macro o AutoRun en cmd
- **CI:** validación del `.nuspec`, ejecución de `build.ps1`, subida de artefactos `.nupkg` y `.zip`.

---

## 🆕 Fase 3E — Soporte completo para segmentos de Oh My Posh

- **40 proveedores de segmento .NET nuevos** para compatibilidad total con temas de Oh My Posh:
  - **Cloud:** aws, az, azure, azd, az_functions, gcp, firebase
  - **Sistema:** battery, cmd_duration
  - **Contenedores:** docker, docker_context
  - **.NET:** dotnet
  - **Git:** gitcommit, gitversion
  - **Go:** go, golang
  - **Kubernetes:** helm, kubernetes, kubectl
  - **JavaScript/TypeScript:** node, npm, npx, pnpm, yarn, bun, deno
  - **Python:** python
  - **Terraform:** terraform, terraform_required_version
  - **Build tools:** gradle, mvn, mvnw
  - **Ruby/Rust/Cargo:** ruby, rust, cargo
  - **PHP:** php, composer
  - **Swift/Kotlin/Scala:** swift, kotlin, scala
- **Total: 46 tipos de segmento soportados** (6 built-in + 40 de Oh My Posh).
- **Nerd Font automática:** el instalador (`Instalar-PPF.ps1`) descarga e instala JetBrainsMono Nerd Font automáticamente desde el release de GitHub (licencia SIL OFL, distribución libre permitida), eliminando la dependencia de terceros.

#### Importar temas de Oh My Posh

```powershell
Import-Module PablitusPrompt -Force
$env:PPF_USE_DOTNET_CORE = "1"
Import-PPFDotNetTheme -Path "ruta\al\tema.omp.json" -Activate -IgnoreUnsupported
Get-PromptString -TerminalWidth 120 -NoColor
```

---

## 🆕 Soporte Multiplataforma (Windows, macOS, Linux)

PPF está diseñado para funcionar en los tres sistemas operativos principales:

| Componente | Windows | macOS | Linux |
|------------|---------|-------|-------|
| Núcleo .NET | ✅ | ✅ | ✅ |
| PowerShell 7+ | ✅ | ✅ | ✅ |
| Batería (WMI/pmset/sysfs) | ✅ Win32_Battery | ✅ pmset | ✅ /sys/class/power_supply |
| Instalación de Nerd Font | C:\Windows\Fonts\ | ~/Library/Fonts/ | ~/.local/share/fonts/ + fc-cache |
| Caché del módulo | %LOCALAPPDATA% | ~/Library/Caches/ | ~/.cache/ |
| ShellInit | ppf.cmd, ppf.ps1 | ppf.bash, ppf.zsh, ppf.fish | ppf.bash, ppf.zsh, ppf.fish |

### Instalación en macOS y Linux

```bash
# Clonar el repositorio
git clone https://github.com/Pablitus666/PablitusPrompt.git
cd PablitusPrompt

# Ejecutar el instalador con PowerShell
pwsh ./Instalar-PPF.ps1

# Importar el módulo
pwsh -Command "Import-Module PablitusPrompt -Force"
```

El instalador detectará automáticamente el sistema operativo e instalará
JetBrainsMono Nerd Font en la ubicación correcta para cada plataforma.

---

## 🆕 Instalador mejorado (Instalar-PPF.ps1)

- Copia `src/` completo al módulo de PowerShell
- Copia el núcleo .NET compilado (DLL, PDB, deps.json) a `dotnet/publish/`
- **Descarga e instala JetBrainsMono Nerd Font automáticamente** (fuente primaria: release de GitHub, respaldo: nerd-fonts oficial)
- Lista los temas disponibles al finalizar

---

## 🚀 Guía de instalación

### 📦 Requisitos

- PowerShell 7.0 o superior.
- Windows, Linux o macOS.
- El instalador descarga e instala JetBrainsMono Nerd Font automáticamente.
- Git, Node, Python, Docker o Kubernetes son **opcionales**; sus segmentos se degradan si no están disponibles.

### ⚡ Importar el módulo

```powershell
git clone https://github.com/Pablitus666/PablitusPrompt.git
.\Instalar-PPF.ps1
Import-Module PablitusPrompt -Force
```

También se puede usar el bootstrap:

```powershell
. .\PablitusPrompt\src\Bootstrap.ps1
```

### 🎨 Configurar el prompt

Agrega un bloque como este a tu `$PROFILE` y ajusta la ruta:

```powershell
$PPF = "D:\PablitusPrompt\src"

if (Test-Path (Join-Path $PPF "Bootstrap.ps1")) {
    try {
        . (Join-Path $PPF "Bootstrap.ps1")

        $env:PPF_USE_DOTNET_CORE = "1"
        Set-PromptTheme -Name "Pablitus Minimal"
        $global:PPF_SkipHiddenProviders = $true

        function global:prompt {
            try {
                $context = Invoke-Prompt
                Get-PromptString -Context $context -Renderer "PowerLine"
            }
            catch {
                "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
            }
        }
    }
    catch {
        Write-Warning "[PPF] No se pudo cargar el prompt: $_"
    }
}
```

El `try/catch` evita que un fallo de un proveedor o renderer deje la consola sin prompt.

### 🧩 Cambiar de tema

```powershell
Set-PromptTheme -Name "Dracula"
Set-PromptTheme -Name "Nord"
Set-PromptTheme -Name "Catppuccin"
Set-PromptTheme -Name "Kali"
Set-PromptTheme -Name "Default"
Set-PromptTheme -Name "Pablitus"
Set-PromptTheme -Name "Pablitus Dark"
Set-PromptTheme -Name "Pablitus Light"
Set-PromptTheme -Name "Pablitus Neon"
Set-PromptTheme -Name "Pablitus Matrix"
Set-PromptTheme -Name "Pablitus Ocean"
Set-PromptTheme -Name "Pablitus Sunset"
Set-PromptTheme -Name "Pablitus Forest"
Set-PromptTheme -Name "Pablitus Cyberpunk"
```

### 🛠️ Temas personalizados

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MyTheme.Theme.ps1"
Set-PromptTheme -Name "MyTheme"
```

También se puede importar un directorio completo:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes"
```

El contrato completo está documentado en `docs/Themes.md` y hay un ejemplo en `examples/Themes/Sunset.Theme.ps1`.

---

## ✨ Especificaciones de software

- **Plataforma:** Windows, Linux y macOS.
- **Motor:** PowerShell 7+.
- **Arquitectura:** modular, con capas para Core, Configuration, Utils, Modules, Themes y Renderers.
- **Bootstrap:** Fast por defecto; Modular disponible por variable de entorno.
- **Proveedores:** 13 integrados.
- **Segmentos:** 14 integrados + 40 de Oh My Posh = 54 totales.
- **Renderers:** 8 integrados.
- **Temas:** 12 integrados.
- **Salida destacada:** PowerLine truecolor, ANSI, JSON, Markdown y HTML.
- **Caché:** memoria y disco.
- **Configuración:** JSON, PSD1 y hot reload.
- **Eventos:** hooks de ciclo de vida del prompt.
- **Diagnóstico:** health checks, benchmarks, telemetría local y logs por nivel.
- **Modo de operación:** local, sin telemetría remota.
- **Dependencias externas:** ninguna obligatoria para renderizar el prompt.
- **Licencia:** MIT.

### Rendimiento de referencia

En la máquina de desarrollo:

- Bootstrap local: aproximadamente **0.2–0.3 s**.
- Prompt PowerLine caliente: aproximadamente **20–25 ms** de media.
- El prompt sigue funcionando si un proveedor o segmento falla.
- La carga de módulos de iconos para `Get-ChildItem` se recomienda hacerla de forma diferida para no penalizar el arranque.

Los valores pueden variar según el hardware, la terminal, los proveedores visibles y el estado de la caché.

---

## 🧪 Calidad y validación

- **Pester:** 192 pruebas aprobadas, 0 fallos.
- **PSScriptAnalyzer:** 0 findings con la configuración del proyecto.
- **Smoke tests:** Fast y Modular OK.
- **Pruebas de resiliencia:** fallos de proveedores, segmentos y renderers.
- **Pruebas de caché:** memoria, disco y TTL.
- **Pruebas de configuración:** importación, exportación y hot reload.
- **Pruebas de temas:** contrato PowerLine, truecolor y diamantes.
- **Pruebas de Fase 3C:** transient prompt, tooltips y right prompt.
- **Pruebas xUnit .NET:** 125 pruebas aprobadas, 0 fallos.

Comandos de validación:

```powershell
Invoke-Pester -Path .\tests
Invoke-ScriptAnalyzer -Path .\src -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
pwsh -File .\build.ps1
```

---

## 📦 Distribución

PPF se distribuye como módulo de PowerShell. No requiere un instalador ni un ejecutable independiente.

- Repositorio: [github.com/Pablitus666/PablitusPrompt](https://github.com/Pablitus666/PablitusPrompt)
- Releases: [github.com/Pablitus666/PablitusPrompt/releases](https://github.com/Pablitus666/PablitusPrompt/releases)
- PowerShell Gallery: [powershellgallery.com/packages/PablitusPrompt](https://www.powershellgallery.com/packages/PablitusPrompt)

PPF se distribuye como módulo de PowerShell. Los artefactos de build incluyen:

- `PablitusPrompt-v<version>.zip` — módulo listo para copiar manualmente.
- `PablitusPrompt.<version>.nupkg` — paquete para PowerShell Gallery (`Install-Module`).
- `JetBrains_Mono.zip` — fuente Nerd Font incluida en el release para instalación automática.

Para generar los artefactos de build, ejecutar pruebas, cobertura, benchmarks y documentación de API:

```powershell
pwsh -File .\build.ps1
```

---

## 👨‍💻 Autor

**Walter Pablo Téllez Ayala**<br>
Software Developer<br>
📍 Bolivia 🇧🇴 <img src="https://flagcdn.com/w20/bo.png" width="20"/><br>
📧 pharmakoz@gmail.com

© 2026 — Pablitus Prompt Framework

---

**Descarga o clona el repositorio, ejecuta el instalador y empezá a construir tu prompt.**

```powershell
.\Instalar-PPF.ps1
Import-Module PablitusPrompt -Force
Set-PromptTheme -Name "Pablitus Minimal"
```