# Pablitus Prompt Framework v1.5.0 — API Reference Guide
> **Pablitus Prompt Framework v1.5.0 API Documentation**

This document describes the official public API and core internal APIs of the Pablitus Prompt Framework (PPF).

---

## 1. Public API
These functions represent the stable public interface of PPF. They will not have breaking signature changes in any v1.x release.

### `Clear-AllPPFCache`
- **Synopsis**: 
Clear-AllPPFCache 


### `Clear-PPFCache`
- **Synopsis**: 
Clear-PPFCache [-Key] <string> [<CommonParameters>]


### `Disable-PPFDotNetCore`
- **Synopsis**: 
Disable-PPFDotNetCore [<CommonParameters>]


### `Disable-PromptConfigHotReload`
- **Synopsis**: 
Disable-PromptConfigHotReload 


### `Enable-PPFDotNetCore`
- **Synopsis**: 
Enable-PPFDotNetCore [-ThemePath] <string> [-IgnoreUnsupported] [<CommonParameters>]


### `Enable-PromptConfigHotReload`
- **Synopsis**: 
Enable-PromptConfigHotReload [-Path] <string> [<CommonParameters>]


### `Export-PromptConfiguration`
- **Synopsis**: 
Export-PromptConfiguration [-Path] <string> [<CommonParameters>]


### `Get-ActiveTheme`
- **Synopsis**: 
Get-ActiveTheme 


### `Get-PPFCache`
- **Synopsis**: 
Get-PPFCache [-Key] <string> [-UseDisk] [<CommonParameters>]


### `Get-PPFDotNetCoreStatus`
- **Synopsis**: 
Get-PPFDotNetCoreStatus 


### `Get-Prompt`
- **Synopsis**: 
Get-Prompt [[-Context] <PromptContext>]


### `Get-PromptConfiguration`
- **Synopsis**: 
Get-PromptConfiguration 


### `Get-PromptHealth`
- **Synopsis**: 
Get-PromptHealth [<CommonParameters>]


### `Get-PromptProviders`
- **Synopsis**: 
Get-PromptProviders 


### `Get-PromptRenderers`
- **Synopsis**: 
Get-PromptRenderers 


### `Get-PromptSegments`
- **Synopsis**: 
Get-PromptSegments [[-Context] <PromptContext>] [<CommonParameters>]


### `Get-PromptString`
- **Synopsis**: 
Get-PromptString [[-Context] <PromptContext>] [[-Renderer] <string>] [[-CommandLine] <string>] [[-TerminalWidth] <int>] [[-Column] <int>] [-Transient]


### `Get-PromptTheme`
- **Synopsis**: 
Get-PromptTheme [[-Name] <string>]


### `Get-PromptThemes`
- **Synopsis**: 
Get-PromptThemes 


### `Get-PromptTooltip`
- **Synopsis**: 
Get-PromptTooltip [-Command] <string> [[-TerminalWidth] <int>] [[-Column] <int>] [-NoColor] [<CommonParameters>]


### `Get-SegmentConfiguration`
- **Synopsis**: 
Get-SegmentConfiguration [-Name] <string> [<CommonParameters>]


### `Import-PPFDotNetTheme`
- **Synopsis**: 
Import-PPFDotNetTheme [-Path] <string> [-IgnoreUnsupported] [-Activate] [<CommonParameters>]


### `Import-PromptConfiguration`
- **Synopsis**: 
Import-PromptConfiguration [-Path] <string> [<CommonParameters>]


### `Import-PromptTheme`
- **Synopsis**: 
Import-PromptTheme [-Path] <string[]> [-PassThru] [<CommonParameters>]


### `Initialize-PPFModules`
- **Synopsis**: 
Initialize-PPFModules [[-ModulesPath] <string>]


### `Invoke-PPFEvent`
- **Synopsis**: 
Invoke-PPFEvent [-EventName] <string> [[-EventArguments] <Object>] [<CommonParameters>]


### `Invoke-PPFPipeline`
- **Synopsis**: 
Invoke-PPFPipeline [[-Context] <PromptContext>]


### `Invoke-Prompt`
- **Synopsis**: 
Invoke-Prompt 


### `Measure-BatteryProvider`
- **Synopsis**: 
Measure-BatteryProvider [[-Iterations] <int>] [-Cold]


### `Measure-CpuProvider`
- **Synopsis**: 
Measure-CpuProvider [[-Iterations] <int>] [-Cold]


### `Measure-DockerProvider`
- **Synopsis**: 
Measure-DockerProvider [[-Iterations] <int>] [-Cold]


### `Measure-DotNetProvider`
- **Synopsis**: 
Measure-DotNetProvider [[-Iterations] <int>] [-Cold]


### `Measure-GitProvider`
- **Synopsis**: 
Measure-GitProvider [[-Iterations] <int>] [-Cold]


### `Measure-KubernetesProvider`
- **Synopsis**: 
Measure-KubernetesProvider [[-Iterations] <int>] [-Cold]


### `Measure-MemoryProvider`
- **Synopsis**: 
Measure-MemoryProvider [[-Iterations] <int>] [-Cold]


### `Measure-NodeProvider`
- **Synopsis**: 
Measure-NodeProvider [[-Iterations] <int>] [-Cold]


### `Measure-PathProvider`
- **Synopsis**: 
Measure-PathProvider [[-Iterations] <int>] [-Cold]


### `Measure-ProjectProvider`
- **Synopsis**: 
Measure-ProjectProvider [[-Iterations] <int>] [-Cold]


### `Measure-Prompt`
- **Synopsis**: 
Measure-Prompt [[-Renderer] <string>] [<CommonParameters>]


### `Measure-PromptCacheComparison`
- **Synopsis**: 
Measure-PromptCacheComparison [[-Iterations] <int>] [<CommonParameters>]


### `Measure-PromptDetailed`
- **Synopsis**: 
Measure-PromptDetailed [[-Renderer] <string>] [[-ExportDir] <string>] [[-Iterations] <int>] [<CommonParameters>]


### `Measure-PromptProvider`
- **Synopsis**: 
Measure-PromptProvider [-Name] <string> [[-Iterations] <int>] [-Cold] [<CommonParameters>]


### `Measure-PythonProvider`
- **Synopsis**: 
Measure-PythonProvider [[-Iterations] <int>] [-Cold]


### `Measure-SessionProvider`
- **Synopsis**: 
Measure-SessionProvider [[-Iterations] <int>] [-Cold]


### `Measure-WslProvider`
- **Synopsis**: 
Measure-WslProvider [[-Iterations] <int>] [-Cold]


### `New-PromptContext`
- **Synopsis**: 
New-PromptContext 


### `New-PromptSegment`
- **Synopsis**: 
New-PromptSegment [-Name] <string> [-Text] <string> [[-Icon] <string>] [[-Foreground] <string>] [[-Background] <string>] [<CommonParameters>]


### `Register-PPFEventListener`
- **Synopsis**: 
Register-PPFEventListener [-EventName] <string> [-Script] <scriptblock> [<CommonParameters>]


### `Register-PPFPipelineStep`
- **Synopsis**: 
Register-PPFPipelineStep [-Name] <string> [[-Priority] <int>] [-Script] <scriptblock> [<CommonParameters>]


### `Register-PromptProvider`
- **Synopsis**: 
Register-PromptProvider [-Name] <string> [[-Priority] <int>] [[-Script] <scriptblock>] [<CommonParameters>]


### `Register-PromptRenderer`
- **Synopsis**: 
Register-PromptRenderer [-Name] <string> [-Script] <scriptblock> [<CommonParameters>]


### `Register-PromptSegment`
- **Synopsis**: 
Register-PromptSegment [-Name] <string> [[-Priority] <int>] [-Script] <scriptblock> [<CommonParameters>]


### `Register-PromptTheme`
- **Synopsis**: 
Register-PromptTheme [-Name] <string> [-Palette] <hashtable> [-Icons] <hashtable> [[-Segments] <hashtable>] [<CommonParameters>]


### `Resolve-ThemeColor`
- **Synopsis**: 
Resolve-ThemeColor [[-ColorName] <string>]


### `Resolve-ThemeIcon`
- **Synopsis**: 
Resolve-ThemeIcon [[-IconKey] <string>]


### `Set-PPFCache`
- **Synopsis**: 
Set-PPFCache [-Key] <string> [-Value] <Object> [[-TtlSeconds] <int>] [-UseDisk] [<CommonParameters>]


### `Set-PPFLogLevel`
- **Synopsis**: 
Set-PPFLogLevel [[-Level] <string>]


### `Set-PromptConfiguration`
- **Synopsis**: 
Set-PromptConfiguration [[-Configuration] <PromptConfiguration>]


### `Set-PromptTheme`
- **Synopsis**: 
Set-PromptTheme [-Name] <string> [<CommonParameters>]


### `Set-SegmentConfiguration`
- **Synopsis**: 
Set-SegmentConfiguration [-Name] <string> [-Configuration] <hashtable> [<CommonParameters>]


### `Test-PPFDotNetCoreAvailable`
- **Synopsis**: 
Test-PPFDotNetCoreAvailable [-Refresh] [<CommonParameters>]


### `Test-PromptFramework`
- **Synopsis**: 
Test-PromptFramework [-RunTests] [<CommonParameters>]


### `Write-PPFLog`
- **Synopsis**: 
Write-PPFLog [-Level] <string> [-Message] <string> [<CommonParameters>]


