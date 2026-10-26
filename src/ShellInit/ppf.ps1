# ============================================================
# Pablitus Prompt Framework (PPF)
# Shell init entry point - ppf.ps1
#
# Entry point usado por los scripts de inicialización de shells
# no-PowerShell (bash, zsh, fish, cmd) para obtener el prompt
# de PPF a través de pwsh.
#
# Uso desde bash/zsh:
#   __ppf_prompt() { pwsh -NoProfile -File /ruta/a/ppf.ps1; }
#   PS1='$(__ppf_prompt) '
#
# Uso desde fish:
#   function fish_prompt
#       pwsh -NoProfile -File /ruta/a/ppf.ps1 | read -l prompt
#       echo -n "$prompt"
#   end
#
# Uso desde cmd:
#   @pwsh -NoProfile -File "ruta\a\ppf.ps1"
# ============================================================

[CmdletBinding()]
param(
    [string]$ThemePath,

    [int]$TerminalWidth = 0,

    [switch]$NoColor
)

$ErrorActionPreference = 'Stop'

# Ruta al manifiesto del módulo PPF (misma carpeta que este script, un nivel arriba)
$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "PablitusPrompt.psd1"
if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    # Fallback: buscar en ubicaciones comunes
    $candidates = @(
        Join-Path $PSScriptRoot "..\PablitusPrompt.psd1",
        Join-Path $env:PPF_InstallRoot "PablitusPrompt.psd1",
        (Get-Item $PSScriptRoot).Parent.FullName + "\PablitusPrompt.psd1"
    )
    $modulePath = ($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)
    if (-not $modulePath) {
        Write-Error "PPF module manifest not found. Set PPF_InstallRoot or place ppf.ps1 next to PablitusPrompt.psd1."
        exit 1
    }
}

# Importar el módulo PPF
Import-Module -LiteralPath $modulePath -Force -ErrorAction Stop

# Activar el núcleo .NET si el entorno lo solicita y hay tema configurado
if ($env:PPF_USE_DOTNET_CORE -eq "1" -and $ThemePath) {
    try {
        Enable-PPFDotNetCore -ThemePath $ThemePath -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning "No se pudo activar el núcleo .NET: $($_.Exception.Message)"
    }
}

# Obtener el prompt
$prompt = Get-PromptString -TerminalWidth $TerminalWidth

if ($NoColor) {
    # Eliminar secuencias ANSI para shells que no las soportan
    $prompt = $prompt -replace '\u001b\[[0-9;]*[a-zA-Z]', ''
}

if ($prompt) {
    # Escribir sin salto de línea para que el shell lo use como PS1
    $null = [Console]::Write($prompt)
}
