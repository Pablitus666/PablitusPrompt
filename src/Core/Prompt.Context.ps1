# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Context.ps1
# ============================================================

class PromptContext {

    # Session
    [string]$User
    [string]$Host
    [bool]$IsAdmin

    # Location
    [string]$CurrentPath
    [string]$FriendlyPath

    # Project
    [string]$ProjectName
    [string]$ProjectType

    # Git
    [string]$GitBranch
    [bool]$GitDirty

    # Languages
    [string]$PythonVersion
    [string]$NodeVersion
    [string]$DotNetVersion

    # Containers
    [bool]$DockerRunning

    # Environment
    [datetime]$Timestamp

    PromptContext() {

        $this.Timestamp = Get-Date

    }

}