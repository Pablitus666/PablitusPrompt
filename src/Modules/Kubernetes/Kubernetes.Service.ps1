# ============================================================
# Pablitus Prompt Framework (PPF)
# Kubernetes.Service.ps1
# ============================================================

function Get-KubeContext {

    try {
        # On Windows USERPROFILE is authoritative; on Unix use HOME first.
        $homePath = if ([System.OperatingSystem]::IsWindows()) {
            if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
        }
        else {
            if ($HOME) { $HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
        }

        $configPaths = if ($env:KUBECONFIG) {
            $env:KUBECONFIG -split [System.IO.Path]::PathSeparator
        }
        elseif ($homePath) {
            @((Join-Path (Join-Path $homePath ".kube") "config"))
        }
        else {
            @()
        }

        foreach ($configPath in $configPaths) {
            if (-not $configPath -or -not (Test-Path -LiteralPath $configPath)) {
                continue
            }

            $content = Get-Content -LiteralPath $configPath -Raw -ErrorAction SilentlyContinue
            if (-not $content) {
                continue
            }

            $currentContext = $null
            if ($content -match "current-context:\s*([^\s\r\n]+)") {
                $currentContext = $Matches[1]
            }
            $namespace = "default"
            # Simple extraction of namespace if specified in context configurations
            # A context configuration in kubeconfig has name and context fields
            if ($currentContext -and ($content -match "- name:\s*$([regex]::Escape($currentContext))[\s\S]*?namespace:\s*([^\s\r\n]+)")) {
                $namespace = $Matches[1]
            }

            if ($currentContext) {
                return [PSCustomObject]@{
                    Context   = $currentContext
                    Namespace = $namespace
                }
            }
        }
    }
    catch {}
    return $null

}
