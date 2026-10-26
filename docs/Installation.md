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
Set-PromptTheme -Name "Dracula"

# No ejecutar providers cuyos segmentos estan ocultos en el tema
$global:PPF_SkipHiddenProviders = $true

# Reemplazar el prompt de PowerShell por el de PPF
function global:prompt {
    try {
        $context = Invoke-Prompt
        Get-PromptString -Context $context -Renderer "PowerLine"
    }
    catch {
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
}
```

> `Dracula`, `Nord`, `Catppuccin` and `Kali` are designed for the `PowerLine`
> renderer. They use truecolor (24-bit) blocks and require a Nerd Font for the
> powerline and diamond glyphs. `Default` remains the ANSI-oriented baseline.

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

### Custom themes

Create a `.Theme.ps1` file with a `Register-PromptTheme` call and import it:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MyTheme.Theme.ps1"
Set-PromptTheme -Name "MyTheme"
```

You can also import a directory, which loads every `*.Theme.ps1` file inside it:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes"
```

Add the import line to your `$PROFILE` after the bootstrap. Built-in theme files
are loaded automatically from `src/Themes/`. See
[Themes](Themes.md#8-creating-custom-themes) and
[`examples/Themes/Sunset.Theme.ps1`](../examples/Themes/Sunset.Theme.ps1).

To persist your configuration and reload it automatically when the file changes:

```powershell
Export-PromptConfiguration -Path "$HOME\.ppf.json"
Enable-PromptConfigHotReload -Path "$HOME\.ppf.json"
```

Load a saved configuration at startup with:

```powershell
Import-PromptConfiguration -Path "$HOME\.ppf.json"
```

---

## 4. Troubleshooting

### "Bootstrap.ps1 cannot be loaded because it is not digitally signed"

Files downloaded as a ZIP carry the Mark of the Web and are blocked by the
`RemoteSigned` execution policy. Unblock the repository once:

```powershell
Get-ChildItem C:\PablitusPrompt -Recurse -File | Unblock-File
```

Then restart PowerShell. Cloning with `git clone` does not add the Mark of the
Web, so this step is only needed for ZIP downloads.

### The prompt does not change

PPF is a library: importing the module does not replace PowerShell's `prompt`
function by itself. Make sure your profile defines it **after** any other prompt
manager (Oh My Posh, Starship, etc.):

```powershell
function global:prompt {
    try {
        $context = Invoke-Prompt
        Get-PromptString -Context $context -Renderer "PowerLine"
    }
    catch {
        # Un fallo de PPF nunca debe dejar la consola sin prompt.
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    }
}
```

If you use Oh My Posh, either remove its `oh-my-posh init ... | Invoke-Expression`
line or define the PPF `prompt` function after it so PPF wins.
