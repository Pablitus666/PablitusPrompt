# Pablitus Prompt Framework - Guía de inicio rápido

Esta guía te lleva desde la instalación hasta tener un prompt PowerLine
funcionando en tu terminal en pocos minutos.

---

## 1. Requisitos

- **PowerShell 7.0 o superior** (se desarrolla y valida con PowerShell 7.6.7).
- Windows, Linux o macOS.
- Una **Nerd Font** instalada y seleccionada en la terminal (necesaria para los
  glifos y diamantes de PowerLine, por ejemplo `U+F017` del segmento `Time`).
- Git, Node, Python, Docker o Kubernetes son **opcionales**; sus segmentos se
  degradan sin romper el prompt si la herramienta no está instalada.

---

## 2. Instalación

### Desde PowerShell Gallery (recomendado)

```powershell
Install-Module -Name PablitusPrompt -Scope CurrentUser
Import-Module PablitusPrompt -Force
```

Actualizar a una versión más reciente:

```powershell
Update-Module -Name PablitusPrompt
```

### Desde el repositorio (fuente)

```powershell
git clone https://github.com/Pablitus666/PablitusPrompt.git
Import-Module .\PablitusPrompt\src\PablitusPrompt.psd1 -Force
```

O usar el bootstrap:

```powershell
. .\PablitusPrompt\src\Bootstrap.ps1
```

### Verificar la instalación

```powershell
Get-PromptHealth
Get-PromptThemes
Get-PromptProviders
Get-PromptRenderers
```

---

## 3. Elegir y activar un tema

PPF incluye 8 temas oficiales:

```powershell
Set-PromptTheme -Name "Default"
Set-PromptTheme -Name "Nord"
Set-PromptTheme -Name "Dracula"
Set-PromptTheme -Name "Catppuccin"
Set-PromptTheme -Name "Kali"
Set-PromptTheme -Name "Pablitus"
Set-PromptTheme -Name "Pablitus Dark"
Set-PromptTheme -Name "Pablitus Light"
```

En esta guía usamos **Pablitus**, el tema oficial de PPF (PowerLine truecolor
con diamantes y glifo de reloj de Nerd Font):

```powershell
Import-Module PablitusPrompt -Force
Set-PromptTheme -Name "Pablitus"
```

Consulta el tema activo:

```powershell
Get-ActiveTheme
```

---

## 4. Configurar el prompt en $PROFILE

Edita tu perfil de PowerShell (`notepad $PROFILE` o `code $PROFILE`) y agrega
el siguiente bloque, ajustando la ruta si instalaste PPF desde el repositorio:

```powershell
# PPF - Bootstrap y tema
if (Get-Module -ListAvailable PablitusPrompt) {
    Import-Module PablitusPrompt -Force
} elseif (Test-Path "D:\PablitusPrompt\src\Bootstrap.ps1") {
    . "D:\PablitusPrompt\src\Bootstrap.ps1"
}

Set-PromptTheme -Name "Pablitus"

# Evita ejecutar proveedores cuyos segmentos el tema oculta (opcional, más rápido)
$global:PPF_SkipHiddenProviders = $true

function global:prompt {
    try {
        $context = Invoke-Prompt
        Get-PromptString -Context $context -Renderer "PowerLine"
    }
    catch {
        Write-Warning "[PPF] Error al renderizar el prompt: $_"
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
}
```

El `try/catch` garantiza que un fallo de un proveedor, segmento o renderer no
deje la consola sin prompt.

Carga los cambios en la sesión actual:

```powershell
. $PROFILE
```

---

## 5. Funcionalidades avanzadas (Fase 3C)

El núcleo .NET de PPF añade prompt transitorio, tooltips y right prompt. Requiere
opt-in:

```powershell
$env:PPF_USE_DOTNET_CORE = "1"
Import-Module PablitusPrompt -Force
```

| Comando | Descripción |
| --- | --- |
| `Get-PromptString -TerminalWidth 120` | Prompt principal con right prompt compuesto. |
| `Get-PromptString -Transient -TerminalWidth 80` | Prompt simplificado tras aceptar un comando. |
| `Get-PromptTooltip -Command "git" -TerminalWidth 80 -Column 5` | Tooltip right-aligned para la palabra clave `git`. |

---

## 6. Salida esperada

Con el tema **Pablitus** y el renderer `PowerLine`, el prompt se ve
aproximadamente así (los glifos requieren una Nerd Font):

```text
  pablo   PablitusPrompt   main   13:53 
```

El texto exacto depende del tema, del directorio actual, de las herramientas
instaladas y de los segmentos visibles. Por ejemplo, con **Dracula**:

```text
  pablo   src   feature/login   14:02 
```

Si la terminal no soporta truecolor o no tienes una Nerd Font, cambia el
renderer:

```powershell
Get-PromptString -Renderer "ANSI"
# o
Get-PromptString -Renderer "Plain"
```

---

## 7. Siguientes pasos

- Consulta [`docs/Themes.md`](Themes.md) para crear o importar temas personalizados.
- Consulta [`docs/MIGRATION.md`](MIGRATION.md) para migrar temas de Oh My Posh.
- Consulta [`docs/Architecture.md`](Architecture.md) para entender la arquitectura modular de PPF.
