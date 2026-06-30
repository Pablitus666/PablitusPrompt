# ============================================
# Pablitus Prompt - PowerShell Profile
# ============================================

# Ruta del tema
$Theme = "$HOME\Documents\PowerShell\Themes\Pablitus.omp.json"

# Inicializar Oh My Posh
if (Test-Path $Theme) {
    oh-my-posh init pwsh --config $Theme | Invoke-Expression
}

# Terminal Icons
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Alias útiles
Set-Alias ll Get-ChildItem

function touch {
    param($File)
    New-Item -ItemType File -Path $File -Force | Out-Null
}