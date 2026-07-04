# Changelog

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