# Changelog

## v1.5.0 (Fast Bootstrap) - 2026-10-21

### Added
- **Fast in-memory bootstrap**: `PablitusPrompt.psm1` reads the modular sources in dependency order, concatenates them, and parses them once with `Invoke-Expression`. Module import dropped from roughly 900 ms to roughly 300 ms locally while keeping the source tree modular.
- **Bootstrap mode telemetry**: `$global:PPF_BootstrapMode` reports `Fast` or `Modular`.
- **Compatibility loader**: set `$env:PPF_USE_MODULAR_LOADER = "1"` to force the original per-file loader. Pester/coverage runs select it automatically because Pester instruments files, not in-memory bundles.
- **Hidden-provider skipping**: `$global:PPF_SkipHiddenProviders = $true` avoids running providers whose segment is hidden by the active theme. Visible providers keep the dependencies they need (for example, Python keeps Project data available). Off by default.

### Changed
- `build.ps1` forces the modular loader while running Pester and coverage, then switches back to the fast path for benchmarks.
- README and installation guide document the bootstrap modes and hidden-provider option.

### Quality
- 182 Pester tests passing, 0 failures.
- Code coverage: 91.54% (2695/2944 commands).
- PSScriptAnalyzer: 0 findings with the project settings.

## v1.4.0 (Kali Theme) - 2026-10-20

### Added
- **Kali theme**: green/cyan/yellow palette, Nerd Font icons, `user@host` session output, and a minimal layout that hides Project, Memory, CPU, Battery, Docker, Kubernetes, DotNet, Node, and WSL.
- **`ShowHost` session option**: any theme can render `user@host` by setting `ShowHost = $true` in its `Session` segment configuration.
- The prompt integration examples now include the `$`/`#` indicator and document the Kali theme.

### Changed
- The default theme list now includes Kali in the README, installation guide, architecture notes, theme reference, and roadmap.

## v1.3.1 (Prompt Integration) - 2026-10-20

### Added
- `Import-PromptConfiguration` and `Export-PromptConfiguration` are now part of the public API, so the documented persistence and hot-reload workflow actually works.
- The installation guide and README explain how to replace the PowerShell `prompt` function with PPF.

### Fixed
- Installation documentation no longer references commands that were not exported.

## v1.3.0 (Stability & Coverage) - 2026-10-20

### Added
- **Quality gates**: `PSScriptAnalyzerSettings.psd1` documents the intentional exceptions, and CI now runs PSScriptAnalyzer on every push/PR.
- **Coverage suite**: `tests/Coverage.Memory.Tests.ps1` and `tests/Coverage.Modules.Tests.ps1` add 105 regression tests for memory, CPU, battery, session, git, configuration and the language providers.
- **Deterministic core load order**: `PablitusPrompt.psm1` loads `Core` in an explicit order before falling back to alphabetical discovery.
- **Cross-platform cache directories**: Windows (`LocalApplicationData`), macOS (`~/Library/Caches`), Linux (`XDG_CACHE_HOME`) and a temp fallback.
- **Cross-platform session detection**: Windows identity/administrator detection plus Linux/macOS environment fallbacks.
- **Cross-platform memory providers**: Windows (CIM/WMI/P-Invoke), Linux (`/proc/meminfo`) and macOS (`sysctl`/`vm_stat`).
- **Security**: the HTML renderer escapes segment text before emitting markup.
- **Renderer default**: `Get-PromptString`/`Invoke-PromptRenderer` use the configured renderer when none is passed explicitly.

### Changed
- `PowerShellVersion` in the module manifest is now `7.0`, matching the documented requirement.
- External commands are launched with `ProcessStartInfo.ArgumentList`, preserving argument boundaries.
- Generated `build/` and `benchmarks/benchmark_report.*` artifacts are no longer tracked.

### Fixed
- `Import-PromptConfiguration` no longer mutates a live hashtable while enumerating it.
- Imported segment configuration is preserved after the theme is applied.
- macOS memory usage no longer overflows `Int32` and silently reports 0%.
- `Export-PromptConfiguration` to PSD1 no longer fails when a dictionary contains a `$null` value.
- The coverage gate in `build.ps1` uses the Pester 5.8 API and now fails the build below 90%.
- The test suite runs without pre-importing the module (self-contained discovery).

### Quality
- 177 Pester tests passing, 0 failures.
- Code coverage: 91.33% (2611/2859 commands).
- PSScriptAnalyzer: 0 findings with the project settings.

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