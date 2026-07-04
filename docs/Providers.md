# Pablitus Prompt Framework v1.0 — Providers Reference
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

Providers gather information from the current operating system, shell state, or active directory, and populate the `PromptContext` for renderers to consume.

PPF v1.0 includes 12 modularized providers:

---

## 1. Session Provider
- **Module Directory**: `src/Modules/Session/`
- **Gathers**: Environment details such as current username, hostname, OS type, shell type, and whether the shell has elevated privileges (Admin/root).
- **Properties**: `$Context.Session`

---

## 2. Path Provider
- **Module Directory**: `src/Modules/Path/`
- **Gathers**: The current working directory, relative path from home directory, and path shortening logic.
- **Properties**: `$Context.Path`

---

## 3. Project Provider
- **Module Directory**: `src/Modules/Project/`
- **Gathers**: Active software project detection. Identifies project type (e.g. Node, Python, Rust, Go, .NET) based on lockfiles, config files, or directory structures.
- **Properties**: `$Context.Project`

---

## 4. Git Provider
- **Module Directory**: `src/Modules/Git/`
- **Gathers**: Git repository status, active branch name, commit hash (full and short), state (dirty/clean), untracked files, and ahead/behind counts.
- **Properties**: `$Context.Git`

---

## 5. Python Provider
- **Module Directory**: `src/Modules/Python/`
- **Gathers**: Active virtual environment (virtualenv/conda) name and path, and the system Python executable version.
- **Properties**: `$Context.Runtime.Python`

---

## 6. Node Provider
- **Module Directory**: `src/Modules/Node/`
- **Gathers**: Node.js runtime version, active npm/pnpm package details if in a node project folder.
- **Properties**: `$Context.Runtime.Node`

---

## 7. Docker Provider
- **Module Directory**: `src/Modules/Docker/`
- **Gathers**: Docker daemon connection status and number of currently running containers.
- **Properties**: `$Context.Docker`

---

## 8. WSL Provider
- **Module Directory**: `src/Modules/WSL/`
- **Gathers**: Checks if PowerShell is running inside a WSL instance and retrieves the WSL distribution name.
- **Properties**: `$Context.Wsl`

---

## 9. Battery Provider
- **Module Directory**: `src/Modules/Battery/`
- **Gathers**: Current system battery charge percentage, charging status (AC/Battery/Charged).
- **Properties**: `$Context.Battery`

---

## 10. CPU Provider
- **Module Directory**: `src/Modules/CPU/`
- **Gathers**: Overall CPU utilization percentage.
- **Properties**: `$Context.Cpu`

---

## 11. Memory Provider
- **Module Directory**: `src/Modules/Memory/`
- **Gathers**: Total system memory, free memory, and percentage of memory utilization.
- **Properties**: `$Context.Memory`

---

## 12. Kubernetes Provider
- **Module Directory**: `src/Modules/Kubernetes/`
- **Gathers**: Active Kubernetes context name, namespace, and server connection status.
- **Properties**: `$Context.Kubernetes`
