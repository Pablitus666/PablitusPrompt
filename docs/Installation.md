# Pablitus Prompt Framework v1.5.0 - Installation Guide

PPF is easy to install: clone the repository, load the bootstrap from your PowerShell profile, and point the `prompt` function at `Get-PromptString`.

---

## 1. Clone the Repository
Clone this repository to a directory of your choice (e.g. `C:\PablitusPrompt` or `~/PablitusPrompt`):
```powershell
git clone https://github.com/Pablitus666/PablitusPrompt.git C:\PablitusPrompt
```

---

## 2. Add to PowerShell Profile
Open your profile file in your editor:
```powershell
notepad $PROFILE
```

Add the following block to the end of the file to bootstrap the framework and use it as your prompt:

```powershell
# Cargar PPF
. C:\PablitusPrompt\src\Bootstrap.ps1

# Tema y colores
Set-PromptTheme -Name "Kali"

# No ejecutar providers cuyos segmentos estan ocultos en el tema
$global:PPF_SkipHiddenProviders = $true

# Reemplazar el prompt de PowerShell por el de PPF
function global:prompt {
    $context = Invoke-Prompt
    $prompt = Get-PromptString -Context $context -Renderer "ANSI"
    $indicator = if ($context.Session.IsAdmin) { "#" } else { "$" }
    $indicatorColor = if ($context.Session.IsAdmin) { "`e[36m" } else { "`e[32m" }
    "$prompt${indicatorColor}${indicator}`e[0m "
}
```

Save and restart your terminal. The prompt is now rendered by PPF.

> If you already use Oh My Posh, the `prompt` function above overrides it. Remove the function (or the whole block) to get the previous prompt back.

### Startup modes

PPF uses a fast in-memory bundle by default. The selected mode is available in
`$global:PPF_BootstrapMode` (`Fast` or `Modular`). To force the compatibility loader
(for example, when Pester needs to instrument every source file):

```powershell
$env:PPF_USE_MODULAR_LOADER = "1"
```

`$global:PPF_SkipHiddenProviders = $true` is optional. It avoids running providers whose
segment is hidden by the active theme, while keeping providers needed by visible segments.

---

## 3. Customizing the Prompt

The renderer and theme can be changed at any time:

```powershell
# Set theme
Set-PromptTheme -Name "Dracula"

# Render with a different output format
Get-PromptString -Renderer "PowerLine"
```

Available renderers: `ANSI`, `HTML`, `JSON`, `Markdown`, `Minimal`, `Plain`, `PowerLine`, `Rich`.
Available themes: `Default`, `Nord`, `Dracula`, `Catppuccin`, `Kali`.

To persist your configuration and reload it automatically when the file changes:

```powershell
Export-PromptConfiguration -Path "$HOME\.ppf.json"
Enable-PromptConfigHotReload -Path "$HOME\.ppf.json"
```

Load a saved configuration at startup with:

```powershell
Import-PromptConfiguration -Path "$HOME\.ppf.json"
```
