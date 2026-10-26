# Pablitus Prompt Framework - Themes Reference

Themes in PPF define the color palette, icons, and per-segment overrides that
segments use to render themselves. A theme only declares overrides; switching
themes restores the baseline segment configuration first, so hidden segments or
icons never leak between themes.

PPF ships with 5 built-in themes in `src/Themes/`. The built-in PowerLine themes
use the Nerd Font clock glyph (`U+F017`) for the `Time` segment.

---

## 1. Default
- **Palette**: standard ANSI colors (Cyan, Blue, Green, Yellow, Magenta, Red).
- **Icons**: clean Unicode/Nerd Font equivalents.
- **Renderer**: ANSI-oriented baseline. It still works with PowerLine through
  the renderer's foreground-to-background fallback, but does not define
  truecolor blocks.

---

## 2. Nord
- **Palette**: official Nord palette (Polar Night, Snow Storm, Frost and Aurora).
- **PowerLine**: truecolor blocks for Session, Project, Path, Git, Python, Node,
  Time and the optional runtime/telemetry segments.
- **Layout**: frost-blue session block, compact Polar Night path block,
  Git/Python/Node accents and a diamond-closed yellow time block. Uses light text
  on the darker Session/Path blocks and dark text on the Aurora/Frost accents.
  Project and the telemetry blocks are hidden by default to keep the layout
  compact; they still have colors if you enable them.
- **Renderer**: best used with `Get-PromptString -Renderer "PowerLine"`.

---

## 3. Dracula
- **Palette**: official Dracula truecolor palette: `#44475a` session, `#6272a4`
  path, `#ffb86c` Git, `#8be9fd` Node, `#ff79c6` time, `#f8f8f2` text and
  `#282a36` dark text.
- **Layout**: Powerline blocks with a leading session diamond and a trailing time
  diamond, matching the Oh My Posh Dracula theme. Session and Path use light text;
  Git, Node and Time use dark text for stronger contrast.
- **Renderer**: best used with `Get-PromptString -Renderer "PowerLine"`.
- **Behavior**: shows Session, Path, Git, Node and Time. Hides `Project`,
  `Python`, `Docker`, `WSL`, `Battery`, `CPU`, `Memory`, `Kubernetes` and
  `DotNet` to keep the official Dracula silhouette.

---

## 4. Catppuccin
- **Palette**: Catppuccin Mocha (Mauve, Blue, Peach, Yellow, Green and Surface
  tones).
- **PowerLine**: truecolor blocks with a dark Surface path block and pastel
  accent blocks for Session, Git, Python, Node and Time.
- **Layout**: mauve session diamond, compact dark folder path, Git/Python/Node
  accents and a diamond-closed blue time block. Uses dark text on the pastel
  accents and light text on the dark path block. Project and the telemetry blocks
  are hidden by default; they still have colors if you enable them.
- **Renderer**: best used with `Get-PromptString -Renderer "PowerLine"`.

---

## 5. Kali
- **Palette**: Kali-style terminal colors (green session, dark cyan path, amber
  Git, orange Python and purple time) with truecolor PowerLine blocks.
- **Icons**: Nerd Font glyphs shared with `Default`. The Time segment uses the
  Nerd Font clock icon (`U+F017`).
- **Behavior**: shows `user@host` in the session segment and hides `Project`,
  `Memory`, `CPU`, `Battery`, `Docker`, `Kubernetes`, `DotNet`, `Node`, and
  `WSL` for a minimal prompt. `ShowHost` can be enabled independently in any
  theme's `Session` configuration.
- **Renderer**: best used with `Get-PromptString -Renderer "PowerLine"`.

---

## 6. PowerLine Theme Contract

For a theme to render polished PowerLine blocks, each visible segment override
should define:

| Key | Purpose | Example |
| --- | --- | --- |
| `Foreground` | Text color. Use a palette key or a `#rrggbb` value. | `"Text"` |
| `Background` | Block background. Must resolve to a color. | `"PathBg"` |
| `PowerlineSymbol` | Separator glyph. Defaults to ``. | `""` |
| `LeadingDiamond` | Opening half-circle, used only on the first visible segment. | `""` |
| `TrailingDiamond` | Closing half-circle, used only on the last visible segment. | `""` |
| `PathStyle` | Set to `"Folder"` for a compact leaf-folder path. | `"Folder"` |

If a segment has a `Background` but no `Foreground`, the renderer chooses a
contrasting ANSI color automatically. For the best result, define both.

---

## 7. Theme Operations

### Activating a theme
```powershell
Set-PromptTheme -Name "Catppuccin"
```

### Listing registered themes
```powershell
Get-PromptThemes | Select-Object -ExpandProperty Name
```

### Retrieving active theme details
```powershell
Get-ActiveTheme
```

### Querying colors and icons
If you are developing a segment, use these helper functions to resolve themes
dynamically:

```powershell
$color = Resolve-ThemeColor -ColorName "Primary"
$icon  = Resolve-ThemeIcon -IconKey "GitDirty"
```

These functions fall back gracefully when a theme does not define a custom key.

---

## 8. Creating Custom Themes

There are two supported ways to add themes.

### Option A: Built-in theme file
Create `src/Themes/MyTheme.Theme.ps1`. The loader automatically imports every
`*.Theme.ps1` file in that directory, so the theme is registered the next time
the module is imported.

### Option B: External theme file
Keep the theme outside the repository and import it explicitly:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes\MyTheme.Theme.ps1"
Set-PromptTheme -Name "MyTheme"
```

`Import-PromptTheme` also accepts a directory and imports every
`*.Theme.ps1` file inside it:

```powershell
Import-PromptTheme -Path "$HOME\Documents\PowerShell\Themes"
```

Add that line to your `$PROFILE` after the PPF bootstrap if you want custom
themes available in every session.

### Theme file example
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

A complete copy is available at
[`examples/Themes/Sunset.Theme.ps1`](../examples/Themes/Sunset.Theme.ps1).

### Theme rules
- `Palette` and `Icons` are mandatory for `Register-PromptTheme`.
- `Segments` is optional. Only declare the keys you want to override.
- Palette values may be ANSI names (`"Cyan"`) or truecolor hex values
  (`"#89b4fa"`).
- Use `Visible = $false` to hide a segment for that theme.
- Use `Get-PromptTheme -Name "MyTheme"` to inspect the registered object.
- Use `Import-PromptTheme -PassThru` to return the themes added by an import.
