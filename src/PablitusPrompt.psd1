@{
    ModuleVersion = '1.3.0'
    GUID = 'bf7aeb6a-3aab-4860-8fb5-04f4e43940ad'
    Author = 'Pablitus'
    CompanyName = 'Pablitus'
    Copyright = '(c) Pablitus. All rights reserved.'
    Description = 'Pablitus Prompt Framework (PPF)'
    PowerShellVersion = '7.0'
    RootModule = 'PablitusPrompt.psm1'
    
    FunctionsToExport = @(
        "Get-Prompt",
        "Invoke-Prompt",
        "Get-PromptString",
        "New-PromptContext",
        "Initialize-PPFModules",
        "Register-PPFPipelineStep",
        "Invoke-PPFPipeline",
        "Get-PromptProviders",
        "Get-PromptSegments",
        "Get-PromptRenderers",
        "Get-PromptThemes",
        "Get-PromptTheme",
        "Get-ActiveTheme",
        "Set-PromptTheme",
        "Measure-Prompt",
        "Measure-PromptDetailed",
        "Test-PromptFramework",
        "Measure-CpuProvider",
        "Measure-MemoryProvider",
        "Measure-BatteryProvider",
        "Measure-GitProvider",
        "Measure-DockerProvider",
        "Measure-KubernetesProvider",
        "Measure-NodeProvider",
        "Measure-PythonProvider",
        "Measure-SessionProvider",
        "Measure-ProjectProvider",
        "Measure-PathProvider",
        "Measure-WslProvider",
        "Measure-DotNetProvider",
        "Measure-PromptCacheComparison",
        "Measure-PromptProvider",
        "Get-PromptHealth",
        "Set-SegmentConfiguration",
        "Get-SegmentConfiguration",
        "Resolve-ThemeColor",
        "Resolve-ThemeIcon",
        "New-PromptSegment",
        "Register-PromptSegment",
        "Register-PromptProvider",
        "Get-PromptConfiguration",
        "Set-PromptConfiguration",
        "Register-PromptRenderer",
        "Register-PromptTheme",
        "Enable-PromptConfigHotReload",
        "Disable-PromptConfigHotReload",
        "Register-PPFEventListener",
        "Invoke-PPFEvent",
        "Set-PPFCache",
        "Get-PPFCache",
        "Clear-PPFCache",
        "Clear-AllPPFCache",
        "Write-PPFLog",
        "Set-PPFLogLevel"
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
