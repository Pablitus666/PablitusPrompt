# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Segment.Registry.ps1
# ============================================================

$script:PromptSegments = @()

function Register-PromptSegment {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [int]$Priority = 100,

        [Parameter(Mandatory)]
        [scriptblock]$Script

    )

    $script:PromptSegments = @(
        $script:PromptSegments |
        Where-Object Name -ne $Name
    )

    $script:PromptSegments += [pscustomobject]@{

        Name     = $Name
        Priority = $Priority
        Script   = $Script

    }

}

function Get-PromptSegments {

    param(
        [Parameter(Mandatory = $false)]
        [PromptContext]$Context
    )

    if ($null -eq $Context) {
        $Context = New-PromptContext
    }

    if ($null -eq $Context.Metrics) {
        $Context.Metrics = @{}
    }

    $segments = [System.Collections.Generic.List[PromptSegment]]::new()

    foreach ($entry in ($script:PromptSegments | Sort-Object Priority)) {

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "DEBUG" -Message "Evaluating Segment '$($entry.Name)'..."
            }
            $segment = & $entry.Script $Context
            $sw.Stop()
            
            if ($null -ne $Context.Metrics) {
                $Context.Metrics["Segment_$($entry.Name)_TimeMs"] = $sw.Elapsed.TotalMilliseconds
            }

            if ($null -ne $segment) {
                $null = $segments.Add($segment)
            }
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "TRACE" -Message "Segment '$($entry.Name)' took $($sw.Elapsed.TotalMilliseconds) ms (Visible: $($null -ne $segment))."
            }
        }
        catch {
            $sw.Stop()
            if ($null -ne $Context.Metrics) {
                $Context.Metrics["Segment_$($entry.Name)_TimeMs"] = $sw.Elapsed.TotalMilliseconds
            }
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "ERROR" -Message "Segment '$($entry.Name)' failed: $_"
            }
        }

    }

    return $segments

}

function Invoke-PromptSegments {

    param(
        [PromptContext]$Context
    )

    $Context.Segments.Clear()

    foreach ($segment in (Get-PromptSegments -Context $Context)) {

        $null = $Context.Segments.Add($segment)

    }

}
