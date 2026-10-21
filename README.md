# Pablitus Prompt Framework (PPF) v1.3.1
> Modular PowerShell prompt framework for PowerShell 7+

Pablitus Prompt Framework (PPF) is a modular framework for building prompts in PowerShell 7.
It separates data collection, context assembly, middleware, segment construction, theme resolution,
and rendering into distinct layers.

## Overview

```text
Import-Module
  -> PablitusPrompt.psd1
  -> PablitusPrompt.psm1
  -> Core
  -> Configuration
  -> Utils
  -> Modules
  -> Themes
  -> Renderers
  -> Public API
```

The runtime flow is:

```text
Invoke-Prompt
  -> New-PromptContext
  -> Providers
  -> Pipeline
  -> Segments
  -> Renderer
  -> Get-PromptString
```

## Features

- 13 built-in providers: Session, WSL, Path, Project, Git, Docker, Python, Node, DotNet, Kubernetes, Battery, CPU, Memory
- 13 built-in segments
- 8 built-in renderers: Plain, Minimal, JSON, ANSI, PowerLine, Markdown, HTML, Rich
- 4 built-in themes: Default, Nord, Dracula, Catppuccin
- Memory and disk cache
- Configuration import/export and hot reload
- Event hooks for `BeforeRender`, `AfterRender`, `ThemeChanged`, `ConfigurationChanged`, and `ModuleLoaded`
- CPU sampler with runspace-backed background collection
- Git repository watcher support

## Requirements

- PowerShell 7.0 or later
- Windows, Linux, or macOS

## Installation

Import the module manifest:

```powershell
Import-Module .\src\PablitusPrompt.psd1 -Force
```

Or bootstrap it from the helper script:

```powershell
. .\src\Bootstrap.ps1
```

## Quick Start

```powershell
Import-Module .\src\PablitusPrompt.psd1 -Force

Set-PromptTheme -Name "Nord"

$context = Invoke-Prompt
$prompt  = Get-PromptString -Context $context

$prompt
```

## Use as your PowerShell Prompt

Add this block to your `$PROFILE` (adjust the path to your clone):

```powershell
. C:\PablitusPrompt\src\Bootstrap.ps1
Set-PromptTheme -Name "Nord"

function global:prompt {
    Get-PromptString -Renderer "ANSI"
}
```

Open a new terminal and PPF will render your prompt. Remove the function to go back to the previous prompt.

## Public API

Common entry points:

- `Get-Prompt`
- `Invoke-Prompt`
- `Get-PromptString`
- `New-PromptContext`
- `Get-PromptProviders`
- `Get-PromptSegments`
- `Get-PromptRenderers`
- `Get-PromptThemes`
- `Get-PromptTheme`
- `Get-ActiveTheme`
- `Set-PromptTheme`
- `Measure-Prompt`
- `Measure-PromptDetailed`
- `Test-PromptFramework`

## Architecture

PPF is organized into these layers:

- `Core`: prompt lifecycle, registry, cache, events, telemetry, rendering
- `Configuration`: prompt configuration, defaults, import/export, hot reload
- `Modules`: providers, services, and segments for each capability
- `Themes`: palettes, icons, and segment defaults
- `Renderers`: output formats
- `Utils`: command execution helpers
- `Profile`: optional shell profile integration
- `Tests`: regression and integration coverage

## Notes

- `Get-PromptRenderer` is an internal helper used by the rendering pipeline.
- `PromptContext` is defined in `src/Core/Prompt.Context.ps1` and is loaded before any API that references it.
- The `build/` directory contains packaged artifacts and may lag behind `src/` if a fresh build has not been generated.

## Testing

```powershell
Import-Module .\src\PablitusPrompt.psd1 -Force
Invoke-Pester -Path .\tests
```

Static analysis (project settings document the intentional exceptions):

```powershell
Invoke-ScriptAnalyzer -Path .\src -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

Build and release (tests, coverage gate >= 90%, benchmarks, API docs, package):

```powershell
pwsh -File .\build.ps1
```

## Documentation

- `docs/Architecture.md`
- `docs/API.md`
- `docs/SDK.md`
- `docs/DeveloperGuide.md`
- `docs/Installation.md`
- `docs/Themes.md`
- `docs/Providers.md`
- `docs/Renderers.md`
- `docs/Roadmap.md`
- `docs/Contributing.md`

## License

See `LICENSE`.
