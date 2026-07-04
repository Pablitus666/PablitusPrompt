# Pablitus Prompt Framework v1.0 — Roadmap
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

PPF has achieved stable release status v1.0. Below is the progress status and the path forward towards v2.0.

---

## v1.0 — Architecture Frozen & Stable (Completed)
- [x] **Core Architecture**: Solid loading pipeline, event engine, and cache.
- [x] **Provider System**: Decoupled gathering of context info.
- [x] **12 Modularized Providers**: Session, Path, Project, Git, Node, Python, WSL, Docker, Kubernetes, CPU, Memory, Battery.
- [x] **8 Renderers**: Plain, Minimal, JSON, ANSI, PowerLine, Markdown, HTML, Rich.
- [x] **Theme Engine**: Palette and icon mapping for Default, Nord, Dracula, Catppuccin.
- [x] **Configuration Manager**: PSD1/JSON imports, exports, and config hot-reloading.
- [x] **Test Coverage**: Complete integration test suite written in Pester.
- [x] **Consolidated Source**: Removed redundant registries, files, and empty directories.

---

## v2.0 — Expansion & Integration (Planned)

### 1. Ecosistema de Módulos (Marketplace)
- [ ] Command `Install-PromptModule` to install third-party providers/segments from GitHub repositories.
- [ ] Command `Install-PromptTheme` to import community themes.
- [ ] Host a central directory/marketplace registry.

### 2. Inteligencia Artificial (IA Segmentos Inteligentes)
- [ ] Add smart command predictions segment using local or API models.
- [ ] Auto-suggest corrections for command errors.
- [ ] Context-aware prompt detailing active work/tasks.

### 3. Cloud Synchronization
- [ ] Sync prompt profiles, configurations, and stats across terminals.
- [ ] Remotely host configuration templates.
- [ ] Git-backed profile syncing.

### 4. Advanced Integrations
- [ ] Direct telemetry segments for Azure / AWS active profile and regions.
- [ ] VS Code and Neovim integrations to query terminal settings or active editor states.
- [ ] Windows Terminal configuration sync.
