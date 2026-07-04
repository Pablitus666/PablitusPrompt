# Pablitus Prompt Framework v1.0 — API Reference Guide
> **Pablitus Prompt Framework v1.0 API Frozen**

This document describes the official public API and core internal APIs of the Pablitus Prompt Framework (PPF).

---

## 1. Public API
These functions represent the stable public interface of PPF. They will not have breaking signature changes in any v1.x release.

### `Get-Prompt`
- **Description**: Returns the list of registered segments currently populated in the prompt context.
- **Syntax**: `Get-Prompt [[-Context] <PromptContext>]`
- **Output**: `[PromptSegment[]]`

### `Get-PromptString`
- **Description**: Compiles and renders the prompt into a final string using the specified renderer.
- **Syntax**: `Get-PromptString [[-Context] <PromptContext>] [[-Renderer] <string>]`
- **Output**: `[string]`

### `Invoke-Prompt`
- **Description**: Runs the complete lifecycle (hot reload check, before-render event, providers, pipeline steps, segment generation, after-render event) and returns the completed context.
- **Syntax**: `Invoke-Prompt`
- **Output**: `[PromptContext]`

### `New-PromptContext`
- **Description**: Creates a blank context object containing placeholders for all module data.
- **Syntax**: `New-PromptContext`
- **Output**: `[PromptContext]`

### `Get-PromptConfiguration`
- **Description**: Retrieves the current global configuration object.
- **Syntax**: `Get-PromptConfiguration`
- **Output**: `[PromptConfiguration]`

### `Set-PromptConfiguration`
- **Description**: Overwrites the global configuration object.
- **Syntax**: `Set-PromptConfiguration [-Configuration] <PromptConfiguration>`
- **Output**: `None`

### `Register-PromptRenderer`
- **Description**: Registers a custom renderer.
- **Syntax**: `Register-PromptRenderer [-Name] <string> [-Script] <scriptblock>`
- **Output**: `None`

### `Register-PromptSegment`
- **Description**: Registers a visual segment with priority and a visibility/render script block.
- **Syntax**: `Register-PromptSegment [-Name] <string> [-Priority] <int> [-Script] <scriptblock>`
- **Output**: `None`

### `Register-PromptTheme`
- **Description**: Registers a visual theme containing colors and icons.
- **Syntax**: `Register-PromptTheme [-Name] <string> [-Theme] <hashtable>`
- **Output**: `None`

### `Set-PromptTheme`
- **Description**: Activates a registered theme.
- **Syntax**: `Set-PromptTheme [-Name] <string>`
- **Output**: `None`

---

## 2. Internal Core API
These functions are used by the framework core. They may be refactored or updated in minor releases, but are documented here for transparency.

### `Initialize-PPFModules`
- **Description**: Scans the modules folder, loading providers, services, and segments in the correct order.
- **Syntax**: `Initialize-PPFModules [[-ModulesPath] <string>]`

### `Register-PromptProvider`
- **Description**: Registers a context provider. Used by modules.
- **Syntax**: `Register-PromptProvider [-Name] <string> [-Priority] <int> [-Script] <scriptblock>`

### `Invoke-PromptProviders`
- **Description**: Executes all registered providers against the active context.
- **Syntax**: `Invoke-PromptProviders [-Context] <PromptContext>`

### `Register-PPFPipelineStep`
- **Description**: Adds a middleware step to the post-provider pipeline.
- **Syntax**: `Register-PPFPipelineStep [-Name] <string> [-Priority] <int> [-Script] <scriptblock>`

### `Invoke-PPFPipeline`
- **Description**: Runs all pipeline middleware.
- **Syntax**: `Invoke-PPFPipeline [-Context] <PromptContext>`

### `Get-PPFCache` / `Set-PPFCache`
- **Description**: Core caching mechanism for slow provider operations. Supports memory and disk caching.
- **Syntax**: 
  - `Get-PPFCache [-Key] <string> [-UseDisk]`
  - `Set-PPFCache [-Key] <string> [-Value] <any> [-TtlSeconds <int>] [-UseDisk]`

### `Register-PPFEventListener` / `Invoke-PPFEvent`
- **Description**: Simplistic event dispatcher for hooks (e.g. `BeforeRender`, `AfterRender`, `ThemeChanged`).
- **Syntax**: 
  - `Register-PPFEventListener [-EventName] <string> [-Script] <scriptblock>`
  - `Invoke-PPFEvent [-EventName] <string> [-EventArgs] <any>`
