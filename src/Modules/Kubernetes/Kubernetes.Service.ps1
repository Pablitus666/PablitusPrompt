# ============================================================
# Pablitus Prompt Framework (PPF)
# Kubernetes.Service.ps1
# ============================================================

function Get-KubeContext {

    try {
        $configPath = "$env:USERPROFILE\.kube\config"
        if (Test-Path $configPath) {
            $content = Get-Content -Path $configPath -Raw -ErrorAction SilentlyContinue
            if ($content) {
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
    }
    catch {}
    return $null

}
