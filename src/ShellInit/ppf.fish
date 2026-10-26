# ============================================================
# Pablitus Prompt Framework (PPF) - Shell init for fish
#
# Source este archivo desde ~/.config/fish/config.fish:
#   source /ruta/a/ppf.fish
#
# Requiere pwsh (PowerShell 7+) en PATH.
# ============================================================

if command -q pwsh
    # Directorio donde reside este script (y ppf.ps1)
    set -l __ppf_dir (dirname (status --filename))

    function fish_prompt
        pwsh -NoProfile -File "$__ppf_dir/ppf.ps1" 2>/dev/null | read -lz prompt
        or return
        echo -n -s "$prompt"
    end

    # Precargar PPF una vez al iniciar la sesión
    if not set -q PPF_INITIALIZED
        pwsh -NoProfile -Command "Import-Module (Join-Path '$__ppf_dir' '..\PablitusPrompt.psd1') -Force" >/dev/null 2>&1 || true
        set -gx PPF_INITIALIZED 1
    end
end
