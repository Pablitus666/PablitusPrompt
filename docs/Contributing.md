# Contributing to Pablitus Prompt Framework (PPF)
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

Thank you for contributing to PPF! As we have frozen the v1.0 architecture, we follow a strict process to maintain API stability and avoid regressions.

---

## 1. Principles of Contribution
- **Public API Preservation**: The public functions defined in [docs/API.md](file:///I:/PablitusPrompt/docs/API.md) cannot be modified or removed. Only additive or internal performance improvements are allowed.
- **Strict Decoupling**: Ensure new features are either new modules (consisting of Provider, Service, and Segment) or custom Renderers. Never mix rendering code into Providers.
- **Testing Required**: All features and bug fixes must have corresponding Pester tests added to [tests/Prompt.Tests.ps1](file:///I:/PablitusPrompt/tests/Prompt.Tests.ps1).
- **Code Standards**: Follow the conventions defined in [docs/DeveloperGuide.md](file:///I:/PablitusPrompt/docs/DeveloperGuide.md) (Standardized file headers, CamelCase variable names, try-catch handlers).

---

## 2. Pull Request Workflow

### Step 1: Clone and Branch
Clone the repository and create a feature branch off of the `main` branch:
```powershell
git checkout -b feature/your-awesome-feature
```

### Step 2: Implement and Format
Implement your changes following the developer guide. Ensure your files have the proper license headers:
```powershell
# ============================================================
# Pablitus Prompt Framework (PPF)
# <YourFileName>.ps1
# ============================================================
```

### Step 3: Run the Test Suite
Ensure all tests pass before making a pull request. Tests must be executed using PowerShell Core (`pwsh`):
```powershell
pwsh -ExecutionPolicy Bypass -Command "Invoke-Pester -Path tests/Prompt.Tests.ps1"
```

### Step 4: Submit PR
Push to your fork and submit a Pull Request describing:
- What changes were made.
- Why they are needed.
- Demonstration that the test suite passes successfully.
