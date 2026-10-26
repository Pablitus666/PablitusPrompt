# ============================================================
# Pablitus Prompt Framework (PPF) - Shell init for zsh
#
# Source este archivo desde ~/.zshrc:
#   source /ruta/a/ppf.zsh
#
# Requiere pwsh (PowerShell 7+) en PATH.
# ============================================================

if command -v pwsh >/dev/null 2>&1; then
    # Directorio donde reside este script (y ppf.ps1)
    __ppf_dir="$(cd "$(dirname "${(%):-%x}")" && pwd)"

    __ppf_prompt() {
        local prompt
        prompt=$(pwsh -NoProfile -File "$__ppf_dir/ppf.ps1" 2>/dev/null) || return 0
        print -n - "$prompt"
    }

    # Precargar PPF una vez al iniciar la sesión
    if [[ -z "${PPF_INITIALIZED:-}" ]]; then
        pwsh -NoProfile -Command "Import-Module (Join-Path '$__ppf_dir' '..\PablitusPrompt.psd1') -Force" >/dev/null 2>&1 || true
        export PPF_INITIALIZED=1
    fi

    precmd() {
        PS1="$(__ppf_prompt)"
    }
fi
