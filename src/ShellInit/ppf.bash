# ============================================================
# Pablitus Prompt Framework (PPF) - Shell init for bash
#
# Source este archivo desde ~/.bashrc o ~/.bash_profile:
#   source /ruta/a/ppf.bash
#
# Requiere pwsh (PowerShell 7+) en PATH.
# ============================================================

if command -v pwsh >/dev/null 2>&1; then
    # Directorio donde reside este script (y ppf.ps1)
    __ppf_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    __ppf_prompt() {
        local prompt
        prompt=$(pwsh -NoProfile -File "$__ppf_dir/ppf.ps1" 2>/dev/null) || return 0
        PS1="$prompt"
    }

    # Precargar PPF una vez al iniciar la sesión
    if [ -z "${PPF_INITIALIZED:-}" ]; then
        pwsh -NoProfile -Command "Import-Module (Join-Path '$__ppf_dir' '..\PablitusPrompt.psd1') -Force" >/dev/null 2>&1 || true
        export PPF_INITIALIZED=1
    fi

    PROMPT_COMMAND='__ppf_prompt; '"${PROMPT_COMMAND}"
fi
