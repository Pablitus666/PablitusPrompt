# Pablitus Prompt Framework v1.0 — Developer Guide
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

This guide covers coding standards, conventions, the testing framework, and workflow procedures for developing on the Pablitus Prompt Framework (PPF).

---

## 1. Coding Style & Standards

To maintain readability and consistency across the framework, all code contributions must comply with these standards:

### Standardized File Headers
Every file must start with a standardized header block containing the framework name, file name, and separator lines:
```powershell
# ============================================================
# Pablitus Prompt Framework (PPF)
# <FileName>.ps1
# ============================================================
```

### Formatting Conventions
- **Indentation**: Use 4 spaces for indentation (no tabs).
- **Naming Case**: Use `PascalCase` for variables, function names, classes, properties, and parameters.
- **Function Naming**: Always use standard PowerShell `Verb-Noun` syntax (e.g., `Get-PromptString`, `Register-PromptSegment`). Avoid non-standard verbs.
- **Spaces & Newlines**: Keep spaces around operators and braces. Use clean spacing between parameter blocks and function logic to ensure code is highly readable.

### Error Handling
- Never let exceptions bubble up to the main PowerShell console during prompt generation.
- Use `try-catch` blocks around commands in Services/Providers that could fail (e.g., when git command is not found or when running in a directory without permissions).
- Silent failure is preferred over cluttering the user's shell screen:
```powershell
try {
    # run command
}
catch {
    Write-Verbose "[PPF] Error: $_"
}
```

---

## 2. Test Suite (Pester)

PPF uses the Pester testing framework for testing integrations, renderers, cache mechanisms, themes, configuration exports, and events.

### Test Location
All tests are defined in the `tests/` directory:
- [Prompt.Tests.ps1](file:///I:/PablitusPrompt/tests/Prompt.Tests.ps1): This contains regression, integration, pipeline, theme, config, event, and cache tests.

### Running Tests
To run tests, always use PowerShell Core (`pwsh`) to ensure correct parsing of UTF-8 strings.
The module must be imported before `Invoke-Pester` because the suite uses `InModuleScope`:
```powershell
pwsh -ExecutionPolicy Bypass -Command "Import-Module ./src/PablitusPrompt.psd1 -Force; Invoke-Pester -Path ./tests"
```

Static analysis (uses the project settings, which document intentional exceptions):
```powershell
pwsh -ExecutionPolicy Bypass -Command "Invoke-ScriptAnalyzer -Path ./src -Recurse -Settings ./PSScriptAnalyzerSettings.psd1"
```

### Adding Tests
When you create a new module, renderer, or core capability, you must add corresponding tests to `Prompt.Tests.ps1` inside the appropriate `Context` block.

---

## 3. Configuration Management & Hot-Reloading
- Default configuration is defined in `src/Configuration/10.Default.Configuration.ps1`.
- When changes are made, ConfigManager (`src/Configuration/20.ConfigManager.ps1`) writes JSON/PSD1 and validates configuration.
- The `Test-PromptConfigReload` function checks the file write times on each prompt execution. If the config has been updated, it automatically reloads it into memory. Keep logic in this function extremely lightweight.
