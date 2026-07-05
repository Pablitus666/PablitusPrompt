# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Context.ps1
# ============================================================

class SessionContext {

    [string]$User
    [string]$Host
    [bool]$IsAdmin

}

class PathContext {

    [string]$Current
    [string]$Friendly

}

class ProjectContext {

    [string]$Name
    [string]$Type
    [string]$Root
    [string]$Icon

}

class GitContext {

    [bool]$IsRepository
    [string]$Branch
    [bool]$Dirty
    [int]$Ahead
    [int]$Behind
    [bool]$Detached
    [string]$Root

}

class RuntimeContext {

    [string]$Python
    [string]$Node
    [string]$DotNet

}

class DockerContext {

    [bool]$Active
    [int]$RunningContainers

}

class WslContext {

    [bool]$IsWsl
    [string]$Distro

}

class BatteryContext {

    [int]$Percentage
    [string]$Status

}

class CpuContext {

    [int]$Usage

}

class MemoryContext {

    [int]$Usage

}

class KubernetesContext {

    [string]$Context
    [string]$Namespace

}

class PromptSegment {

    [string]$Name
    [string]$Text
    [string]$Icon
    [string]$Foreground
    [string]$Background
    [bool]$Visible = $true

}

class PromptContext {

    [SessionContext]$Session
    [PathContext]$Path
    [ProjectContext]$Project
    [GitContext]$Git
    [RuntimeContext]$Runtime
    [DockerContext]$Docker
    [WslContext]$Wsl
    [BatteryContext]$Battery
    [CpuContext]$Cpu
    [MemoryContext]$Memory
    [KubernetesContext]$Kubernetes

    [System.Collections.Generic.List[PromptSegment]]$Segments

    [datetime]$Timestamp
    [hashtable]$Metrics

    PromptContext() {

        $this.Session    = [SessionContext]::new()
        $this.Path       = [PathContext]::new()
        $this.Project    = [ProjectContext]::new()
        $this.Git        = [GitContext]::new()
        $this.Runtime    = [RuntimeContext]::new()
        $this.Docker     = [DockerContext]::new()
        $this.Wsl        = [WslContext]::new()
        $this.Battery    = [BatteryContext]::new()
        $this.Cpu        = [CpuContext]::new()
        $this.Memory     = [MemoryContext]::new()
        $this.Kubernetes = [KubernetesContext]::new()

        $this.Segments = [System.Collections.Generic.List[PromptSegment]]::new()

        $this.Timestamp = Get-Date
        $this.Metrics = @{}

    }

}