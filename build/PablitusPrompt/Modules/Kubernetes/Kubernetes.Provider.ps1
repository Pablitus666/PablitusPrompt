# ============================================================
# Pablitus Prompt Framework (PPF)
# Kubernetes.Provider.ps1
# ============================================================

function Invoke-KubernetesProvider {

    param(
        [PromptContext]$Context
    )

    $cacheKey = "KubeContext"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Kubernetes.Context   = $cached.Context
        $Context.Kubernetes.Namespace = $cached.Namespace
    }
    else {
        $kube = Get-KubeContext
        $data = if ($kube) {
            $kube
        }
        else {
            [pscustomobject]@{
                Context   = ""
                Namespace = ""
            }
        }
        $Context.Kubernetes.Context   = $data.Context
        $Context.Kubernetes.Namespace = $data.Namespace
        Set-PPFCache -Key $cacheKey -Value $data -TtlSeconds 10
    }

}

Register-PromptProvider `
    -Name "Kubernetes" `
    -Priority 600 `
    -Script ${function:Invoke-KubernetesProvider}
