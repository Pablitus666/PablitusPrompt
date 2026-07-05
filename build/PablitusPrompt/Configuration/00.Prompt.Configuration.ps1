# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Configuration.ps1
# ============================================================

class PromptConfiguration {

    [hashtable]$Segments
    [hashtable]$Renderer
    [hashtable]$Theme
    [hashtable]$Performance

    PromptConfiguration() {

        $this.Segments    = @{}
        $this.Renderer    = @{}
        $this.Theme       = @{}
        $this.Performance = @{}

    }

}

$script:PromptConfiguration = [PromptConfiguration]::new()

function Get-PromptConfiguration {

    return $script:PromptConfiguration

}

function Set-PromptConfiguration {

    param(
        [PromptConfiguration]$Configuration
    )

    $script:PromptConfiguration = $Configuration

}

function Get-SegmentConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($script:PromptConfiguration.Segments.ContainsKey($Name)) {
        return $script:PromptConfiguration.Segments[$Name]
    }

    return @{
        Visible    = $true
        Icon       = ""
        Foreground = "White"
        Background = ""
    }

}

function Set-SegmentConfiguration {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [hashtable]$Configuration

    )

    $script:PromptConfiguration.Segments[$Name] = $Configuration

}