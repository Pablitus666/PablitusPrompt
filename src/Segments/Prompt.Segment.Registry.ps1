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
        [PromptContext]$Context
    )

    $segments = [System.Collections.Generic.List[PromptSegment]]::new()

    foreach ($entry in ($script:PromptSegments | Sort-Object Priority)) {

        $segment = & $entry.Script $Context

        if ($null -ne $segment) {
            $null = $segments.Add($segment)
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