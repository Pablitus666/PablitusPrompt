# Pablitus Prompt Framework (PPF)

Pablitus Prompt Framework (PPF) es un framework modular para construir prompts de **PowerShell 7+** con una arquitectura clara, rápida y personalizable.

Separa la recolección de datos, la construcción del contexto, el middleware, los segmentos, la resolución de temas y el renderizado en capas independientes. Esto permite cambiar el aspecto del prompt sin reescribir la lógica que obtiene la información del sistema.

PPF funciona de forma local, no depende de servicios externos para renderizar el prompt y está diseñado para Windows, Linux y macOS.

---

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-0078D6?style=flat)
![Language](https://img.shields.io/badge/language-PowerShell%207%2B-5391FE?style=flat&logo=powershell&logoColor=white)
![Version](https://img.shields.io/badge/version-1.5.0-blue?style=flat)
![Architecture](https://img.shields.io/badge/architecture-Modular-informational?style=flat)
![Bootstrap](https://img.shields.io/badge/bootstrap-Fast-success?style=flat)
![Providers](https://img.shields.io/badge/providers-13-5391FE?style=flat)
![Segments](https://img.shields.io/badge/segments-14-informational?style=flat)
![Renderers](https://img.shields.io/badge/renderers-8-orange?style=flat)
![Themes](https://img.shields.io/badge/themes-5-9B59B6?style=flat)
![Output](https://img.shields.io/badge/output-PowerLine%20%2F%20ANSI%20%2F%20HTML-blueviolet?style=flat)
![Cache](https://img.shields.io/badge/cache-Memory%20%2B%20Disk-success?style=flat)
![Mode](https://img.shields.io/badge/mode-100%25%20Local-brightgreen?style=flat)
![Status](https://img.shields.io/badge/status-Stable-brightgreen?style=flat)
![Tests](https://img.shields.io/badge/tests-192%20passing-brightgreen?style=flat)
![Analyzer](https://img.shields.io/badge/analyzer-0%20findings-success?style=flat)
![License](https://img.shields.io/badge/license-MIT-green?style=flat)

---

![Social Preview](images/Preview.png)

---

## Características principales

- Arquitectura modular con responsabilidades separadas.
- **13 proveedores** integrados para contexto, entorno y estado del sistema.
- **14 segmentos** visuales reutilizables.
- **8 renderers** de salida: Plain, Minimal, JSON, ANSI, PowerLine, Markdown, HTML y Rich.
- **5 temas** integrados: Default, Nord, Dracula, Catppuccin y Kali.
- Bloques PowerLine truecolor para Dracula, Nord, Catppuccin y Kali.
- Segmento de hora con icono de reloj de Nerd Font (`U+F017`).
- Importación de temas personalizados sin modificar el repositorio.
- Bootstrap rápido que compila las fuentes modulares en una sola carga.
- Omisión opcional de proveedores cuyos segmentos están ocultos por el tema.
- Caché en memoria y en disco.
- Importación, exportación y recarga en caliente de configuración.
- Sistema de eventos para `BeforeRender`, `AfterRender`, `ThemeChanged`, `ConfigurationChanged` y `ModuleLoaded`.
- Sampler de CPU respaldado por runspaces.
- Watcher de repositorios Git.
- Diagnóstico de salud, benchmarks y telemetría de rendimiento.
- Funcionamiento local, sin telemetría remota ni dependencia de APIs externas.
- Compatibilidad con Windows, Linux y macOS.
- Suite de pruebas con Pester y análisis estático con PSScriptAnalyzer.

---

## Componentes

PPF combina proveedores, segmentos, renderers y temas. Cada capa puede utilizarse de forma independiente o extenderse con la API pública.

### Proveedores

Los proveedores recopilan información del sistema, del entorno de PowerShell o del directorio actual y la depositan en el `PromptContext`.

| Proveedor | Información |
| --- | --- |
| `Session` | Usuario, host, sistema operativo, shell y estado de elevación. |
| `WSL` | Detección de WSL y nombre de la distribución. |
| `Path` | Directorio actual, ruta abreviada y ruta relativa al home. |
| `Project` | Tipo de proyecto detectado: Node, Python, .NET, etc. |
| `Git` | Rama, commit, estado limpio/sucio, archivos sin seguimiento y ahead/behind. |
| `Docker` | Estado del daemon y cantidad de contenedores activos. |
| `Python` | Versión de Python y entorno virtual activo. |
| `Node` | Versión de Node.js y contexto del proyecto. |
| `DotNet` | Versión de .NET y archivos de proyecto. |
| `Kubernetes` | Contexto, namespace y estado de conexión. |
| `Battery` | Porcentaje de batería y estado de carga. |
| `CPU` | Porcentaje de uso de CPU. |
| `Memory` | Memoria total, disponible y porcentaje de uso. |

### Segmentos

Los segmentos construyen los bloques visibles del prompt a partir del contexto.

- `Session`
- `Project`
- `Path`
- `Git`
- `Python`
- `Node`
- `Docker`
- `WSL`
- `Battery`
- `CPU`
- `Memory`
- `Kubernetes`
- `DotNet`
- `Time`

Cada tema puede ocultar, mostrar o reconfigurar cualquier segmento sin modificar el código del proveedor.

### Renderers

| Renderer | Salida |
| --- | --- |
| `Plain` | Texto plano sin códigos ANSI. |
| `Minimal` | Prompt corto con el directorio esencial. |
| `JSON` | Contexto y segmentos en JSON válido. |
| `ANSI` | Colores ANSI de 16 colores. |
| `PowerLine` | Bloques truecolor con separadores y diamantes. |
| `Markdown` | Texto con formato Markdown. |
| `HTML` | Segmentos envueltos en HTML con estilos. |
| `Rich` | Diseño de terminal con símbolos y estilos enriquecidos. |

El renderer `PowerLine` requiere una **Nerd Font** instalada y seleccionada en la terminal.

### Temas

| Tema | Estilo | Composición principal |
| --- | --- | --- |
| `Default` | Base ANSI clásica | Layout estándar, sin bloques truecolor. |
| `Nord` | Polar Night, Frost y Aurora | Session, Path, Git, Python, Node y Time. |
| `Dracula` | Paleta oficial Dracula | Session, Path, Git, Node y Time. |
| `Catppuccin` | Catppuccin Mocha | Session, Path, Git, Python, Node y Time. |
| `Kali` | Verde, cian y ámbar | Session con `user@host`, Path, Git, Python y Time. |

Los temas PowerLine comparten la misma gramática visual de bloques, pero cada uno define su propia paleta, contraste y acentos. El segmento `Time` usa el icono de reloj de Nerd Font (`U+F017`).

---

## Diagnóstico y observabilidad

PPF incluye herramientas para inspeccionar el estado del framework y medir su rendimiento.

```powershell
Get-PromptHealth
Test-PromptFramework
Measure-Prompt
Measure-PromptDetailed
Measure-PromptCacheComparison
```

También se puede ajustar el nivel de logging:

```powershell
Set-PPFLogLevel -Level "DEBUG"
Set-PPFLogLevel -Level "INFO"
```

Niveles disponibles: `TRACE`, `DEBUG`, `INFO`, `WARN` y `ERROR`.

La telemetría local registra tiempos de providers, segmentos y renderers, además de estadísticas de caché. No se envía información a servicios externos.

---

## Arquitectura

PPF está organizado en capas con dependencias explícitas:

- `Core`: ciclo de vida del prompt, registro, caché, eventos, telemetría y renderizado.
- `Configuration`: configuración, valores por defecto, importación/exportación y hot reload.
- `Utils`: utilidades para ejecución segura de comandos externos.
- `Modules`: providers, services y segments de cada capacidad.
- `Themes`: paletas, iconos y valores por defecto de los segmentos.
- `Renderers`: formatos de salida.
- `Profile` y `examples`: integración opcional con perfiles y temas de ejemplo.
- `tests`: pruebas de regresión, integración y cobertura.

### Bootstrap rápido

`PablitusPrompt.psm1` lee las fuentes modulares en orden de dependencia, las concatena y las ejecuta una sola vez. Esto evita el coste de importar decenas de archivos pequeños sin perder la organización del código.

El modo activo se expone en:

```powershell
$global:PPF_BootstrapMode
```

Valores posibles: `Fast` o `Modular`.

Para forzar el cargador modular, por ejemplo durante cobertura con Pester:

```powershell
$env:PPF_USE_MODULAR_LOADER = "1"
Import-Module .\src\PablitusPrompt.psd1 -Force
```

### Omisión de proveedores ocultos

Por defecto todos los proveedores se ejecutan. Si el tema activo oculta segmentos, se puede evitar su coste con:

```powershell
$global:PPF_SkipHiddenProviders = $true
```

Los proveedores visibles conservan las dependencias que necesitan. Por ejemplo, el segmento Python puede seguir usando información del proveedor Project.

---

## Estructura del proyecto

```text
PablitusPrompt/
├── src/
│   ├── PablitusPrompt.psd1
│   ├── PablitusPrompt.psm1
│   ├── Bootstrap.ps1
│   ├── Core/
│   ├── Configuration/
│   ├── Utils/
│   ├── Modules/
│   ├── Themes/
│   ├── Renderers/
│   └── Profile/
├── docs/
├── examples/
├── tests/
├── benchmarks/
├── build/
├── images/
├── CHANGELOG.md
├── RELEASE_DESCRIPTION.md
└── README.md
```

### `src/Core/`

Contiene el ciclo de vida del prompt, el contexto, el registro de componentes, la caché, los eventos, la telemetría y el motor de renderizado.

### `src/Configuration/`

Contiene la configuración del prompt, los valores por defecto, la importación/exportación y la recarga en caliente.

### `src/Modules/`

Contiene los providers, services y segments organizados por capacidad. Cada módulo puede crecer sin afectar a los demás.

### `src/Themes/`

Contiene los temas integrados. Cualquier archivo `*.Theme.ps1` en esta carpeta se carga automáticamente.

### `src/Renderers/`

Contiene los renderers de salida. Cada renderer transforma el contexto y los segmentos en un formato específico.

### `examples/`

Contiene ejemplos listos para usar, incluido un tema personalizado:

```text
examples/Themes/Sunset.Theme.ps1
```

### `tests/`

Contiene la suite de Pester, pruebas de regresión, pruebas de resiliencia y scripts de soak/stress.

### `benchmarks/`

Contiene reportes y artefactos generados por las herramientas de medición.

---

## Flujo de procesamiento

La carga del módulo sigue este orden:

```text
Import-Module
    │
    ▼
PablitusPrompt.psd1
    │
    ▼
PablitusPrompt.psm1
    │
    ├── Core
    ├── Configuration
    ├── Utils
    ├── Modules
    ├── Themes
    └── Renderers
    │
    ▼
Public API
```

La generación del prompt sigue este flujo:

```text
Invoke-Prompt
    │
    ▼
New-PromptContext
    │
    ▼
Providers
    │
    ▼
Pipeline
    │
    ▼
Segments
    │
    ▼
Get-PromptString
    │
    ▼
Renderer
```

Esta separación permite cambiar la presentación sin alterar la recolección de datos y ampliar los proveedores sin reconstruir el sistema completo.

---

## Renderizado y salida

El renderer se selecciona al generar el prompt:

```powershell
$context = Invoke-Prompt
Get-PromptString -Context $context -Renderer "PowerLine"
```

También se puede usar el renderer configurado por defecto:

```powershell
Get-PromptString
```

Para guardar o integrar el prompt en otros flujos:

```powershell
Get-PromptString -Renderer "JSON" | ConvertFrom-Json
Get-PromptString -Renderer "HTML" | Set-Content .\prompt.html -Encoding utf8
```

### PowerLine

El renderer `PowerLine` genera bloques con fondo truecolor, separadores triangulares y diamantes de apertura/cierre. Está pensado para terminales modernas con soporte de color de 24 bits y Nerd Font.

Si la terminal no soporta truecolor, se puede usar `ANSI` o `Plain`.

---

## About

| Campo | Valor |
| --- | --- |
| Nombre | Pablitus Prompt Framework (PPF) |
| Descripción | Framework modular para prompts de PowerShell 7+. |
| Versión | `1.5.0` |
| Plataforma | Windows, Linux y macOS. |
| Tecnología | PowerShell 7+, .NET, ANSI/TrueColor y Nerd Font. |
| Modo de operación | Local, sin telemetría remota. |
| Autor | Walter Pablo Téllez Ayala. |
| Ubicación | Bolivia. |
| Año | 2026. |

PPF está pensado para quienes quieren un prompt propio, comprensible y extensible, sin depender de un servicio externo ni de una configuración opaca.

---

## Codificación y compatibilidad internacional

El proyecto está diseñado para trabajar con contenido **UTF-8**.

Los temas PowerLine utilizan glifos de Nerd Font y secuencias ANSI truecolor. Para una representación correcta se recomienda:

- Una terminal con soporte de color de 24 bits.
- Una Nerd Font instalada y configurada.
- `$PSStyle.OutputRendering = "Ansi"` cuando se inspeccionan salidas con color en PowerShell.

Los nombres de usuario, hosts, rutas y ramas Git conservan los caracteres proporcionados por el sistema. Si el entorno utiliza otra codificación, algunos glifos pueden mostrarse como signos de interrogación o cuadros.

---

## Compatibilidad

### PowerShell

Compatible con:

```text
PowerShell 7.0 o superior
```

El proyecto se desarrolla y valida con PowerShell 7.6.7.

### Multi-shell

PPF es un módulo de PowerShell, pero incluye scripts de inicialización en
`src/ShellInit/` que permiten usarlo desde otros shells (bash, zsh, fish, cmd)
invocando a `pwsh` para obtener el prompt:

| Archivo | Shell | Uso |
|---------|-------|-----|
| `ppf.bash` | bash | `source /ruta/a/ppf.bash` en `~/.bashrc` |
| `ppf.zsh` | zsh | `source /ruta/a/ppf.zsh` en `~/.zshrc` |
| `ppf.fish` | fish | `source /ruta/a/ppf.fish` en `~/.config/fish/config.fish` |
| `ppf.cmd` | cmd | Llamar desde un macro o AutoRun |

Estos scripts inician `pwsh` para renderizar el prompt de PPF y lo inyectan como
`PS1`/`PROMPT` del shell anfitrión. Nota: iniciar `pwsh` en cada prompt añade
un coste de arranque; para uso diario se recomienda usar PPF directamente desde
PowerShell 7+.

### Sistema operativo

- Windows
- Linux
- macOS

### Terminales recomendadas

- Windows Terminal
- WezTerm
- Alacritty
- Kitty
- iTerm2
- Terminales compatibles con ANSI truecolor y Nerd Font

### Dependencias opcionales

Los proveedores de Git, Node, Python, Docker y Kubernetes detectan sus herramientas localmente. Si una herramienta no está instalada, el segmento correspondiente se omite o se degrada sin romper el prompt.

---

## Funcionamiento local

PPF está diseñado para funcionar de forma local.

El renderizado del prompt no requiere:

- APIs externas.
- Servidores remotos.
- Servicios web.
- Conexión a Internet.
- Envío de telemetría a terceros.

La información se obtiene del sistema local, del entorno de PowerShell y de las herramientas instaladas. La caché y los logs se guardan en las rutas locales del usuario.

---

## Instalación

### Desde PowerShell Gallery (recomendado)

PPF se distribuye como módulo de PowerShell en PowerShell Gallery:

```powershell
Install-Module -Name PablitusPrompt -Scope CurrentUser
Import-Module PablitusPrompt -Force
```

Actualizar a una versión más reciente:

```powershell
Update-Module -Name PablitusPrompt
```

### Desde el repositorio (fuente)

Clona el repositorio o descarga una copia:

```powershell
git clone https://github.com/Pablitus666/PablitusPrompt.git
```

Importa el manifiesto del módulo:

```powershell
Import-Module .\src\PablitusPrompt.psd1 -Force
```

También se puede usar el bootstrap:

```powershell
. .\src\Bootstrap.ps1
```

### Verificar la instalación

```powershell
Get-PromptHealth
Get-PromptThemes
Get-PromptProviders
Get-PromptRenderers
```

---

## Configuración del prompt

Agrega un bloque como este a tu `$PROFILE` y ajusta la ruta del repositorio:

```powershell
$PPF = "D:\PablitusPrompt\src"

if (Test-Path (Join-Path $PPF "Bootstrap.ps1")) {
    try {
        . (Join-Path $PPF "Bootstrap.ps1")

        Set-PromptTheme -Name "Dracula"
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

El `try/catch` garantiza que un fallo de un proveedor, segmento o renderer no deje la consola sin prompt.

Para volver al prompt anterior, elimina la función `prompt` del perfil o comenta el bloque.

---

## Ejemplo de ejecución

```powershell
Import-Module .\src\PablitusPrompt.psd1 -Force

Set-PromptTheme -Name "Nord"

$context = Invoke-Prompt
Get-PromptString -Context $context -Renderer "PowerLine"
```

Ejemplo de prompt PowerLine:

```text
  Pablo   PablitusPrompt   main   13:53 
```

La salida exacta depende del tema, del directorio actual, de las herramientas instaladas y de los segmentos visibles.

---

## Fase 3C: Prompt transitorio, tooltips y right prompt

Desde la versión 1.5.0, PPF incluye soporte para tres funcionalidades avanzadas de la línea de comandos:

### Right prompt

Un bloque alineado a la derecha del prompt principal. Se configura con un bloque `type: "rprompt"` en el tema o configuración JSON:

```json
{
  "type": "rprompt",
  "alignment": "right",
  "filler": ".",
  "overflow": "hide",
  "segments": [
    { "type": "text", "template": "{{ .Path.Folder }}" }
  ]
}
```

Se renderiza mediante `Get-PromptString -TerminalWidth <n>` o automáticamente cuando el núcleo .NET conoce el ancho de terminal.

### Prompt transitorio

Un prompt simplificado que se muestra tras aceptar un comando, liberando espacio en pantalla. Se configura con `template.transientPrompt`:

```powershell
Get-PromptString -Transient -TerminalWidth 80
```

Soporta `template`, `right_template`, `filler`, `newline`, `foreground` y `background`.

### Tooltips

Segmentos right-aligned que se muestran al escribir palabras clave específicas (`tips`). Útil para mostrar información contextual mientras escribes comandos como `git`, `docker`, etc.

```powershell
Get-PromptTooltip -Command "git" -TerminalWidth 80 -Column 5
```

Soporta `tooltips_action` con valores `replace` (predeterminado), `extend` o `prepend` respecto al right prompt actual.

Todos estos_features requieren el núcleo .NET activo (`PPF_USE_DOTNET_CORE=1`) y el ancho de terminal se pasa desde el llamador para mantener el renderizado determinista.

---

## Temas

### Cambiar de tema

```powershell
Set-PromptTheme -Name "Dracula"
Set-PromptTheme -Name "Nord"
Set-PromptTheme -Name "Catppuccin"
Set-PromptTheme -Name "Kali"
Set-PromptTheme -Name "Default"
```

### Consultar temas

```powershell
Get-PromptThemes
Get-PromptTheme -Name "Nord"
Get-ActiveTheme
```

### Temas personalizados

PPF puede importar temas externos sin modificar el repositorio:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MyTheme.Theme.ps1"
Set-PromptTheme -Name "MyTheme"
```

También acepta un directorio completo:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes"
```

El parámetro `-PassThru` devuelve los temas importados:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes" -PassThru
```

El contrato completo de temas está documentado en [`docs/Themes.md`](docs/Themes.md), y hay un ejemplo listo en [`examples/Themes/Sunset.Theme.ps1`](examples/Themes/Sunset.Theme.ps1).

---

## Rendimiento

PPF está optimizado para que el prompt no agregue una latencia innecesaria a la terminal.

### Bootstrap rápido

El cargador rápido concatena las fuentes modulares y las ejecuta una sola vez. En la máquina de referencia, la carga inicial se redujo de forma significativa frente al cargador modular.

```powershell
$global:PPF_BootstrapMode
```

### Omisión de proveedores ocultos

Si un tema oculta segmentos, se puede evitar el coste de sus proveedores:

```powershell
$global:PPF_SkipHiddenProviders = $true
```

### Caché

PPF mantiene una caché en memoria y puede persistir valores en disco. Los proveedores y segmentos reutilizan información cuando corresponde.

```powershell
Set-PPFCache -Key "MiClave" -Value "MiValor"
Get-PPFCache -Key "MiClave"
Clear-PPFCache
Clear-AllPPFCache
```

### Medición

```powershell
Measure-Prompt
Measure-PromptDetailed
Measure-PromptCacheComparison
```

### Terminal-Icons

Si se utiliza un módulo de iconos para `Get-ChildItem`, se recomienda cargarlo de forma diferida. Importarlo al inicio agrega cientos de milisegundos al arranque de PowerShell.

---

## Características de robustez

PPF está diseñado para seguir funcionando aunque un componente falle o no esté disponible.

Entre los mecanismos utilizados se encuentran:

- Aislamiento de errores por proveedor y por segmento.
- `try/catch` en la integración del prompt.
- Valores por defecto y fallbacks.
- Detección opcional de herramientas externas.
- Degradación controlada cuando Git, Docker, Node, Python o Kubernetes no están disponibles.
- Caché con TTL y persistencia opcional.
- Recarga en caliente de configuración.
- Pruebas de resiliencia y recuperación.
- Validación de sintaxis y análisis estático.

Si un proveedor falla, el prompt puede seguir renderizando el resto de los segmentos. Si un segmento visual falla, solo ese segmento desaparece.

---

## Distribución

Las versiones oficiales de **Pablitus Prompt Framework** se publican en:

- Repositorio: [github.com/Pablitus666/PablitusPrompt](https://github.com/Pablitus666/PablitusPrompt)
- Releases: [github.com/Pablitus666/PablitusPrompt/releases](https://github.com/Pablitus666/PablitusPrompt/releases)
- PowerShell Gallery: [powershellgallery.com/packages/PablitusPrompt](https://www.powershellgallery.com/packages/PablitusPrompt)

PPF se distribuye como módulo de PowerShell. No requiere un instalador ni un ejecutable independiente. Los artefactos de build incluyen:

- `PablitusPrompt-v<version>.zip` — módulo listo para copiar manualmente.
- `PablitusPrompt.<version>.nupkg` — paquete para PowerShell Gallery (`Install-Module`).

Para generar los artefactos de build, ejecutar pruebas y actualizar la documentación de API:

```powershell
pwsh -File .\build.ps1
```

El script `build.ps1` ejecuta:

1. Pruebas Pester (todas deben pasar).
2. Validación de cobertura de código (≥90%).
3. Benchmarks de rendimiento.
4. Generación de documentación de API (`docs/API.md`).
5. Empaquetado como ZIP y como `.nupkg` para PowerShell Gallery.

Los artefactos se dejan en la carpeta `artifacts/`.

---

## Tecnologías

PPF utiliza principalmente:

- **PowerShell 7+**
- **.NET**
- **ANSI / TrueColor**
- **Nerd Font**
- **JSON**
- **PSD1**
- **HTML / CSS**
- **Pester**
- **PSScriptAnalyzer**
- **Runspaces**
- **FileSystemWatcher**
- **CIM/WMI**, `/proc/meminfo`, `sysctl` y `vm_stat` según la plataforma

No requiere frameworks externos para renderizar el prompt.

---

## Filosofía del proyecto

PPF busca combinar cuatro objetivos principales:

### Modularidad

Separar proveedores, segmentos, temas y renderers para que cada parte pueda evolucionar sin arrastrar a las demás.

### Rendimiento

Evitar trabajo innecesario en el hot path del prompt, reutilizar caché y permitir omitir proveedores ocultos.

### Personalización

Ofrecer temas integrados y un contrato claro para crear temas propios sin tocar el código del framework.

### Portabilidad

Funcionar en Windows, Linux y macOS con PowerShell 7+, sin depender de un servicio externo.

La separación entre estas responsabilidades permite:

- Cambiar la presentación sin alterar los proveedores.
- Agregar nuevos proveedores sin reconstruir el sistema.
- Crear temas sin modificar el núcleo.
- Mantener una arquitectura comprensible y testeable.
- Facilitar el mantenimiento y la evolución del proyecto.

---

## Estado del proyecto

**Versión actual:**

```text
v1.5.0
```

**Estado:**

```text
Stable
```

El proyecto incluye actualmente:

- Arquitectura modular.
- Bootstrap rápido.
- 13 proveedores.
- 14 segmentos.
- 8 renderers.
- 5 temas integrados.
- Temas personalizados.
- Caché en memoria y disco.
- Configuración con hot reload.
- Eventos y telemetría local.
- Suite de pruebas con Pester.
- Análisis estático con PSScriptAnalyzer.
- Documentación de arquitectura, API, temas, providers y renderers.

Antes de realizar cambios importantes, se recomienda revisar la arquitectura existente para mantener la separación entre:

```text
Providers
    │
    ▼
PromptContext
    │
    ▼
Pipeline
    │
    ▼
Segments
    │
    ▼
Renderer
```

---

## 📷 Capturas de pantalla

<p align="center">
  <img src="images/screenshot.png?v=2" alt="Pablitus Prompt Framework - PowerLine prompt" width="900"/>
</p>

---

## Seguridad y privacidad

PPF genera información a partir del sistema local y del entorno de PowerShell.

El prompt puede mostrar información potencialmente identificable, como:

- Nombre de usuario.
- Nombre del equipo.
- Directorio actual.
- Rama y estado de Git.
- Versiones de runtimes instalados.
- Estado de batería, CPU y memoria.
- Contexto de Kubernetes.

PPF no envía esa información a servicios externos. La telemetría es local y se utiliza para diagnóstico y benchmarks.

Antes de publicar capturas, logs o reportes generados por el framework, se recomienda revisar su contenido y eliminar cualquier información personal o identificable que no se desee compartir.

---

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**.

Consulta el archivo [`LICENSE`](LICENSE) para más información.

---

## 🤝 Contribuciones

Las contribuciones, sugerencias y mejoras son bienvenidas.

Si encuentras un problema o tienes una idea, puedes abrir un *issue* o un *pull request* en el repositorio.

Antes de enviar cambios, se recomienda ejecutar:

```powershell
Invoke-Pester -Path .\tests
Invoke-ScriptAnalyzer -Path .\src -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

---

## 👨‍💻 Autor

**Walter Pablo Téllez Ayala**<br>
Software Developer<br>
📍 Bolivia 🇧🇴 <img src="https://flagcdn.com/w20/bo.png" width="20"/><br>
📧 pharmakoz@gmail.com

© 2026 — Pablitus Prompt Framework

---

# Pablitus Prompt Framework

**Modular.**

**Rápido.**

**Personalizable.**

**Hecho para PowerShell.**
