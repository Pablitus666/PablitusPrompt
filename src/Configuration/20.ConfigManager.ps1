# ============================================================
# Pablitus Prompt Framework (PPF)
# ConfigManager.ps1
# ============================================================

$script:ConfigFilePath = $null
$script:ConfigFileLastWriteTime = $null
$script:HotReloadEnabled = $false

function Import-PromptConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Verbose "[PPF] Config file not found at '$Path'"
        return
    }

    Write-Verbose "[PPF] Loading config from '$Path'"
    
    $configData = $null
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()

    if ($ext -eq ".json") {
        $content = Get-Content -Raw -Path $Path
        $configData = ConvertFrom-Json $content -AsHashtable
    }
    elseif ($ext -eq ".psd1") {
        $configData = Import-PowerShellDataFile -Path $Path
    }
    else {
        throw "Unsupported configuration format: $ext. Support JSON and PSD1."
    }

    if (-not $configData) {
        return
    }

    # 1. Theme
    if ($configData.ContainsKey("theme")) {
        $themeName = $configData["theme"]
        if (Get-Command Set-PromptTheme -ErrorAction SilentlyContinue) {
            try {
                Set-PromptTheme -Name $themeName
            }
            catch {
                Write-Warning "[PPF] Failed to set theme '$themeName': $_"
            }
        }
    }

    # 2. Renderer
    if ($configData.ContainsKey("renderer")) {
        $rendererName = $configData["renderer"]
        $config = Get-PromptConfiguration
        $config.Renderer["Default"] = $rendererName
    }

    # 3. Segments
    if ($configData.ContainsKey("segments") -and ($configData["segments"] -is [hashtable])) {
        foreach ($segName in $configData["segments"].Keys) {
            $segVal = $configData["segments"][$segName]
            $currentCfg = Get-SegmentConfiguration -Name $segName

            if ($segVal -is [bool]) {
                $currentCfg.Visible = $segVal
            }
            elseif ($segVal -is [hashtable]) {
                foreach ($key in $segVal.Keys) {
                    $currentCfg[$key] = $segVal[$key]
                }
            }
            Set-SegmentConfiguration -Name $segName -Configuration $currentCfg
        }
    }

    $script:ConfigFileLastWriteTime = (Get-Item $Path).LastWriteTime

    if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
        Invoke-PPFEvent -EventName "ConfigurationChanged" -EventArgs $Path
    }

}

function Export-PromptConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $config = Get-PromptConfiguration
    
    $activeTheme = Get-ActiveTheme
    $themeName = if ($activeTheme) { $activeTheme.Name } else { $config.Theme["Name"] }
    $rendererName = $config.Renderer["Default"]

    $segmentsHash = @{}
    foreach ($segName in $config.Segments.Keys) {
        $segmentsHash[$segName] = $config.Segments[$segName]
    }

    $exportHash = [ordered]@{
        "theme"    = $themeName
        "renderer" = $rendererName
        "segments" = $segmentsHash
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    if ($ext -eq ".json") {
        $json = $exportHash | ConvertTo-Json -Depth 5
        $json | Out-File -FilePath $Path -Encoding utf8
    }
    elseif ($ext -eq ".psd1") {
        $sb = New-Object System.Text.StringBuilder
        $null = $sb.AppendLine("@{")
        $null = $sb.AppendLine("    theme = '$themeName'")
        $null = $sb.AppendLine("    renderer = '$rendererName'")
        $null = $sb.AppendLine("    segments = @{")
        foreach ($key in $segmentsHash.Keys) {
            $val = $segmentsHash[$key]
            if ($val -is [hashtable]) {
                $null = $sb.AppendLine("        '$key' = @{")
                foreach ($subKey in $val.Keys) {
                    $subVal = $val[$subKey]
                    if ($subVal -is [bool]) {
                        $boolStr = if ($subVal) { '$true' } else { '$false' }
                        $null = $sb.AppendLine("            $subKey = $boolStr")
                    } else {
                        $null = $sb.AppendLine("            $subKey = '$subVal'")
                    }
                }
                $null = $sb.AppendLine("        }")
            }
        }
        $null = $sb.AppendLine("    }")
        $null = $sb.AppendLine("}")
        $sb.ToString() | Out-File -FilePath $Path -Encoding utf8
    }
    else {
        throw "Unsupported configuration format: $ext. Support JSON and PSD1."
    }

}

function Enable-PromptConfigHotReload {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $script:ConfigFilePath = Resolve-Path $Path
    $script:ConfigFileLastWriteTime = (Get-Item $script:ConfigFilePath).LastWriteTime
    $script:HotReloadEnabled = $true
    
    Import-PromptConfiguration -Path $script:ConfigFilePath

}

function Disable-PromptConfigHotReload {

    $script:HotReloadEnabled = $false
    $script:ConfigFilePath = $null
    $script:ConfigFileLastWriteTime = $null

}

function Test-PromptConfigReload {

    if (-not $script:HotReloadEnabled -or -not $script:ConfigFilePath -or -not (Test-Path $script:ConfigFilePath)) {
        return
    }

    $currentWriteTime = (Get-Item $script:ConfigFilePath).LastWriteTime
    if ($currentWriteTime -gt $script:ConfigFileLastWriteTime) {
        Write-Verbose "[PPF] Hot-reloading configuration from '$script:ConfigFilePath'..."
        try {
            Import-PromptConfiguration -Path $script:ConfigFilePath
            $script:ConfigFileLastWriteTime = $currentWriteTime
        }
        catch {
            Write-Warning "[PPF] Error reloading configuration: $_"
        }
    }

}
