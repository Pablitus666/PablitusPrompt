# Changelog

## v1.2.0 (Hardening & Optimization) - 2026-07-04

### Added
- **Build & Release Automation**: Created `build.ps1` to automate Pester tests, code coverage validation, dynamic API documentation generation, performance benchmarks, and module packaging.
- **Observability Framework**:
  - Added `Get-PromptHealth` to show system metrics (Runspaces, caches, active providers, themes, memory).
  - Added `Test-PromptFramework` for automatic diagnostic self-testing of all subsystems.
  - Dynamic logging levels (`Set-PPFLogLevel`) with debug, trace, info, warn, and error levels.
- **Latency Histogram & Box Plots**: Implemented percentile measurements (P95, P99), outlier detection, ASCII box plots, and cumulative distribution curves.
- **Individual Benchmarks**: Unified statistical analysis engine across all providers via commands like `Measure-CpuProvider`, `Measure-MemoryProvider`, etc.
- **Soak & Stress Tests**: Added suite of automated stability validation scripts: `SoakRender.ps1` (100k renders), `SoakCpuSampler.ps1` (hours execution), and `StressModules.ps1` (1000 module lifecycle cycles).

### Changed
- **PowerShell Core Support**: Patched static `[Runspace]::GetRunspaces()` method usage to `Get-Runspace` cmdlet and added null-checks for `$MyInvocation.MyCommand.Module` during `OnRemove` events, ensuring compatibility with PS v7.5+.
- **OrderedDictionary Compatibility**: Replaced `.ContainsKey` calls with `.Contains` on `$global:PPF_ProviderCacheStats` and git watchers to support `OrderedDictionary` types in PowerShell Core.

### Fixed
- Fixed memory leakage verification in SoakRender by forcing Garbage Collection (`[GC]::Collect()`) before sampling final process memory.
- Corrected scope qualifier syntax error in `StressModules.ps1` warning message block.

## v1.0.0 (Architecture Frozen) - 2026-07-04

### Added
- **Complete Documentation Suite**: Created guides for `Architecture.md`, `API.md`, `SDK.md`, `DeveloperGuide.md`, `Installation.md`, `Providers.md`, `Renderers.md`, and `Themes.md`.
- **Modo YOLO Consolidation**: Resolved all outstanding technical debt and successfully declared the v1.0 architecture frozen.

### Changed
- **Removed Duplicate Code**:
  - Eliminated duplicate `Register-PromptProvider` definition in `src/Core/Prompt.Registry.ps1`.
  - Eliminated duplicate `Register-PromptRenderer` and `Invoke-PromptRenderer` definitions in `src/Renderers/Prompt.Renderer.Registry.ps1`.
  - Eliminated duplicate `Get-PromptString` definition in `src/Core/Prompt.Core.ps1`, consolidating it inside `src/Core/Prompt.Rendering.ps1`.
- **Cleaned Up Workspace**:
  - Deleted 0-byte helper files: `OhMyPosh.Renderer.ps1`, `FileSystem.Utils.ps1`, and `String.Utils.ps1`.
  - Cleaned up empty folders: `src/Contracts`, `src/Templates`, `src/Installer`, `src/Scripts`, `scripts`, `installer`, `tests/Core`, and `tests/Providers`.
  - Re-routed root documentation files (`README.md`, `ROADMAP.md`, `CONTRIBUTING.md`) to the consolidated `docs/` subdirectory.

### Fixed
- Fixed UTF-8 character loading issues in testing script by declaring `pwsh` as the standard test execution shell.