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
Themes define colors and icons. You can register custom themes from anywhere in your scripts using `Register-PromptTheme`.

### Example: Registering the "Sunset" Theme
```powershell
$sunSetTheme = @{
    Colors = @{
        Primary   = "Red"
        Secondary = "Yellow"
        Success   = "Green"
        Docker    = "Magenta"
    }
    Icons = @{
        Docker    = "🐳"
        GitDirty  = "✗"
        GitClean  = "✓"
    }
}

Register-PromptTheme -Name "Sunset" -Theme $sunSetTheme
Set-PromptTheme -Name "Sunset"
```

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
