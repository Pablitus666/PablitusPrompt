# ============================================================
# Pablitus Prompt Framework (PPF)
# ConfigManager.ps1
# ============================================================

$script:ConfigFilePath = $null
$script:ConfigFileLastWriteTime = $null
$script:HotReloadEnabled = $false

function Get-PPFConfigValue {

    param(
        [System.Collections.IDictionary]$Table,
        [string]$Name
    )

    if (-not $Table) {
        return $null
    }

    foreach ($key in $Table.Keys) {
        if ($key -ieq $Name) {
            return $Table[$key]
        }
    }

    return $null

}

function ConvertTo-PPFConfigImportValue {

    param(
        $Value
    )

    if ($Value -is [System.Collections.IDictionary]) {
        $normalized = @{}
        foreach ($key in $Value.Keys) {
            $normalized[$key] = ConvertTo-PPFConfigImportValue -Value $Value[$key]
        }
        return $normalized
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        return @($Value | ForEach-Object { ConvertTo-PPFConfigImportValue -Value $_ })
    }

    return $Value

}

function ConvertTo-PPFConfigExportValue {

    param(
        $Value
    )

    if ($Value -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $ordered[$key] = ConvertTo-PPFConfigExportValue -Value $Value[$key]
        }
        return $ordered
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        return @($Value | ForEach-Object { ConvertTo-PPFConfigExportValue -Value $_ })
    }

    return $Value

}

function ConvertTo-PPFPsd1ScalarLiteral {

    param(
        $Value
    )

    if ($null -eq $Value) {
        return '$null'
    }

    if ($Value -is [bool]) {
        if ($Value) {
            return '$true'
        }

        return '$false'
    }

    if ($Value -is [string]) {
        return "'" + $Value.Replace("'", "''") + "'"
    }

    return [string]$Value

}

function ConvertTo-PPFPsd1Literal {

    param(
        [Parameter(Mandatory)]
        $Value,

        [int]$Indent = 0
    )

    $pad = ' ' * $Indent

    if ($Value -is [System.Collections.IDictionary]) {
        $sb = New-Object System.Text.StringBuilder
        $null = $sb.AppendLine("@{")
        foreach ($key in $Value.Keys) {
            $child = $Value[$key]
            $childLiteral = ConvertTo-PPFPsd1Literal -Value $child -Indent ($Indent + 4)
            $null = $sb.AppendLine("${pad}    $key = $childLiteral")
        }
        $null = $sb.Append("${pad}}")
        return $sb.ToString()
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @($Value | ForEach-Object {
            ConvertTo-PPFPsd1ScalarLiteral -Value $_
        })
        return "@($($items -join ', '))"
    }

    return ConvertTo-PPFPsd1ScalarLiteral -Value $Value

}

function Import-PromptConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    if ($ext -ne ".json" -and $ext -ne ".psd1") {
        throw "Unsupported configuration format: $ext. Support JSON and PSD1."
    }

    if (-not (Test-Path $Path)) {
        Write-Verbose "[PPF] Config file not found at '$Path'"
        return
    }

    Write-Verbose "[PPF] Loading config from '$Path'"
    
    try {
        if ($ext -eq ".json") {
            $content = Get-Content -Raw -Path $Path
            $configData = ConvertFrom-Json $content -AsHashtable
        }
        elseif ($ext -eq ".psd1") {
            $configData = Import-PowerShellDataFile -Path $Path
        }
    }
    catch {
        Write-Warning "[PPF] Failed to parse configuration file '$Path': $_"
        return
    }

    if (-not $configData) {
        return
    }

    $config = Get-PromptConfiguration
    if (-not $config) {
        return
    }

    $properties = @($config.PSObject.Properties)
    $importedSegments = $null
    foreach ($property in $properties) {
        $incoming = Get-PPFConfigValue -Table $configData -Name $property.Name
        if ($null -eq $incoming) {
            continue
        }

        # Ensure the incoming value type matches the expected property type
        $importedValue = ConvertTo-PPFConfigImportValue -Value $incoming

        if ($property.Name -eq "Segments" -and $importedValue -is [hashtable]) {
            # Keep a snapshot: Set-PromptTheme mutates the live configuration below,
            # so $config.Segments no longer holds the imported values afterwards.
            $importedSegments = $importedValue.Clone()
        }

        # Specific fix for Renderer Hashtable vs String issue
        if ($property.Name -eq "Renderer" -and $importedValue -is [string]) {
             $property.Value = @{ "Default" = $importedValue }
        }
        # Specific fix for Theme Hashtable vs String issue
        elseif ($property.Name -eq "Theme" -and $importedValue -is [string]) {
             $property.Value = @{ "Name" = $importedValue }
        }
        else {
             $property.Value = $importedValue
        }
    }

    if ($config.Theme -and $config.Theme.ContainsKey("Name")) {
        $themeName = $config.Theme["Name"]
        if ($themeName -and (Get-Command Set-PromptTheme -ErrorAction SilentlyContinue)) {
            try {
                Set-PromptTheme -Name $themeName
            }
            catch {
                Write-Warning "[PPF] Failed to set theme '$themeName': $_"
            }
        }
    }

    if ($config.Segments -is [hashtable] -and $importedSegments -is [hashtable]) {
        # Iterate a snapshot of the imported keys to avoid modification during enumeration
        $segNames = @($importedSegments.Keys)
        foreach ($segName in $segNames) {
            $segVal = $importedSegments[$segName]
            $currentCfg = Get-SegmentConfiguration -Name $segName

            # Get-SegmentConfiguration returns the live hashtable reference,
            # so work on a copy before merging the imported values.
            if ($currentCfg -is [hashtable]) {
                $updatedCfg = $currentCfg.Clone()
            }
            else {
                $updatedCfg = @{
                    Visible    = $true
                    Icon       = ""
                    Foreground = "White"
                    Background = ""
                }
            }

            if ($segVal -is [bool]) {
                $updatedCfg.Visible = $segVal
            }
            elseif ($segVal -is [hashtable]) {
                foreach ($key in @($segVal.Keys)) {
                    $updatedCfg[$key] = $segVal[$key]
                }
            }
            Set-SegmentConfiguration -Name $segName -Configuration $updatedCfg
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
    $exportHash = [ordered]@{}
    foreach ($property in $config.PSObject.Properties) {
        $exportHash[$property.Name] = ConvertTo-PPFConfigExportValue -Value $property.Value
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    if ($ext -eq ".json") {
        $json = $exportHash | ConvertTo-Json -Depth 10
        $json | Out-File -FilePath $Path -Encoding utf8
    }
    elseif ($ext -eq ".psd1") {
        $psd1 = ConvertTo-PPFPsd1Literal -Value $exportHash
        $psd1 | Out-File -FilePath $Path -Encoding utf8
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
