# Pablitus Prompt Framework (PPF) v1.0
> **Build once. Render anywhere.**
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

PPF is a modular, high-performance, extension-friendly framework for building intelligent PowerShell prompts. 

Instead of mixing shell-querying logic with ANSI color formatting, PPF separates the prompt lifecycle into independent components:

```
    [Providers] (Gather Environment Data)
         │
         ▼
  [PromptContext] (Central State Container)
         │
         ▼
  [Pipeline Steps] (Post-processors / Middleware)
         │
         ▼
  [PromptSegments] (Visual Components Resolution)
         │
         ▼
     [Renderer] (Stateless Formatter)
```

---

## Documentation

To learn more about PPF, refer to the official documentation guides:

- 🏗️ [Architecture Guide](file:///I:/PablitusPrompt/docs/Architecture.md): Deep-dive into boot order, execution pipelines, and lifecycle phases.
- 🔌 [API Reference](file:///I:/PablitusPrompt/docs/API.md): Documentation of the stable public and internal functions.
- 🚀 [Developer SDK Guide](file:///I:/PablitusPrompt/docs/SDK.md): Learn how to build custom modules, segments, renderers, and themes.
- 💻 [Developer Guide](file:///I:/PablitusPrompt/docs/DeveloperGuide.md): Coding standards, testing protocols, and debugging tips.
- 📦 [Installation Guide](file:///I:/PablitusPrompt/docs/Installation.md): Sourcing the bootstrap file and profile integration.
- 🎨 [Themes Reference](file:///I:/PablitusPrompt/docs/Themes.md): Colors and icons of the default themes.
- 📊 [Providers Reference](file:///I:/PablitusPrompt/docs/Providers.md): Details on the 12 built-in providers.
- 🔍 [Renderers Reference](file:///I:/PablitusPrompt/docs/Renderers.md): Formats supported (PowerLine, JSON, ANSI, Rich, HTML, etc.).
- 🗺️ [Roadmap](file:///I:/PablitusPrompt/docs/Roadmap.md): Future expansion plans for PPF v2.0.
- 🤝 [Contributing Guidelines](file:///I:/PablitusPrompt/docs/Contributing.md): How to submit pull requests on the frozen v1.0 codebase.

---

## Core Features

- **Decoupled Architecture**: Providers never print output; Renderers never query state.
- **12 Built-in Providers**: Session, Path, Project, Git, Node, Python, WSL, Docker, Kubernetes, CPU, Memory, and Battery.
- **8 Built-in Renderers**: Plain, Minimal, JSON, ANSI, PowerLine, Markdown, HTML, and Rich.
- **4 Beautiful Themes**: Default, Nord, Dracula, and Catppuccin.
- **Robust Caching**: Built-in memory and disk cache for slow terminal utilities (like Git or Kubernetes lookups).
- **Configuration Hot-Reload**: Automatically detects profile changes on disk and reloads configuration.
- **Event Hooks**: Extend functionality dynamically using events like `BeforeRender`, `AfterRender`, or `ThemeChanged`.

---

## Quick Start

Open your PowerShell profile file (`$PROFILE`) and import the bootstrap script:
```powershell
. C:\PablitusPrompt\src\Bootstrap.ps1
```

Set the theme and test output:
```powershell
Set-PromptTheme -Name "Nord"
Get-PromptString -Renderer "Rich"
```

---

Created by Pablo