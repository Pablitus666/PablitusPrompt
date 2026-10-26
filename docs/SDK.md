# Pablitus Prompt Framework v1.0 — Developer SDK Guide
> **Pablitus Prompt Framework v1.0 SDK Frozen**

This guide provides step-by-step instructions for extending the Pablitus Prompt Framework (PPF) by building custom modules, themes, renderers, and event listeners.

---

## 1. Creating a Module
Modules reside in the `src/Modules/` directory. Each module must occupy its own subdirectory and follows a strict naming convention for its component files:
- **`*.Provider.ps1`**: Queries the environment and populates the `PromptContext`.
- **`*.Service.ps1`**: Wraps external commands and handles errors or caching.
- **`*.Segment.ps1`**: Defines what to show in the prompt using the data gathered by the provider.

### Example: Building a `Docker` Module

#### Step A: Create `Docker.Provider.ps1`
The provider's job is to gather raw data and put it in `$Context.Docker`. It must *never* return output or write colors.
```powershell
Register-PromptProvider -Name "Docker" -Priority 150 -Script {
    param([PromptContext]$Context)

    $dockerActive = Test-DockerActive
    $containers = 0

    if ($dockerActive) {
        $containers = Get-DockerRunningContainers
    }

    # Populate Context
    $Context.Docker.Active = $dockerActive
    $Context.Docker.RunningContainers = $containers
}
```

#### Step B: Create `Docker.Service.ps1`
The service contains business logic, executable invocations, and error handling.
```powershell
function Test-DockerActive {
    # Check if docker daemon is running
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return $false
    }
    # Quick probe (cached or with timeout)
    $output = docker info --format '{{.ContainersRunning}}' 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-DockerRunningContainers {
    $count = docker info --format '{{.ContainersRunning}}' 2>$null
    if ($LASTEXITCODE -eq 0) {
        return [int]$count
    }
    return 0
}
```

#### Step C: Create `Docker.Segment.ps1`
The segment reads from `$Context.Docker`, decides if it should display itself, and registers the segment.
```powershell
Register-PromptSegment -Name "Docker" -Priority 150 -Script {
    param([PromptContext]$Context)

    # Only show if docker is active and has containers running
    if (-not $Context.Docker.Active -or $Context.Docker.RunningContainers -eq 0) {
        return $null
    }

    $icon = Resolve-ThemeIcon -IconKey "Docker" -Default "🐳"
    $color = Resolve-ThemeColor -ColorName "Docker" -Default "Cyan"

    return [PromptSegment]::new(
        "Docker",
        "$icon $($Context.Docker.RunningContainers)",
        $color,
        "DarkGray" # Background
    )
}
```

---

## 2. Registering a Custom Renderer
Renderers transform the array of `PromptSegment` objects into a single printable prompt string. They must be stateless.

### Example: Custom Minimalist Renderer
Create a folder `src/Renderers/Minimal/` and add `Minimal.Renderer.ps1`:
```powershell
Register-PromptRenderer -Name "Minimal" -Script {
    param([PromptContext]$Context)

    $promptStr = ""
    # Render segments in order
    foreach ($segment in $Context.Segments) {
        $promptStr += "[$($segment.Text)] "
    }

    # Final prompt symbol
    $symbol = if ($env:USER -eq "root" -or $env:USERNAME -eq "Administrator") { "#" } else { ">" }
    $promptStr += "$symbol "

    return $promptStr
}
```

---

## 3. Registering a Custom Theme
Themes define colors and icons. You can register a theme directly, import it
from a `.Theme.ps1` file, or let PPF discover it in `src/Themes/`.

### Example: Registering the "Sunset" Theme
```powershell
Register-PromptTheme `
    -Name "Sunset" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Red"
        "Secondary"  = "Yellow"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        "Text"      = "#fff4e6"
        "DarkText"  = "#2b1b17"
        "SessionBg" = "#ff8a65"
        "PathBg"    = "#ffd54f"
        "GitBg"     = "#81c784"
        "TimeBg"    = "#ba68c8"
    } `
    -Icons @{
        "Session"  = ""
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Time"     = [string][char]0xF017
    } `
    -Segments @{
        "Session" = @{
            Visible         = $true
            Icon            = "Session"
            Foreground      = "DarkText"
            Background      = "SessionBg"
            LeadingDiamond  = ""
            PowerlineSymbol = ""
        }
        "Path" = @{
            Visible         = $true
            Icon            = "Path"
            Foreground      = "DarkText"
            Background      = "PathBg"
            PathStyle       = "Folder"
            PowerlineSymbol = ""
        }
        "Time" = @{
            Visible         = $true
            Icon            = "Time"
            Foreground      = "DarkText"
            Background      = "TimeBg"
            TrailingDiamond = ""
            PowerlineSymbol = ""
        }
    }

Set-PromptTheme -Name "Sunset"
```

To keep a theme outside the repository, save it as `Sunset.Theme.ps1` and load
it with `Import-PromptTheme -Path .\Sunset.Theme.ps1`. See
[Themes](Themes.md#8-creating-custom-themes) for the full contract.

---

## 4. Subscribing to Events
PPF has a simple hook-based event model. You can listen to events such as `BeforeRender`, `AfterRender`, or `ThemeChanged`.

### Example: Log Prompt Render Times
```powershell
Register-PPFEventListener -EventName "AfterRender" -Script {
    param([PromptContext]$Context)
    $time = $Context.Metrics["ExecutionTimeMs"]
    Write-Debug "[PPF Log] Prompt rendered in $time ms."
}
```

---

## 5. Custom Segments in .NET Mode

Custom segment scriptblocks work in both engines. In the legacy PowerShell
engine they run directly. In the opt-in .NET engine they run in a dedicated
PowerShell runspace through the plugin host.

You do not need a second registration for .NET mode. Keep using
`Register-PromptSegment`:

```powershell
Register-PromptSegment -Name "Deploy" -Priority 120 -Script {
    param([PromptContext]$Context)

    $config = Get-SegmentConfiguration -Name "Deploy"
    if (-not $config.Visible) {
        return $null
    }

    New-PromptSegment `
        -Name "Deploy" `
        -Text "deploy:$($config.Environment)" `
        -Foreground $config.Foreground
}
```

Reference it from a PPF JSON theme by type name:

```json
{
  "type": "Deploy",
  "name": "deploy",
  "style": "plain",
  "foreground": "#ffffff",
  "timeoutMs": 1500,
  "properties": {
    "environment": "production",
    "nested": { "region": "us-east-1" }
  }
}
```

The host maps the .NET context to the legacy `PromptContext`, applies the
segment's `properties` with `Set-SegmentConfiguration`, and sets `$PWD` to the
rendered path. Available data includes `$Context.Session`, `$Context.Path`,
`$Context.Git`, `$Context.Timestamp`, `$Context.Metrics`, and
`$global:LASTEXITCODE`.

Rules and limitations:

- The segment type must match the name used in `Register-PromptSegment`.
  Matching is case-insensitive.
- Native .NET types (`session`, `path`, `git`, `text`, `time`, `exit`) cannot be
  overridden by a custom segment with the same name.
- A returning `PromptSegment` is converted to the .NET result. Returning
  `$null` or no segment makes the segment invisible.
- Exceptions are isolated: the prompt continues and the failing segment is
  hidden.
- `timeoutMs` is enforced by the scheduler. The default plugin timeout is
  2000 ms.
- Plugins run with the permissions of the current user. The runspace is an
  isolation boundary for module state, not a security sandbox.
- The plugin host does not run `BeforeRender` / `AfterRender` in .NET mode.

See [ADR 0003](adr/0003-powershell-plugin-host.md) for the full contract.
