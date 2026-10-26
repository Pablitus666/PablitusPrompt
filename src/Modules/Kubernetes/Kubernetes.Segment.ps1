# ============================================================
# Pablitus Prompt Framework (PPF)
# Kubernetes.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Kubernetes" `
    -Priority 800 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Kubernetes.Context) {
            return $null
        }

        $icon = Resolve-ThemeIcon -IconKey "Kubernetes"
        if (-not $icon) { $icon = "⎈" }

        New-PromptSegment `
            -Name "Kubernetes" `
            -Text "$($Context.Kubernetes.Context) ($($Context.Kubernetes.Namespace))" `
            -Icon $icon

    }
