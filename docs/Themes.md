# Pablitus Prompt Framework - Temas

Los temas de PPF definen la paleta de colores, los íconos y las anulaciones por
segmento que los segmentos usan para renderizarse. Un tema solo declara
anulaciones; al cambiar de tema se restaura primero la configuración base de los
segmentos, por lo que los segmentos ocultos o los íconos nunca se filtran entre
temas.

PPF incluye 12 temas oficiales en `src/Themes/`. Los temas integrados de
PowerLine usan el glifo de reloj de Nerd Font (`U+F017`) para el segmento
`Time`.

## Temas oficiales

| Tema | Estilo | Paleta principal | Mejor caso de uso |
| --- | --- | --- | --- |
| `Default` | Base ANSI clásica | Cyan, Blue, Green, Yellow, Magenta, Red | Prompts sencillos y compatibles con cualquier terminal sin Nerd Font. |
| `Nord` | Polar Night, Frost y Aurora | `#5e81ac`, `#434c5e`, `#a3be8c`, `#ebcb8b` | Escritorios oscuros con buena legibilidad y bloques PowerLine. |
| `Dracula` | Paleta oficial Dracula | `#44475a`, `#6272a4`, `#ffb86c`, `#8be9fd`, `#ff79c6` | Estilo oscuro clásico con alto contraste y silueta de Oh My Posh. |
| `Catppuccin` | Catppuccin Mocha | `#cba6f7`, `#585b70`, `#fab387`, `#a6e3a1`, `#89b4fa` | Paleta pastel suave sobre fondo oscuro para sesiones largas. |
| `Kali` | Verde, cian y ámbar | `#00a86b`, `#00838f`, `#ffc107`, `#ff9800`, `#9c27b0` | Entornos de seguridad y auditoría con `user@host` visible. |
| `Pablitus` | PowerLine truecolor oscuro | `#1e1e2e`, `#89b4fa`, `#a6e3a1`, `#f38ba8` | Tema oficial de PPF: Session, Path, Git y Time con diamantes. |
| `Pablitus Dark` | PowerLine truecolor muy oscuro | `#0a0a0a`, `#bb86fc`, `#03dac6`, `#ff5252` | Fondos negros; transient prompt con `right_template` y `filler`. |
| `Pablitus Light` | PowerLine truecolor claro/neón | `#fafafa`, `#ff00ff`, `#00e5ff`, `#00ff9f`, `#ff6b00` | Terminales con tema claro; diamantes magenta, cian y naranja. |
| `Pablitus Neon` | PowerLine truecolor neón oscuro | `#0a0a0a`, `#ff00ff`, `#00e5ff`, `#00ff9f` | Estilo neón vibrante sobre fondo oscuro; diamantes magenta, cian y verde. |
| `Pablitus Matrix` | PowerLine truecolor verde matriz | `#000000`, `#00ff00`, `#33ff33` | Estilo monocromo verde matriz; sesiones de hacking y terminales oscuros. |
| `Pablitus Ocean` | PowerLine truecolor azul océano | `#0a192f`, `#64ffda`, `#1d3557`, `#233554` | Desarrollo con rutas, Git y Docker; transient prompt y tooltips. |
| `Pablitus Sunset` | PowerLine truecolor atardecer | `#2d1b19`, `#ef476f`, `#118ab2`, `#06d6a0` | Sesiones nocturnas con tonos cálidos; right prompt con `overflow: break`. |

Los temas PowerLine comparten la misma gramática visual de bloques, diamantes y
glifos de Nerd Font, pero cada uno define su propia paleta, contraste y acentos.
El segmento `Time` usa el icono de reloj de Nerd Font (`U+F017`).

---

## 1. Default

- **Paleta**: colores ANSI estándar (Cyan, Blue, Green, Yellow, Magenta, Red).
- **Íconos**: equivalentes Unicode/Nerd Font limpios.
- **Renderizador**: base orientada a ANSI. Funciona con PowerLine a través del
  fallback de fondo del renderizador, pero no define bloques truecolor.
- **Segmentos visibles**: Session, Project, Path, Git, Python y Node.

---

## 2. Nord

- **Paleta**: paleta oficial Nord (Polar Night, Snow Storm, Frost y Aurora).
- **PowerLine**: bloques truecolor para Session, Path, Git, Python, Node y
  Time.
- **Diseño**: bloque de sesión azul escarcha, bloque de ruta Polar Night
  compacto, acentos de Git/Python/Node y bloque de tiempo cerrado con diamante
  amarillo. Usa texto claro sobre los bloques oscuros de Sesión/Ruta y texto
  oscuro sobre los acentos de Aurora/Frost. Project y los bloques de telemetría
  están ocultos por defecto para mantener el diseño compacto; siguen teniendo
  colores si se habilitan.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 3. Dracula

- **Paleta**: paleta truecolor oficial Dracula: `#44475a` sesión, `#6272a4`
  ruta, `#ffb86c` Git, `#8be9fd` Node, `#ff79c6` tiempo, `#f8f8f2` texto y
  `#282a36` texto oscuro.
- **Diseño**: bloques PowerLine con diamante de apertura en sesión y diamante de
  cierre en tiempo, al estilo del tema Dracula de Oh My Posh. Session y Path
  usan texto claro; Git, Node y Time usan texto oscuro para mayor contraste.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.
- **Comportamiento**: muestra Session, Path, Git, Node y Time. Oculta
  `Project`, `Python`, `Docker`, `WSL`, `Battery`, `CPU`, `Memory`,
  `Kubernetes` y `DotNet` para mantener la silueta oficial de Dracula.

---

## 4. Catppuccin

- **Paleta**: Catppuccin Mocha (Mauve, Blue, Peach, Yellow, Green y tonos de
  Surface).
- **PowerLine**: bloques truecolor con un bloque de ruta Surface oscuro y
  bloques de acento pastel para Session, Git, Python, Node y Time.
- **Diseño**: diamante de sesión en mauve, bloque de ruta compacto de carpeta
  oscura, acentos de Git/Python/Node y bloque de tiempo azul cerrado con
  diamante. Usa texto oscuro sobre los acentos pastel y texto claro sobre el
  bloque de ruta oscuro. Project y los bloques de telemetría están ocultos por
  defecto; siguen teniendo colores si se habilitan.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 5. Kali

- **Paleta**: colores de terminal al estilo Kali (sesión verde, ruta cian
  oscuro, Git ámbar, Python naranja, tiempo púrpura) con bloques PowerLine
  truecolor.
- **Íconos**: glifos de Nerd Font compartidos con `Default`. El segmento Time
  usa el icono de reloj de Nerd Font (`U+F017`).
- **Comportamiento**: muestra `user@host` en el segmento de sesión y oculta
  `Project`, `Memory`, `CPU`, `Battery`, `Docker`, `Kubernetes`, `DotNet`,
  `Node` y `WSL` para un prompt minimalista. `ShowHost` se puede habilitar de
  forma independiente en la configuración `Session` de cualquier tema.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 6. Pablitus

- **Paleta**: PowerLine truecolor oscuro sobre `#1e1e2e` con `#89b4fa`
  (sesión), `#a6e3a1` (ruta), `#89b4fa` (Git) y `#f38ba8` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes de apertura y cierre.
  Project está oculto. Es el tema oficial de PPF.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 7. Pablitus Dark

- **Paleta**: PowerLine truecolor muy oscuro sobre `#0a0a0a` con `#bb86fc`
  (sesión), `#03dac6` (ruta), `#bb86fc` (Git) y `#ff5252` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes; Project está oculto.
  Demuestra las capacidades de Fase 3C con prompt transitorio que usa
  `right_template` y `filler`. Tema oficial oscuro de PPF.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 8. Pablitus Light

- **Paleta**: PowerLine truecolor claro/neón sobre `#fafafa` con `#ff00ff`
  (sesión), `#00e5ff` (ruta), `#00ff9f` (Git) y `#ff6b00` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes; Project está oculto.
  Paleta clara/neón con diamantes magenta, cian y naranja, optimizada para
  terminales con tema claro.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 9. Pablitus Neon

- **Paleta**: PowerLine truecolor neón oscuro sobre `#0a0a0a` con `#ff00ff`
  (sesión), `#00e5ff` (ruta), `#00ff9f` (Git) y `#ff00ff` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes de apertura y cierre.
  Project está oculto. Paleta neón vibrante sobre fondo oscuro con diamantes
  magenta, cian y verde lima.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 10. Pablitus Matrix

- **Paleta**: PowerLine truecolor monocromo verde matriz sobre `#000000`
  con `#00ff00` (sesión, ruta, Git) y `#33ff33` (ruta, tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes de apertura y cierre.
  Project y WSL están ocultos. Paleta verde matriz sobre fondo negro, ideal
  para terminales oscuros y sesiones de estilo hacking.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 11. Pablitus Ocean

- **Paleta**: PowerLine truecolor azul océano sobre `#0a192f` con `#64ffda`
  (sesión, Git), `#1d3557` (sesión) y `#233554` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes de apertura y cierre.
  Project está oculto. Incluye transient prompt con `right_template`,
  tooltips con `tips` específicos de Docker y right prompt con `filler`.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 12. Pablitus Sunset

- **Paleta**: PowerLine truecolor atardecer sobre `#2d1b19` con `#ef476f`
  (sesión), `#118ab2` (ruta), `#06d6a0` (Git) y `#ffd166` (tiempo).
- **Íconos**: Nerd Font (`U+F017` para el reloj).
- **Diseño**: Session, Path, Git y Time con diamantes de apertura y cierre.
  Project está oculto. Incluye transient prompt con `filler` personalizado,
  tooltips con múltiples palabras clave y right prompt con `overflow: break`.
- **Renderizador**: se usa mejor con `Get-PromptString -Renderer "PowerLine"`.

---

## 13. Contrato de tema PowerLine

Para que un tema renderice bloques PowerLine pulidos, cada anulación de segmento
visible debería definir:

| Clave | Propósito | Ejemplo |
| --- | --- | --- |
| `Foreground` | Color del texto. Usa una clave de paleta o un valor `#rrggbb`. | `"Text"` |
| `Background` | Fondo del bloque. Debe resolverse a un color. | `"PathBg"` |
| `PowerlineSymbol` | Glifo separador. Por defecto es ``. | `""` |
| `LeadingDiamond` | Semicírculo de apertura, usado solo en el primer segmento visible. | `""` |
| `TrailingDiamond` | Semicírculo de cierre, usado solo en el último segmento visible. | `""` |
| `PathStyle` | Se establece en `"Folder"` para una ruta de carpeta compacta. | `"Folder"` |

Si un segmento tiene `Background` pero no `Foreground`, el renderizador elige
automáticamente un color ANSI contrastante. Para obtener el mejor resultado,
definir ambos.

---

## 10. Operaciones de tema

### Activar un tema

```powershell
Set-PromptTheme -Name "Catppuccin"
```

### Listar temas registrados

```powershell
Get-PromptThemes | Select-Object -ExpandProperty Name
```

### Obtener detalles del tema activo

```powershell
Get-ActiveTheme
```

### Consultar colores e íconos

Si estás desarrollando un segmento, usa estas funciones auxiliares para
resolver temas dinámicamente:

```powershell
$color = Resolve-ThemeColor -ColorName "Primary"
$icon  = Resolve-ThemeIcon -IconKey "GitDirty"
```

Estas funciones hacen fallback de forma elegante cuando el tema no define una
clave personalizada.

---

## 11. Crear temas personalizados

Hay dos formas compatibles de agregar temas.

### Opción A: archivo de tema integrado

Crea `src/Themes/MiTema.Theme.ps1`. El cargador importa automáticamente todos
los archivos `*.Theme.ps1` de ese directorio, por lo que el tema se registra la
próxima vez que se importa el módulo.

### Opción B: archivo de tema externo

Mantén el tema fuera del repositorio e impórtalo explícitamente:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MiTema.Theme.ps1"
Set-PromptTheme -Name "MiTema"
```

`Import-PromptTheme` también acepta un directorio e importa todos los archivos
`*.Theme.ps1` dentro de él:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes"
```

Agrega esa línea a tu `$PROFILE` después del bootstrap de PPF si quieres que
los temas personalizados estén disponibles en cada sesión.

### Ejemplo de archivo de tema

```powershell
Register-PromptTheme `
    -Name "Sunset" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Red"
        "Secondary"  = "Yellow"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        "Text"      = "#fff4e6"
        "DarkText"  = "#2b1b17"
        "SessionBg" = "#ff8a65"
        "PathBg"    = "#ffd54f"
        "GitBg"     = "#81c784"
        "TimeBg"    = "#ba68c8"
    } `
    -Icons @{
        "Session"  = ""
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Time"     = [string][char]0xF017
    } `
    -Segments @{
        "Session" = @{
            Visible         = $true
            Icon            = "Session"
            Foreground      = "DarkText"
            Background      = "SessionBg"
            LeadingDiamond  = ""
            PowerlineSymbol = ""
        }
        "Path" = @{
            Visible         = $true
            Icon            = "Path"
            Foreground      = "DarkText"
            Background      = "PathBg"
            PathStyle       = "Folder"
            PowerlineSymbol = ""
        }
        "Git" = @{
            Visible         = $true
            IconClean       = "GitClean"
            IconDirty       = "GitDirty"
            Foreground      = "DarkText"
            Background      = "GitBg"
            PowerlineSymbol = ""
        }
        "Time" = @{
            Visible         = $true
            Icon            = "Time"
            Foreground      = "DarkText"
            Background      = "TimeBg"
            TrailingDiamond = ""
            PowerlineSymbol = ""
        }
    }
```

Una copia completa está disponible en
[`examples/Themes/Sunset.Theme.ps1`](../examples/Themes/Sunset.Theme.ps1).

### Reglas del tema

- `Palette` e `Icons` son obligatorios para `Register-PromptTheme`.
- `Segments` es opcional. Declara solo las claves que quieras anular.
- Los valores de `Palette` pueden ser nombres ANSI (`"Cyan"`) o valores
  truecolor hexadecimales (`"#89b4fa"`).
- Usa `Visible = $false` para ocultar un segmento en ese tema.
- Usa `Get-PromptTheme -Name "MiTema"` para inspeccionar el objeto registrado.
- Usa `Import-PromptTheme -PassThru` para devolver los temas agregados por una
  importación.

---

## 12. Importar un tema de Oh My Posh (OMP)

PPF puede importar temas de Oh My Posh (archivos `.omp.json`) a través del
núcleo .NET con `Import-PPFDotNetTheme`. Esta función lee el tema OMP, valida
los segmentos soportados y devuelve la configuración PPF.

```powershell
# Requiere el núcleo .NET (Fase 3C)
$env:PPF_USE_DOTNET_CORE = "1"
Import-Module PablitusPrompt -Force

# Importar y validar sin activar
Import-PPFDotNetTheme -Path "$HOME\Documents\PowerShell\Themes\MiTema.omp.json"

# Importar y activar como tema actual
Import-PPFDotNetTheme -Path "$HOME\Documents\PowerShell\Themes\Pablitus.omp.json" -Activate
```

| Parámetro | Descripción |
| --- | --- |
| `-Path` | Ruta al archivo `.omp.json` (obligatorio). |
| `-IgnoreUnsupported` | Ignora los tipos de segmento que PPF no soporta en lugar de fallar. |
| `-Activate` | Importa y establece el tema como activo en la sesión actual. |

Después de importar con `-Activate`, usa `Set-PromptTheme -Name <nombre>` si
necesitas cambiar de tema explícitamente.

### Requisitos

- `Import-PPFDotNetTheme` requiere que la DLL del núcleo .NET de PPF esté
  disponible (se busca en `PPF_DOTNET_CORE_DLL`, `dotnet/publish` y el
  directorio de salida de `dotnet build`).
- Para temas nativos de PPF usa `Import-PromptTheme` con archivos
  `*.Theme.ps1`.

PPF soporta los siguientes tipos de segmento de OMP: `session`, `path`, `git`,
`text`, `time` y `exit`. Otros tipos (por ejemplo, `aws`, `kubernetes`,
`docker`, `go`, `rust`) se ignoran o requieren `-IgnoreUnsupported`.
