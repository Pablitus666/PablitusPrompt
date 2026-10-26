# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Rendering.ps1
# ============================================================

$script:PromptRenderers = [ordered]@{}

# ANSI escapes and contrast colors are pure functions of their input. Both are
# called several times per segment during rendering, and the conversion used to
# rebuild its named-color table and run a regex on every call. The results are
# memoized for the lifetime of the session; the palette is small and stable.
$script:PPFAnsiColorCache = @{}
$script:PPFContrastColorCache = @{}
$script:PPFAnsiNamedColors = @{
    "Black"   = 0
    "Red"     = 1
    "Green"   = 2
    "Yellow"  = 3
    "Blue"    = 4
    "Magenta" = 5
    "Cyan"    = 6
    "White"   = 7
}

function ConvertTo-PPFAnsiColor {

    param(
        [string]$Color,

        [switch]$Background
    )

    if ([string]::IsNullOrWhiteSpace($Color)) {
        return ""
    }

    $cacheKey = if ($Background) { "B$Color" } else { "F$Color" }
    $cached = $script:PPFAnsiColorCache[$cacheKey]
    if ($null -ne $cached) {
        return $cached
    }

    $baseCode = if ($Background) { 40 } else { 30 }
    $result = ""

    if ($script:PPFAnsiNamedColors.ContainsKey($Color)) {
        $result = "`e[$($baseCode + $script:PPFAnsiNamedColors[$Color])m"
    }
    elseif ($Color -match '^#?([0-9a-fA-F]{6})$') {
        $hex = $Matches[1]
        $red = [Convert]::ToInt32($hex.Substring(0, 2), 16)
        $green = [Convert]::ToInt32($hex.Substring(2, 2), 16)
        $blue = [Convert]::ToInt32($hex.Substring(4, 2), 16)
        $prefix = if ($Background) { 48 } else { 38 }
        $result = "`e[$prefix;2;$red;$green;${blue}m"
    }

    $script:PPFAnsiColorCache[$cacheKey] = $result
    return $result

}

function Get-PPFContrastColor {

    param(
        [string]$Color
    )

    if ([string]::IsNullOrWhiteSpace($Color)) {
        return "White"
    }

    $cached = $script:PPFContrastColorCache[$Color]
    if ($null -ne $cached) {
        return $cached
    }

    $result = "White"

    if ($Color -match '^#?([0-9a-fA-F]{6})$') {
        $hex = $Matches[1]
        $red = [Convert]::ToInt32($hex.Substring(0, 2), 16)
        $green = [Convert]::ToInt32($hex.Substring(2, 2), 16)
        $blue = [Convert]::ToInt32($hex.Substring(4, 2), 16)
        $luminance = (0.299 * $red) + (0.587 * $green) + (0.114 * $blue)
        if ($luminance -gt 150) {
            $result = "Black"
        }
    }
    elseif ($Color -in @("Yellow", "Cyan", "White", "Green")) {
        $result = "Black"
    }

    $script:PPFContrastColorCache[$Color] = $result
    return $result

}

function Get-ConfiguredRendererName {

    $config = Get-PromptConfiguration
    if ($config -and $config.Renderer -and $config.Renderer.ContainsKey("Default")) {
        $configured = $config.Renderer["Default"]
        if ($configured -and $script:PromptRenderers.Contains($configured)) {
            return $configured
        }
    }

    return "Plain"

}

function Register-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Script

    )

    $script:PromptRenderers[$Name] = $Script

}

function Get-PromptRenderer {

    param(
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Get-ConfiguredRendererName
    }

    if (-not $script:PromptRenderers.Contains($Name)) {
        throw "Renderer '$Name' is not registered."
    }

    return $script:PromptRenderers[$Name]

}

function Get-PromptRenderers {

    return $script:PromptRenderers.Keys

}

function Invoke-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [PromptContext]$Context,

        [string]$Renderer

    )

    $rendererScript = Get-PromptRenderer -Name $Renderer

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if ($script:LogLevel -eq "DEBUG" -or $script:LogLevel -eq "TRACE") {
            Write-PPFLog -Level "DEBUG" -Message "Invoking Renderer '$Renderer'..."
        }
        # Prompt.Events is always loaded before renderers in both bootstrap
        # paths, so dispatch directly instead of resolving the command on
        # every render (Get-Command alone costs close to a millisecond).
        Invoke-PPFEvent -EventName "BeforeRender" -EventArgs $Context
        $result = & $rendererScript -Context $Context
        $sw.Stop()
        $Context.Metrics["Renderer_TimeMs"] = $sw.Elapsed.TotalMilliseconds
        Invoke-PPFEvent -EventName "AfterRender" -EventArgs $Context
        if ($script:LogLevel -eq "TRACE") {
            Write-PPFLog -Level "TRACE" -Message "Renderer '$Renderer' took $($sw.Elapsed.TotalMilliseconds) ms."
        }
        return $result
    }
    catch {
        $sw.Stop()
        $Context.Metrics["Renderer_TimeMs"] = $sw.Elapsed.TotalMilliseconds
        Write-PPFLog -Level "ERROR" -Message "Renderer '$Renderer' failed: $_"
        throw $_
    }

}

function Get-PromptString {

    param(

        [PromptContext]$Context,

        [string]$Renderer,

        [switch]$Transient,

        [string]$CommandLine,

        [int]$TerminalWidth = 0,

        [int]$Column = 0
    )

    $hasExplicitContext = $PSBoundParameters.ContainsKey("Context") -and $null -ne $Context

    if (-not $hasExplicitContext) {
        $useDotNetCore = $false
        try {
            $useDotNetCore = [bool](Test-PPFDotNetCoreEnabled)
        }
        catch {
            $useDotNetCore = $false
            Write-PPFLog -Level "DEBUG" -Message "PPF .NET core probe failed: $($_.Exception.Message)"
        }

        if ($useDotNetCore) {
            $coreRenderer = $null
            $supportsCoreRenderer = $true
            if (-not [string]::IsNullOrWhiteSpace($Renderer)) {
                # The .NET core implements plain and powerline. Any other
                # legacy renderer (JSON, HTML, Markdown, Minimal, Rich, ANSI
                # or a custom renderer) must stay on the PowerShell engine;
                # otherwise an explicit -Renderer would silently change its
                # output format.
                switch ($Renderer.ToLowerInvariant()) {
                    "powerline" { $coreRenderer = "powerline" }
                    "plain" { $coreRenderer = "plain" }
                    default { $supportsCoreRenderer = $false }
                }
            }

            if ($supportsCoreRenderer -or $Transient) {
                try {
                    $dotNetPrompt = Invoke-PPFDotNetPrompt `
                        -RendererOverride $coreRenderer `
                        -Transient:$Transient `
                        -CommandLine $CommandLine `
                        -TerminalWidth $TerminalWidth `
                        -Column $Column
                    if ($null -ne $dotNetPrompt -and $null -ne $dotNetPrompt.Output) {
                        return $dotNetPrompt.Output
                    }
                }
                catch {
                    $script:PPFDotNetCore.LastError = $_.Exception.Message
                    $script:PPFDotNetCore.LastErrorAt = [datetime]::UtcNow
                    $script:PPFDotNetCore.FallbackCount = [int]$script:PPFDotNetCore.FallbackCount + 1
                    Write-PPFLog -Level "DEBUG" -Message "PPF .NET core render failed; falling back to the PowerShell engine: $($_.Exception.Message)"
                }
            }
        }

        $Context = Invoke-Prompt
    }

    if ([string]::IsNullOrWhiteSpace($Renderer)) {
        $Renderer = Get-ConfiguredRendererName
    }

    Invoke-PromptRenderer `
        -Context $Context `
        -Renderer $Renderer

}

function Get-PromptTooltip {

    param(

        [Parameter(Mandatory)][string]$Command,

        [int]$TerminalWidth = 0,

        [int]$Column = 0,

        [switch]$NoColor
    )

    $hasExplicitContext = $false

    if (-not $hasExplicitContext) {
        $useDotNetCore = $false
        try {
            $useDotNetCore = [bool](Test-PPFDotNetCoreEnabled)
        }
        catch {
            $useDotNetCore = $false
            Write-PPFLog -Level "DEBUG" -Message "PPF .NET core probe failed: $($_.Exception.Message)"
        }

        if ($useDotNetCore) {
            try {
                $tooltip = Invoke-PPFDotNetTooltip -Command $Command -TerminalWidth $TerminalWidth -Column $Column
                if ($null -ne $tooltip -and $null -ne $tooltip.Output) {
                    $output = $tooltip.Output
                    if ($NoColor) {
                        $output = $output -replace '\u001b\[[0-9;]*[a-zA-Z]', ''
                    }
                    return $output
                }
            }
            catch {
                $script:PPFDotNetCore.LastError = $_.Exception.Message
                $script:PPFDotNetCore.LastErrorAt = [datetime]::UtcNow
                $script:PPFDotNetCore.FallbackCount = [int]$script:PPFDotNetCore.FallbackCount + 1
                Write-PPFLog -Level "DEBUG" -Message "PPF .NET core tooltip render failed; falling back to empty: $($_.Exception.Message)"
            }
        }
    }

    return $null
}
