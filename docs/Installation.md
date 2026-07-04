# Pablitus Prompt Framework v1.0 — Installation Guide
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

PPF is easy to install. Just clone the repository and source the bootstrap file from your PowerShell profile.

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

Add the following line to the end of the file to bootstrap the framework automatically on terminal startup:
```powershell
. C:\PablitusPrompt\src\Bootstrap.ps1
```

Save and restart your terminal.

---

## 3. Customizing the Prompt
By default, the active renderer is `Plain`. You can change this by adding setting variables or using the configuration commands:
```powershell
# Set theme
Set-PromptTheme -Name "Dracula"

# Get active prompt string
Get-PromptString -Renderer "PowerLine"
```
You can also generate your config file to enable hot-reloading:
```powershell
Export-PromptConfiguration -Path "$HOME\.ppf.json"
Enable-PromptConfigHotReload -Path "$HOME\.ppf.json"
```
