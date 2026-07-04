# ============================================================
# Pablitus Prompt Framework (PPF)
# Docker.Service.ps1
# ============================================================

function Test-DockerActive {

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        $result = docker ps --format "{{.ID}}" -ErrorAction SilentlyContinue 2>$null
        return $true
    }
    catch {
        return $false
    }

}

function Get-DockerRunningContainers {

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return 0
    }

    try {
        $containers = docker ps -q 2>$null
        if ($containers) {
            return @($containers).Count
        }
    }
    catch {}
    return 0

}
