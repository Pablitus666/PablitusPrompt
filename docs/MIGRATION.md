# Migración de temas de Oh My Posh a PPF

Esta guía explica cómo migrar un tema de [Oh My Posh](https://ohmyposh.dev)
(`.omp.json`) a Pablitus Prompt Framework (PPF). PPF puede importar temas OMP a
través de su importador `OmpThemeImporter` (expuesto desde PowerShell como
`Import-PPFDotNetTheme`) y también permite convertir un tema OMP a un tema nativo
de PPF (`.Theme.ps1`).

PPF soporta los siguientes tipos de segmento de OMP: **`session`, `path`, `git`,
`text`, `time` y `exit`**. Otros tipos (`aws`, `kubernetes`, `docker`, `go`,
`rust`, etc.) no son nativos de PPF y requieren `-IgnoreUnsupported` para no
interrumpir la importación.

---

## 1. Importar un archivo .omp.json con OmpThemeImporter

Desde PowerShell, el importador OMP se invoca con `Import-PPFDotNetTheme`.
Requiere el núcleo .NET de PPF (Fase 3C) y su DLL compilada.

```powershell
# 1. Activar el núcleo .NET
$env:PPF_USE_DOTNET_CORE = "1"
Import-Module PablitusPrompt -Force

# 2. Importar y validar el tema OMP sin activarlo
$config = Import-PPFDotNetTheme -Path "$HOME\Documents\PowerShell\Themes\MiTema.omp.json"

# 3. Importar y activar como tema actual de la sesión
Import-PPFDotNetTheme -Path "$HOME\Documents\PowerShell\Themes\MiTema.omp.json" -Activate
```

| Parámetro | Descripción |
| --- | --- |
| `-Path` | Ruta al archivo `.omp.json` (obligatorio). |
| `-IgnoreUnsupported` | Ignora tipos de segmento no soportados en lugar de fallar. |
| `-Activate` | Importa y establece el tema como activo en la sesión. |

El valor devuelto es la configuración PPF del tema (`$config`), que se puede
inspeccionar antes de activarlo. Para hacer el cambio persistente, agrega la
importación a tu `$PROFILE`.

**Requisito:** la DLL del núcleo .NET debe estar disponible (se busca en
`PPF_DOTNET_CORE_DLL`, `dotnet/publish` y el directorio de salida de
`dotnet build`). Compílala con:

```powershell
dotnet build dotnet/PablitusPrompt.sln -c Release
```

---

## 2. Ejemplo: tema OMP → tema PPF .Theme.ps1

### Tema de origen (Oh My Posh)

`MiTema.omp.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 3,
  "final_space": true,
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "session",
          "style": "plain",
          "foreground": "#8AE234",
          "template": "┌──({{ .UserName }}㉿{{ .HostName }})"
        },
        {
          "type": "path",
          "style": "plain",
          "foreground": "#E5C07B",
          "properties": {
            "style": "agnoster"
          },
          "template": "-[{{ .Path }}]"
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "foreground": "#8AE234",
          "template": "└─$ "
        }
      ]
    }
  ]
}
```

### Tema equivalente nativo de PPF

`MiTema.Theme.ps1` (registrado con `Register-PromptTheme`):

```powershell
Register-PromptTheme `
    -Name "MiTema" `
    -Palette @{
        Background   = "Black"
        Foreground   = "White"
        Primary      = "#8AE234"
        Secondary    = "#E5C07B"
        Success      = "Green"
        Warning      = "Yellow"
        Error        = "Red"
        SessionFg    = "#8AE234"
        PathFg       = "#E5C07B"
    } `
    -Icons @{
        Session     = ""
        Path        = ""
        PromptSymbol = "$"
    } `
    -Segments @{
        Session = @{
            Visible      = $true
            Icon         = "Session"
            Foreground   = "#8AE234"
            Background   = "Background"
            Style        = "plain"
            Template     = "┌──({{ .UserName }}㉿{{ .HostName }})"
        }
        Path = @{
            Visible      = $true
            Icon         = "Path"
            Foreground   = "#E5C07B"
            Background   = "Background"
            Style        = "plain"
            Template     = "-[{{ .Path }}]"
        }
        TextPrompt = @{
            Visible      = $true
            Foreground   = "#8AE234"
            Background   = "Background"
            Style        = "plain"
            Template     = "└─$ "
        }
    }
```

Importar y activar:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MiTema.Theme.ps1"
Set-PromptTheme -Name "MiTema"
```

---

## 3. Diferencias entre formato OMP (.omp.json) y formato PPF

| Aspecto | Oh My Posh (`.omp.json`) | PPF nativo (`.Theme.ps1`) | PPF declarativo (`.ppf.json`) |
| --- | --- | --- | --- |
| **Registro** | Archivo JSON con versión 3 | `Register-PromptTheme` en PowerShell | JSON cargado por el núcleo .NET |
| **Paleta** | Colores por segmento (`foreground`, `background`) | Hashtable `Palette` con claves con nombre | Sección `palette` del JSON |
| **Íconos** | Propiedad `icon` / glifos inline | Hashtable `Icons` con claves con nombre | Sección `icons` del JSON |
| **Segmentos** | Array de bloques con `type` y `segments` | Hashtable `Segments` con anulación por nombre | Bloques y segmentos JSON |
| **Estilo** | `plain`, `powerline`, `plain-diamond`, etc. | `Style` por segmento (`plain`, `powerline`) | `style` por bloque/segmento |
| **Diamantes** | `leading_diamond`, `trailing_diamond` | `LeadingDiamond`, `TrailingDiamond` | `leadingDiamond`, `trailingDiamond` |
| **Prompt transitorio** | `transient_prompt` | No aplicable (solo núcleos .NET) | `transientPrompt` |
| **Right prompt** | Bloque `type: "rprompt"` | No aplicable (solo núcleos .NET) | Bloque `type: "rprompt"` |
| **Tooltips** | `tooltips` + `tooltips_action` | No aplicable (solo núcleos .NET) | `tooltips`, `tooltipsAction` |
| **Sustitución de plantillas** | `{{ .Propiedad }}` | `{{ .Propiedad }}` en `Template` | `{{ .Propiedad }}` |
| **Ejecución** | Binario de Go de Oh My Posh | Motor PowerShell de PPF | Núcleo .NET de PPF |

### Estructura de un archivo `.Theme.ps1`

```powershell
Register-PromptTheme `
    -Name "Nombre" `
    -Palette @{ ... } `
    -Icons @{ ... } `
    -Segments @{ ... }
```

- `Palette` e `Icons` son obligatorias.
- `Segments` es opcional: solo anula los segmentos que quieres personalizar.

### Estructura de un archivo `.ppf.json` (núcleo .NET)

```json
{
  "name": "MiTema",
  "renderer": "powerline",
  "palette": { "Background": "#1e1e2e", "Foreground": "#cdd6f4", ... },
  "transientPrompt": { "template": "...", "right_template": "...", ... },
  "tooltips": [ { "tips": ["git"], "template": "...", ... } ],
  "tooltipsAction": "extend",
  "blocks": [ { "type": "prompt", "alignment": "left", "segments": [ ... ] } ]
}
```

---

## 4. Características de OMP soportadas y no soportadas en PPF

### Tipos de segmento soportados

| Tipo OMP | Soporte en PPF | Notas |
| --- | --- | --- |
| `session` | Sí | Usuario, host y elevación. |
| `path` | Sí | Directorio actual, ruta abreviada y carpeta. |
| `git` | Sí | Rama, estado sucio, ahead/behind. |
| `text` | Sí | Texto estático o plantilla libre. |
| `time` | Sí | Reloj con glifo `U+F017` (Nerd Font). |
| `exit` | Sí | Código de salida del último comando. |

### Tipos de segmento NO soportados (requieren `-IgnoreUnsupported`)

`aws`, `azure`, `kubernetes`, `docker`, `go`, `java`, `node`, `python`, `ruby`,
`rust`, `dotnet`, `battery`, `wsl`, `cpu`, `memory`, entre otros. PPF implementa
estos segmentos con sus propios proveedores nativos, pero no se mapean
automáticamente desde la definición OMP al importar.

### Otras características de OMP

| Característica | Estado en PPF |
| --- | --- |
| `transient_prompt` (`template`, `right_template`, `filler`, `newline`, `foreground`, `background`) | Soportado en el núcleo .NET (`Get-PromptString -Transient`). |
| `tooltips` + `tooltips_action` (`replace`, `extend`, `prepend`) | Soportado en el núcleo .NET (`Get-PromptTooltip`). |
| `rprompt` / right prompt con `filler` y `overflow` (`hide`, `break`) | Soportado en el núcleo .NET con `-TerminalWidth`. |
| `final_space` | Ignorado; PPF gestiona el espacio final por renderer. |
| `blocks` con `newline` | Soportado en `.ppf.json`; no se aplica a `.Theme.ps1`. |
| Propiedades de segmento OMP (`properties.style`, etc.) | Mapeadas parcialmente; revisar tras la importación. |

### Flujo de migración recomendado

1. Importa el tema OMP con `Import-PPFDotNetTheme -Path <archivo>.omp.json` e
   inspecciona el resultado.
2. Usa `-IgnoreUnsupported` si el tema contiene segmentos que PPF no soporta.
3. Para un tema permanente y nativo, crea un archivo `*.Theme.ps1` con
   `Register-PromptTheme` basado en la paleta y los segmentos del tema OMP.
4. Importa el tema nativo con `Import-PromptTheme` y actívalo con
   `Set-PromptTheme`.
5. Agrega la importación a tu `$PROFILE` para conservar el tema entre sesiones.
