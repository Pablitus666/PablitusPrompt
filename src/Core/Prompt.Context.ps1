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

}

class RuntimeContext {

    [string]$Python
    [string]$Node
    [string]$DotNet

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

    [System.Collections.Generic.List[PromptSegment]]$Segments

    [datetime]$Timestamp

    PromptContext() {

        $this.Session = [SessionContext]::new()
        $this.Path    = [PathContext]::new()
        $this.Project = [ProjectContext]::new()
        $this.Git     = [GitContext]::new()
        $this.Runtime = [RuntimeContext]::new()

        $this.Segments = [System.Collections.Generic.List[PromptSegment]]::new()

        $this.Timestamp = Get-Date

    }

}