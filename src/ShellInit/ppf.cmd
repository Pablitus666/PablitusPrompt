@echo off
:: ============================================================
:: Pablitus Prompt Framework (PPF) - Shell init for cmd
::
:: Uso: Agregar a tu AutoRun del registro o llamar desde
:: un doskey/macro:
::   for /f "delims=" %p in ('pwsh -NoProfile -File "ruta\a\ppf.ps1"') do @set "PROMPT=%p"
::
:: Requiere pwsh (PowerShell 7+) en PATH.
:: ============================================================

setlocal enabledelayedexpansion

:: Directorio donde reside este script (y ppf.ps1)
set "__ppf_dir=%~dp0"

:: Obtener el prompt de PPF
for /f "delims=" %%p in ('pwsh -NoProfile -File "%__ppf_dir%ppf.ps1" 2^>nul') do (
    set "PROMPT=%%p"
)

:: Imprimir sin salto de línea adicional
<nul set /p "=!PROMPT!"

endlocal
