# Pablitus Prompt Framework v1.0 — Themes Reference
> **Pablitus Prompt Framework v1.0 Themes Frozen**

Themes in PPF define the color palette and icons that segments use to render themselves.

PPF ships with 5 default themes located in `src/Themes/`:

---

## 1. Default
- **Palette**: Standard basic shell colors (Green, Yellow, Blue, Cyan, Red, White).
- **Icons**: Clean unicode equivalents.

---

## 2. Nord
- **Palette**: Arctic-themed pastel colors. Establishes a calm, dark-blue terminal mood.
- **Icons**: Optimized for Nerd Fonts with glyphs (like Git branch icon, Docker whale, Kubernetes context).

---

## 3. Dracula
- **Palette**: Vibrant, high-contrast dark theme (Magenta for primary, Cyan for secondary, Yellow for dirty state, Green for clean status).
- **Icons**: Distinctive glyph representation.

---

## 4. Catppuccin
- **Palette**: Cute, warm pastel colors (Lavender, Mauve, Peach, Green, Teal).
- **Icons**: Nerd Font glyphs matching the Catppuccin design system.

---

## 5. Kali
- **Palette**: Kali-style terminal colors (Green for the user, Cyan for the path, Yellow for Git and Python, White for regular text).
- **Icons**: Nerd Font glyphs shared with `Default`: user, folder, branch, and language icons.
- **Behavior**: shows `user@host` in the session segment and hides `Project`, `Memory`, `CPU`, `Battery`, `Docker`, `Kubernetes`, `DotNet`, `Node`, and `WSL` for a minimal prompt. `ShowHost` can be enabled independently in any theme's `Session` configuration.

---

## 6. Theme Operations

### Activating a Theme
To change the active theme, run:
```powershell
Set-PromptTheme -Name "Catppuccin"
```

### Retrieving Active Theme Details
To query the currently active theme structure:
```powershell
Get-ActiveTheme
```

### Querying Colors and Icons
If you are developing a segment, use these helper functions to resolve themes dynamically:
```powershell
$color = Resolve-ThemeColor -ColorName "Primary" -Default "White"
$icon  = Resolve-ThemeIcon -IconKey "GitDirty" -Default "!"
```
These functions guarantee that if a theme does not specify a custom value, the framework will fall back gracefully to the provided default.
