# Pablitus Prompt Framework (PPF)

> **Build once. Render anywhere.**

PPF is a modular framework for building intelligent PowerShell prompts.

Instead of mixing business logic with rendering, PPF separates the prompt into independent components.

```
Providers
     │
     ▼
 PromptContext
     │
     ▼
  Pipeline
     │
     ▼
 Renderer
```

---

# Architecture

```
src/

 Core/
     Prompt.Context.ps1
     Prompt.Registry.ps1
     Prompt.Pipeline.ps1
     Prompt.Core.ps1

 Providers/
     Session/
     Path/
     Project/
     Git/

 Renderers/
     OhMyPosh/

 Themes/

 Utils/
```

---

# Features

- Modular Provider architecture
- Independent Prompt Context
- Provider Pipeline
- Renderer abstraction
- Oh My Posh integration
- Native renderer (planned)
- Git support
- Project detection
- Language detection
- Docker support
- Kubernetes support

---

# Project Status

Current Version

```
v0.2.0-dev
```

---

# Roadmap

- Core Framework ✅
- Provider System ✅
- Git Provider 🚧
- Native Renderer 🚧
- Theme Engine 🚧

---

# Philosophy

PPF follows a simple idea.

Collect information once.

Render it anywhere.

Providers never render.

Renderers never collect data.

Everything communicates through a single PromptContext.

---

Created by Pablo