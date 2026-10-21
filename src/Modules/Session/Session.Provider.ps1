# ============================================================
# Pablitus Prompt Framework (PPF)
# Session.Provider.ps1
# ============================================================

function Invoke-SessionProvider {

    param(
        [PromptContext]$Context
    )

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $Context.Session.User = if ($env:USERNAME) { $env:USERNAME } else { [System.Environment]::UserName }
        $Context.Session.Host = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [System.Net.Dns]::GetHostName() }

        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)

        $Context.Session.IsAdmin = $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
        return
    }

    $Context.Session.User = if ($env:USER) { $env:USER } elseif ($env:USERNAME) { $env:USERNAME } else { [System.Environment]::UserName }
    $Context.Session.Host = if ($env:HOSTNAME) { $env:HOSTNAME } else { [System.Net.Dns]::GetHostName() }
    $Context.Session.IsAdmin = $false

    if (Test-CommandExists id) {
        $result = Invoke-PPFExternalCommand -Command id -Arguments @('-u') -TimeoutMs 500
        if ($result -and $result.Installed -and -not $result.TimedOut -and $result.ExitCode -eq 0) {
            if ($result.Output.Trim() -eq '0') {
                $Context.Session.IsAdmin = $true
            }
        }
    }

}

Register-PromptProvider `
    -Name "Session" `
    -Priority 100 `
    -Script ${function:Invoke-SessionProvider}
