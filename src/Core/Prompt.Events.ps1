# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Events.ps1
# ============================================================

$script:PPFEventListeners = @{}

function Register-PPFEventListener {

    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Parameter(Mandatory)]
        [scriptblock]$Script
    )

    if (-not $script:PPFEventListeners.ContainsKey($EventName)) {
        $script:PPFEventListeners[$EventName] = [System.Collections.Generic.List[scriptblock]]::new()
    }

    $script:PPFEventListeners[$EventName].Add($Script)

}

function Invoke-PPFEvent {

    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Alias('EventArgs')]
        $EventArguments
    )

    if ($script:PPFEventListeners.ContainsKey($EventName)) {
        foreach ($listener in $script:PPFEventListeners[$EventName]) {
            try {
                & $listener $EventArguments
            }
            catch {
                Write-Verbose "[PPF] Event listener for '$EventName' failed: $_"
            }
        }
    }

}
