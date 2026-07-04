# Pablitus Prompt Framework v1.0 — Architecture Guide
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

The Pablitus Prompt Framework (PPF) is designed around a single core philosophy: **Collect information once, render it anywhere.** 

To achieve this, the architecture completely decouples data gathering (Providers) from visual representation (Renderers). The two layers communicate exclusively through a shared context object (`PromptContext`).

---

## 1. High-Level Flow Diagram

The following diagram illustrates the lifecycle of a prompt execution, from PowerShell invocation to the rendered prompt string:

```mermaid
graph TD
    PS([PowerShell Prompt Loop]) --> Boot[Bootstrap.ps1]
    Boot --> LoadCore[Load Core Engine]
    Boot --> LoadConfig[Load Configurations]
    Boot --> LoadUtils[Load Helper Utilities]
    Boot --> InitModules[Initialize Modules]
    Boot --> LoadThemes[Load Themes]
    Boot --> LoadRenderers[Load Renderers]
    
    PS2([Get-PromptString]) --> InvP[Invoke-Prompt]
    InvP --> HotReload[Test-PromptConfigReload]
    InvP --> EvBefore[Event: BeforeRender]
    InvP --> NewCtx[New-PromptContext]
    
    NewCtx --> RunProv[Invoke-PromptProviders]
    RunProv --> RunPipe[Invoke-PPFPipeline]
    RunPipe --> RunSeg[Invoke-PromptSegments]
    
    RunSeg --> EvAfter[Event: AfterRender]
    EvAfter --> Render[Invoke-PromptRenderer]
    Render --> Out([Rendered Prompt String])
```

---

## 2. Bootstrapping & Load Order

When PPF is loaded (typically via `Bootstrap.ps1` in the user's profile), it loads the files in the following order:

1. **`Core/`**: Loads types, classes (`PromptContext`, `PromptSegment`), and core engines (Module Loader, Registry, Pipeline, Events, Cache, Rendering).
2. **`Configuration/`**: Defines default configurations (`Default.Configuration.ps1`) and Config Manager (`ConfigManager.ps1`) for imports, exports, and hot-reloading.
3. **`Utils/`**: Loads cross-cutting helper functions (e.g., `Command.Utils.ps1`).
4. **`Modules/`**: Discovers and imports modules. Each module is loaded in a specific order:
   - **Providers** (`*.Provider.ps1`): Registers context gathers.
   - **Services** (`*.Service.ps1`): Business logic and command wrappers.
   - **Segments** (`*.Segment.ps1`): Visual logic and segment registration.
5. **`Themes/`**: Loads default themes (`Default`, `Catppuccin`, `Dracula`, `Nord`).
6. **`Renderers/`**: Loads available prompt renderers.

---

## 3. Lifecycle & Execution Pipeline

Every time PowerShell queries the prompt string (usually via the global `prompt` function), the following lifecycle occurs:

### Phase 1: Context Initialization
1. **Config Hot-Reload Check**: PPF checks if the configuration file has changed on disk. If so, it reloads it.
2. **BeforeRender Event**: Custom listeners registered to `BeforeRender` are executed.
3. **Context Instantiation**: A new instance of `PromptContext` is created.

### Phase 2: Pipeline Execution
1. **Providers Invocation**: Each registered provider runs in order of priority. Providers execute commands (e.g., `git status`, `kubectl config`) and populate their respective properties in the `PromptContext` (e.g., `$Context.Git`, `$Context.Docker`).
2. **Pipeline Middleware**: Post-processing steps (like profiling execution times) execute and add metadata to the context.

### Phase 3: Segment Registration
1. **Segments Resolution**: PPF evaluates registered segments. If a segment's visibility condition is met, a `PromptSegment` object is created and added to the `$Context.Segments` list.

### Phase 4: Rendering
1. **AfterRender Event**: Custom listeners registered to `AfterRender` are executed.
2. **Renderer Selection**: The active renderer (e.g., `PowerLine`, `ANSI`, `JSON`) receives the populated `PromptContext` and transforms it into the final string.

---

## 4. Key Architectural Rules

- **Zero Output during Gathering**: Providers must never output anything directly to the console or write color codes. They only save raw data to the context.
- **Renderers are Stateless**: Renderers must not call external executables or query environment states. They rely solely on the data inside the `PromptContext` and the active theme settings.
- **Priority-Driven**: Both Providers and Segments are ordered by a `Priority` integer. Lower numbers execute/render first.
