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

class PromptContext {

    [SessionContext]$Session
    [PathContext]$Path
    [ProjectContext]$Project
    [GitContext]$Git

    [datetime]$Timestamp

    PromptContext() {

        $this.Session = [SessionContext]::new()
        $this.Path = [PathContext]::new()
        $this.Project = [ProjectContext]::new()
        $this.Git = [GitContext]::new()

        $this.Timestamp = Get-Date

    }

}