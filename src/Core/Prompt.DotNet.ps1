# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.DotNet.ps1
#
# Opt-in adapter to the .NET core. The PowerShell engine remains the
# default; this file only registers the bridge used when
# PPF_USE_DOTNET_CORE=1 or Enable-PPFDotNetCore is called.
# ============================================================

$script:PPFDotNetCoreRoot = if ($global:PPF_InstallRoot) {
    [System.IO.Path]::GetFullPath($global:PPF_InstallRoot)
}
elseif ($PSScriptRoot) {
    [System.IO.Path]::GetFullPath($PSScriptRoot)
}
else {
    (Get-Location).ProviderPath
}

# The module manifest lives in <repo>/src in this repository, while the .NET
# solution lives in <repo>/dotnet. When the install root points at src (or any
# directory without a dotnet folder), walk one level up.
if (-not (Test-Path -LiteralPath (Join-Path $script:PPFDotNetCoreRoot "dotnet") -PathType Container)) {
    $parent = Split-Path -Parent $script:PPFDotNetCoreRoot
    if ($parent -and (Test-Path -LiteralPath (Join-Path $parent "dotnet") -PathType Container)) {
        $script:PPFDotNetCoreRoot = $parent
    }
}

$script:PPFDotNetCore = [ordered]@{
    Enabled           = $false
    Suppressed        = $false
    AssemblyPath      = $null
    AssemblyLoaded    = $false
    Engine            = $null
    Config            = $null
    ThemePath         = $null
    ThemeStamp        = $null
    ThemeKind         = $null
    IgnoreUnsupported = $false
    LastError         = $null
    LastErrorAt       = $null
    FallbackCount     = 0
    RenderCount       = 0
    AutoEnableKey     = $null
    LastImportedPath  = $null
    Plugins              = [ordered]@{}
    PluginHostType       = $null
    PluginHostError      = $null
    PluginRegistryVersion = -1
}

# The plugin host imports the module into a dedicated runspace. The empty
# theme leaves palette keys unresolved so the .NET renderer can resolve them
# with the active JSON theme instead of the runspace's default theme.
$script:PPFDotNetPluginInitializationScript = @'
param(
    [Parameter(Mandatory)][string]$ModulePath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

Import-Module -Name $ModulePath -Force

if (Get-Command Register-PromptTheme -ErrorAction SilentlyContinue) {
    Register-PromptTheme -Name "__PPFPluginHost" -Palette @{} -Icons @{} -Segments @{}
    Set-PromptTheme -Name "__PPFPluginHost"
}
'@

# This script runs inside the plugin runspace. It maps the .NET context to
# the legacy PPF context, applies the theme segment properties through the
# legacy configuration API, invokes the registered scriptblock in module
# scope (so [PromptContext] resolves), and returns one sentinel object.
$script:PPFDotNetPluginInvocationScript = @'
param(
    [Parameter(Mandatory)] $Context,
    [Parameter(Mandatory)] $Segment,
    [Parameter(Mandatory)][string] $PluginName,
    [Parameter(Mandatory)][string] $PluginScript
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

function ConvertTo-PPFDotNetHostValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Text.Json.JsonElement]) {
        switch ($Value.ValueKind) {
            'Object' {
                $result = @{}
                foreach ($property in $Value.EnumerateObject()) {
                    $result[$property.Name] = ConvertTo-PPFDotNetHostValue -Value $property.Value
                }
                return $result
            }
            'Array' {
                $items = @()
                foreach ($item in $Value.EnumerateArray()) {
                    $items += ConvertTo-PPFDotNetHostValue -Value $item
                }
                return $items
            }
            'String' { return $Value.GetString() }
            'Number' {
                $integer = [long]0
                if ($Value.TryGetInt64([ref]$integer)) {
                    return $integer
                }
                $real = [double]0
                if ($Value.TryGetDouble([ref]$real)) {
                    return $real
                }
                return $Value.GetRawText()
            }
            'True' { return $true }
            'False' { return $false }
            'Null' { return $null }
            default { return $Value.GetRawText() }
        }
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $Value.Keys) {
            $result[[string]$key] = ConvertTo-PPFDotNetHostValue -Value $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @()
        foreach ($item in $Value) {
            $items += ConvertTo-PPFDotNetHostValue -Value $item
        }
        return $items
    }

    return $Value
}

function Get-PPFDotNetHostSegmentValue {
    param(
        $Segment,
        [string]$Name,
        $Default = $null
    )

    if ($null -eq $Segment) {
        return $Default
    }

    if ($Segment -is [System.Collections.IDictionary]) {
        if ($Segment.Contains($Name)) {
            return $Segment[$Name]
        }
        return $Default
    }

    $property = $Segment.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $Default
}

function Test-PPFDotNetHostSegment {
    param($Value)

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return $Value.Contains('Text')
    }

    return $null -ne $Value.PSObject.Properties['Text']
}

$legacyContext = New-PromptContext
$legacyContext.Session.User = [string]$Context.UserName
$legacyContext.Session.Host = [string]$Context.HostName
$legacyContext.Path.Current = [string]$Context.Path.Current
$legacyContext.Path.Friendly = [string]$Context.Path.Display
if ([string]::IsNullOrWhiteSpace($legacyContext.Path.Friendly)) {
    $legacyContext.Path.Friendly = $legacyContext.Path.Current
}
$legacyContext.Git.IsRepository = [bool]$Context.Git.IsRepository
$legacyContext.Git.Branch = [string]$Context.Git.Branch
$legacyContext.Git.Dirty = [bool]$Context.Git.IsDirty
$legacyContext.Git.Ahead = [int]$Context.Git.Ahead
$legacyContext.Git.Behind = [int]$Context.Git.Behind
if ($null -ne $Context.Timestamp) {
    $localTimestamp = $Context.Timestamp.LocalDateTime
    if ($null -ne $localTimestamp) {
        $legacyContext.Timestamp = $localTimestamp
    }
}
$global:LASTEXITCODE = [int]$Context.ExitCode

if ($null -ne $Context.Properties) {
    foreach ($entry in $Context.Properties.GetEnumerator()) {
        $legacyContext.Metrics[[string]$entry.Key] = ConvertTo-PPFDotNetHostValue -Value $entry.Value
    }
}

try {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    $legacyContext.Session.IsAdmin = $principal.IsInRole(
        [System.Security.Principal.WindowsBuiltInRole]::Administrator
    )
}
catch {
    $legacyContext.Session.IsAdmin = $false
}

$config = @{}
if ($null -ne $Segment.Properties) {
    foreach ($entry in $Segment.Properties.GetEnumerator()) {
        $config[[string]$entry.Key] = ConvertTo-PPFDotNetHostValue -Value $entry.Value
    }
}
$config['Visible'] = $true
$config['Icon'] = [string]$Segment.Icon
$config['Foreground'] = [string]$Segment.Foreground
$config['Background'] = [string]$Segment.Background

$configNames = @($PluginName, $Segment.Name, $Segment.Type) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -Unique

foreach ($configName in $configNames) {
    Set-SegmentConfiguration -Name $configName -Configuration $config
}

if (-not [string]::IsNullOrWhiteSpace($Context.Path.Current)) {
    try {
        Set-Location -LiteralPath $Context.Path.Current -ErrorAction Stop
    }
    catch {
        # A stale working directory must not hide the segment.
    }
}

try {
    $plugin = [scriptblock]::Create($PluginScript)
    $module = Get-Module -Name PablitusPrompt | Select-Object -First 1
    if ($null -eq $module) {
        throw "The PablitusPrompt module is not loaded in the plugin runspace."
    }

    $output = @($module.Invoke({ param($script, $ctx) & $script $ctx }, $plugin, $legacyContext))
    $segments = @($output | Where-Object { Test-PPFDotNetHostSegment -Value $_ })
    $selected = $segments | Where-Object {
        (Get-PPFDotNetHostSegmentValue -Segment $_ -Name 'Visible' -Default $true) -ne $false
    } | Select-Object -First 1

    if ($null -eq $selected) {
        $selected = $segments | Select-Object -First 1
    }

    if ($null -eq $selected) {
        [pscustomobject]@{
            PSTypeName = 'PablitusPrompt.PluginResult'
            Name       = [string]$Segment.Name
            Visible    = $false
            Text       = ''
            Icon       = ''
            Foreground = ''
            Background = ''
            Status     = 'Success'
            Error      = $null
        }
        return
    }

    $text = [string](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Text' -Default '')
    $visible = [bool](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Visible' -Default $true)

    [pscustomobject]@{
        PSTypeName = 'PablitusPrompt.PluginResult'
        Name       = [string](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Name' -Default $Segment.Name)
        Visible    = $visible
        Text       = $text
        Icon       = [string](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Icon' -Default '')
        Foreground = [string](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Foreground' -Default '')
        Background = [string](Get-PPFDotNetHostSegmentValue -Segment $selected -Name 'Background' -Default '')
        Status     = 'Success'
        Error      = $null
    }
}
catch {
    [pscustomobject]@{
        PSTypeName = 'PablitusPrompt.PluginResult'
        Name       = [string]$Segment.Name
        Visible    = $false
        Text       = ''
        Icon       = ''
        Foreground = ''
        Background = ''
        Status     = 'Failed'
        Error      = $_.Exception.Message
    }
}
'@

function Resolve-PPFDotNetCoreAssemblyPath {

    # An explicit override wins. If it is wrong we report the core as
    # unavailable instead of silently loading a different build.
    if (-not [string]::IsNullOrWhiteSpace($env:PPF_DOTNET_CORE_DLL)) {
        try {
            return [System.IO.Path]::GetFullPath($env:PPF_DOTNET_CORE_DLL)
        }
        catch {
            return $env:PPF_DOTNET_CORE_DLL
        }
    }

    $root = $script:PPFDotNetCoreRoot
    $candidates = @(
        (Join-Path $root "dotnet/publish/PablitusPrompt.Core.dll")
        (Join-Path $root "dotnet/src/PablitusPrompt.Core/bin/Release/net8.0/PablitusPrompt.Core.dll")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $candidates[0]
}

function Get-PPFDotNetCoreThemeStamp {

    param(
        [Parameter(Mandatory)][string]$Path
    )

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    return "$($item.LastWriteTimeUtc.Ticks):$($item.Length)"
}

function Test-PPFDotNetOmpTheme {

    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Json
    )

    if ($Path -like "*.omp.json") {
        return $true
    }

    if ([string]::IsNullOrWhiteSpace($Json)) {
        $Json = [System.IO.File]::ReadAllText($Path)
    }

    try {
        $document = $Json | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $false
    }

    if ($null -eq $document -or $document -isnot [pscustomobject]) {
        return $false
    }

    $schema = [string]$document.'$schema'
    if ($schema -match "oh-my-posh|JanDeDobbeleer") {
        return $true
    }

    if ($schema -match "pablitus\.dev/schemas/(ppf|theme)\.schema") {
        return $false
    }

    $names = @($document.PSObject.Properties.Name)
    if ($names -notcontains "blocks" -or $names -contains "theme") {
        return $false
    }

    # PPF-only camelCase fields are a strong signal that this is not OMP.
    foreach ($ppfMarker in @("renderer", "defaultStyle", "template", "cache")) {
        if ($names -contains $ppfMarker) {
            return $false
        }
    }

    $ompMarkers = @(
        "final_space",
        "console_title_template",
        "secondary_prompt",
        "transient_prompt",
        "tooltips"
    )

    foreach ($marker in $ompMarkers) {
        if ($names -contains $marker) {
            return $true
        }
    }

    if ($null -ne $document.version -and $document.version -isnot [string]) {
        return $true
    }

    foreach ($block in @($document.blocks)) {
        foreach ($segment in @($block.segments)) {
            if ($null -eq $segment -or $segment -isnot [pscustomobject]) {
                continue
            }

            if (@($segment.PSObject.Properties.Name) -contains "properties") {
                return $true
            }
        }
    }

    return $false
}

function Import-PPFDotNetThemeInternal {

    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$IgnoreUnsupported
    )

    $fullPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $json = [System.IO.File]::ReadAllText($fullPath)
    $serializer = [PablitusPrompt.Core.Configuration.PpfConfigSerializer]

    if (Test-PPFDotNetOmpTheme -Path $fullPath -Json $json) {
        $importer = [PablitusPrompt.Core.Omp.OmpThemeImporter]::new()
        $theme = $importer.ImportFile($fullPath, [bool]$IgnoreUnsupported, $null)

        # Round-trip through the serializer so the imported theme receives the
        # same semantic validation as a hand-written theme file.
        $normalized = $serializer::SerializeTheme($theme)
        $theme = $serializer::LoadThemeFromJson($normalized, $fullPath)

        $config = [PablitusPrompt.Core.Configuration.PpfConfig]::new()
        $config.Version = $theme.Version
        $config.Renderer = if ([string]::IsNullOrWhiteSpace($theme.Renderer)) { "plain" } else { $theme.Renderer }
        $config.FinalSpace = $theme.FinalSpace
        $config.Theme = $theme

        return [pscustomobject]@{
            Config  = $config
            Theme   = $theme
            Kind    = "Omp"
            Path    = $fullPath
        }
    }

    $documentKind = $serializer::DetectDocumentKind($json)
    if ($documentKind -eq [PablitusPrompt.Core.Configuration.PpfDocumentKind]::Theme) {
        $theme = $serializer::LoadThemeFromJson($json, $fullPath)

        $config = [PablitusPrompt.Core.Configuration.PpfConfig]::new()
        $config.Version = $theme.Version
        $config.Renderer = if ([string]::IsNullOrWhiteSpace($theme.Renderer)) { "plain" } else { $theme.Renderer }
        $config.FinalSpace = $theme.FinalSpace
        $config.Theme = $theme

        return [pscustomobject]@{
            Config  = $config
            Theme   = $theme
            Kind    = "PpfTheme"
            Path    = $fullPath
        }
    }

    $config = $serializer::LoadConfigFromJson($json, $fullPath)
    return [pscustomobject]@{
        Config  = $config
        Theme   = $config.Theme
        Kind    = "PpfConfig"
        Path    = $fullPath
    }
}

function Import-PPFDotNetCoreAssembly {

    $path = Resolve-PPFDotNetCoreAssemblyPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "PPF .NET core assembly not found. Looked for '$path'. Build it with scripts/Build-PPFDotNetCore.ps1 or set PPF_DOTNET_CORE_DLL."
    }

    $state = $script:PPFDotNetCore
    if (-not $state.AssemblyLoaded -or $state.AssemblyPath -ne $path) {
        Add-Type -Path $path -ErrorAction Stop
        $state.AssemblyLoaded = $true
        $state.AssemblyPath = $path
    }

    return $path
}

function Get-PPFDotNetModuleManifestPath {

    $candidates = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($global:PPF_InstallRoot)) {
        $candidates.Add((Join-Path $global:PPF_InstallRoot "PablitusPrompt.psd1"))
    }

    $candidates.Add((Join-Path $script:PPFDotNetCoreRoot "PablitusPrompt.psd1"))
    $candidates.Add((Join-Path $script:PPFDotNetCoreRoot "src/PablitusPrompt.psd1"))

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Get-PPFDotNetPluginHostSourcePath {

    $candidates = @(
        (Join-Path $script:PPFDotNetCoreRoot "src/Core/PpfPowerShellPluginHost.cs")
        (Join-Path $script:PPFDotNetCoreRoot "Core/PpfPowerShellPluginHost.cs")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Get-PPFDotNetPluginDefinitions {

    $definitions = [System.Collections.Generic.List[object]]::new()

    foreach ($entry in @($script:PromptSegments)) {
        if ($null -eq $entry) {
            continue
        }

        $name = [string]$entry.Name
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $scriptText = $null
        try {
            $scriptText = $entry.Script.ToString()
        }
        catch {
            $scriptText = $null
        }

        if ([string]::IsNullOrWhiteSpace($scriptText)) {
            continue
        }

        $definitions.Add([pscustomobject]@{
            Name     = $name
            Priority = [int]$entry.Priority
            Script   = $scriptText
        })
    }

    return $definitions
}

function Initialize-PPFDotNetPluginHost {

    $state = $script:PPFDotNetCore
    if ($null -ne $state.PluginHostType) {
        return $state.PluginHostType
    }

    $typeName = "PablitusPrompt.Integrations.PpfPowerShellSegmentProvider"

    foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
        try {
            $existingType = $assembly.GetType($typeName, $false)
            if ($null -ne $existingType) {
                $state.PluginHostType = $existingType
                $state.PluginHostError = $null
                return $existingType
            }
        }
        catch {
            # Some dynamic assemblies cannot be inspected; keep looking.
        }
    }

    $sourcePath = Get-PPFDotNetPluginHostSourcePath
    if ([string]::IsNullOrWhiteSpace($sourcePath)) {
        throw "PowerShell plugin host source not found. Expected PpfPowerShellPluginHost.cs next to Prompt.DotNet.ps1."
    }

    $corePath = $state.AssemblyPath
    if ([string]::IsNullOrWhiteSpace($corePath) -or -not (Test-Path -LiteralPath $corePath -PathType Leaf)) {
        $corePath = Import-PPFDotNetCoreAssembly
    }

    $smaPath = [System.Management.Automation.PowerShell].Assembly.Location
    if ([string]::IsNullOrWhiteSpace($smaPath) -or -not (Test-Path -LiteralPath $smaPath -PathType Leaf)) {
        throw "System.Management.Automation.dll could not be located for the PowerShell plugin host."
    }

    $references = @($corePath, $smaPath)
    $smaDirectory = Split-Path -Parent $smaPath
    foreach ($assemblyName in @(
        "System.Private.CoreLib.dll",
        "System.Collections.dll",
        "System.Runtime.dll",
        "System.Threading.dll",
        "System.Threading.Tasks.dll"
    )) {
        $assemblyPath = Join-Path $smaDirectory $assemblyName
        if (Test-Path -LiteralPath $assemblyPath -PathType Leaf) {
            $references += $assemblyPath
        }
    }

    $source = [System.IO.File]::ReadAllText($sourcePath)
    $types = Add-Type `
        -TypeDefinition $source `
        -ReferencedAssemblies $references `
        -CompilerOptions "/nowarn:1701" `
        -PassThru `
        -ErrorAction Stop

    $hostType = @($types | Where-Object { $_.FullName -eq $typeName }) | Select-Object -First 1
    if ($null -eq $hostType) {
        throw "PowerShell plugin host type '$typeName' was not produced by Add-Type."
    }

    $state.PluginHostType = $hostType
    $state.PluginHostError = $null
    return $hostType
}

function Clear-PPFDotNetPluginProviders {

    $state = $script:PPFDotNetCore
    foreach ($entry in @($state.Plugins.Values)) {
        try {
            $entry.Provider.Dispose()
        }
        catch {
            Write-PPFLog -Level "DEBUG" -Message "PPF .NET plugin provider '$($entry.Type)' could not be disposed: $($_.Exception.Message)"
        }
    }

    $state.Plugins.Clear()
}

function Sync-PPFDotNetPluginProviders {

    $state = $script:PPFDotNetCore
    if (-not $state.Enabled -or $null -eq $state.Engine) {
        return
    }

    $version = if ($null -ne $script:PromptSegmentsVersion) {
        [int]$script:PromptSegmentsVersion
    }
    else {
        -1
    }

    if ($state.PluginRegistryVersion -eq $version) {
        return
    }

    $definitions = @(Get-PPFDotNetPluginDefinitions)
    $builtInTypes = @($state.Engine.Registry.Types)
    $activeNames = @(
        $definitions |
            Where-Object { $builtInTypes -notcontains $_.Name } |
            ForEach-Object { $_.Name }
    )

    foreach ($name in @($state.Plugins.Keys)) {
        if ($activeNames -notcontains $name) {
            $entry = $state.Plugins[$name]
            try {
                $entry.Provider.Dispose()
            }
            catch {
                Write-PPFLog -Level "DEBUG" -Message "PPF .NET plugin provider '$name' could not be disposed: $($_.Exception.Message)"
            }
            $state.Plugins.Remove($name)
        }
    }

    if ($activeNames.Count -eq 0) {
        $state.PluginRegistryVersion = $version
        $state.PluginHostError = $null
        return
    }

    $modulePath = Get-PPFDotNetModuleManifestPath
    if ([string]::IsNullOrWhiteSpace($modulePath)) {
        $state.PluginRegistryVersion = $version
        $state.PluginHostError = "The PablitusPrompt module manifest could not be located."
        return
    }

    $hostType = $null
    $syncError = $null

    foreach ($definition in @($definitions | Where-Object { $activeNames -contains $_.Name })) {
        $current = $state.Plugins[$definition.Name]
        if ($null -ne $current -and $current.Script -ceq $definition.Script) {
            continue
        }

        if ($null -ne $current) {
            try {
                $current.Provider.Dispose()
            }
            catch {
                Write-PPFLog -Level "DEBUG" -Message "PPF .NET plugin provider '$($definition.Name)' could not be disposed: $($_.Exception.Message)"
            }
            $state.Plugins.Remove($definition.Name)
        }

        if ($null -eq $hostType) {
            try {
                $hostType = Initialize-PPFDotNetPluginHost
            }
            catch {
                $syncError = $_.Exception.Message
                break
            }
        }

        try {
            $provider = [System.Activator]::CreateInstance($hostType, [object[]]@(
                $definition.Name,
                $definition.Name,
                $modulePath,
                $definition.Name,
                $definition.Script,
                $script:PPFDotNetPluginInvocationScript,
                $script:PPFDotNetPluginInitializationScript,
                2000
            ))

            $state.Engine.Registry.Register($provider)
            $state.Plugins[$definition.Name] = [pscustomobject]@{
                Provider = $provider
                Script   = $definition.Script
                Type     = $definition.Name
            }
        }
        catch {
            $syncError = $_.Exception.Message
            Write-PPFLog -Level "DEBUG" -Message "PPF .NET plugin provider '$($definition.Name)' could not be registered: $($_.Exception.Message)"
        }
    }

    $state.PluginRegistryVersion = $version
    $state.PluginHostError = $syncError
}

function Test-PPFDotNetCoreAvailable {

    [CmdletBinding()]
    param(
        [switch]$Refresh
    )

    $state = $script:PPFDotNetCore
    if ($state.AssemblyLoaded -and -not $Refresh) {
        return $true
    }

    $path = Resolve-PPFDotNetCoreAssemblyPath
    try {
        return (Test-Path -LiteralPath $path -PathType Leaf)
    }
    catch {
        return $false
    }
}

function Get-PPFDotNetCoreStatus {

    $state = $script:PPFDotNetCore
    $path = Resolve-PPFDotNetCoreAssemblyPath

    $available = $false
    try {
        $available = Test-Path -LiteralPath $path -PathType Leaf
    }
    catch {
        $available = $false
    }

    return [pscustomobject]@{
        PSTypeName        = "PablitusPrompt.DotNetCoreStatus"
        Enabled           = [bool]$state.Enabled
        Suppressed        = [bool]$state.Suppressed
        Available         = $available
        AssemblyPath      = $path
        AssemblyLoaded    = [bool]$state.AssemblyLoaded
        EngineReady       = ($null -ne $state.Engine -and $null -ne $state.Config)
        ThemePath         = $state.ThemePath
        ThemeKind         = $state.ThemeKind
        IgnoreUnsupported = [bool]$state.IgnoreUnsupported
        LastError         = $state.LastError
        LastErrorAt       = $state.LastErrorAt
        FallbackCount     = [int]$state.FallbackCount
        RenderCount       = [int]$state.RenderCount
        PluginCount       = [int]$state.Plugins.Count
        PluginTypes       = @($state.Plugins.Keys | Sort-Object)
        PluginHostReady   = ($null -ne $state.PluginHostType)
        PluginHostError   = $state.PluginHostError
    }
}

function Enable-PPFDotNetCore {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ThemePath,

        [switch]$IgnoreUnsupported
    )

    $fullPath = (Resolve-Path -LiteralPath $ThemePath -ErrorAction Stop).Path
    $null = Import-PPFDotNetCoreAssembly

    $loaded = Import-PPFDotNetThemeInternal -Path $fullPath -IgnoreUnsupported:$IgnoreUnsupported
    $engine = [PablitusPrompt.Core.PromptEngine]::new()

    $state = $script:PPFDotNetCore
    $state.Engine = $engine
    $state.Config = $loaded.Config
    $state.ThemePath = $fullPath
    $state.ThemeKind = $loaded.Kind
    $state.ThemeStamp = Get-PPFDotNetCoreThemeStamp -Path $fullPath
    $state.IgnoreUnsupported = [bool]$IgnoreUnsupported
    $state.Enabled = $true
    $state.Suppressed = $false
    $state.LastError = $null
    $state.LastErrorAt = $null
    $state.AutoEnableKey = $null
    $state.LastImportedPath = $fullPath
    $state.PluginHostError = $null

    Clear-PPFDotNetPluginProviders
    $state.PluginRegistryVersion = -1
    Sync-PPFDotNetPluginProviders

    Write-PPFLog -Level "DEBUG" -Message "PPF .NET core enabled with '$fullPath' ($($loaded.Kind))."
    return Get-PPFDotNetCoreStatus
}

function Disable-PPFDotNetCore {

    [CmdletBinding()]
    param()

    $state = $script:PPFDotNetCore
    Clear-PPFDotNetPluginProviders
    $state.PluginRegistryVersion = -1
    $state.PluginHostError = $null
    $state.Enabled = $false
    $state.Engine = $null
    $state.Config = $null
    $state.ThemePath = $null
    $state.ThemeKind = $null
    $state.ThemeStamp = $null
    $state.IgnoreUnsupported = $false
    $state.LastError = $null
    $state.LastErrorAt = $null
    $state.AutoEnableKey = $null

    # When the environment still requests the .NET core, an explicit Disable
    # must win until the caller enables it again.
    $state.Suppressed = ($env:PPF_USE_DOTNET_CORE -eq "1")

    Write-PPFLog -Level "DEBUG" -Message "PPF .NET core disabled."
    return Get-PPFDotNetCoreStatus
}

function Import-PPFDotNetTheme {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,

        [switch]$IgnoreUnsupported,

        [switch]$Activate
    )

    $fullPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $null = Import-PPFDotNetCoreAssembly

    $loaded = Import-PPFDotNetThemeInternal -Path $fullPath -IgnoreUnsupported:$IgnoreUnsupported
    $script:PPFDotNetCore.LastImportedPath = $fullPath

    if ($Activate) {
        $null = Enable-PPFDotNetCore -ThemePath $fullPath -IgnoreUnsupported:$IgnoreUnsupported
    }

    return $loaded.Config
}

function Test-PPFDotNetCoreEnabled {

    $state = $script:PPFDotNetCore
    if ($state.Enabled) {
        return $true
    }

    if ($env:PPF_USE_DOTNET_CORE -ne "1" -or $state.Suppressed) {
        return $false
    }

    $themePath = $env:PPF_DOTNET_THEME
    if ([string]::IsNullOrWhiteSpace($themePath)) {
        $themePath = $state.LastImportedPath
    }

    if ([string]::IsNullOrWhiteSpace($themePath)) {
        $state.LastError = "PPF_USE_DOTNET_CORE=1 requires a theme. Set PPF_DOTNET_THEME or call Enable-PPFDotNetCore -ThemePath <ruta>."
        $state.LastErrorAt = [datetime]::UtcNow
        return $false
    }

    $stamp = 0
    if (Test-Path -LiteralPath $themePath -PathType Leaf) {
        $stamp = (Get-Item -LiteralPath $themePath).LastWriteTimeUtc.Ticks
    }

    $key = "$themePath|$stamp"
    if ($state.AutoEnableKey -eq $key -and $state.LastError) {
        return $false
    }

    $state.AutoEnableKey = $key
    try {
        $null = Enable-PPFDotNetCore -ThemePath $themePath
        return $true
    }
    catch {
        $state.LastError = $_.Exception.Message
        $state.LastErrorAt = [datetime]::UtcNow
        Write-PPFLog -Level "DEBUG" -Message "PPF .NET core auto-enable failed: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-PPFDotNetPrompt {

    [CmdletBinding()]
    param(
        [string]$RendererOverride,

        [switch]$Transient,

        [string]$CommandLine,

        [int]$TerminalWidth = 0,

        [int]$Column = 0
    )

    $state = $script:PPFDotNetCore
    if (-not $state.Enabled -or $null -eq $state.Engine -or $null -eq $state.Config) {
        throw "PPF .NET core is not enabled. Call Enable-PPFDotNetCore or set PPF_USE_DOTNET_CORE=1 with PPF_DOTNET_THEME."
    }

    try {
        if ($state.ThemePath -and (Test-Path -LiteralPath $state.ThemePath -PathType Leaf)) {
            $stamp = Get-PPFDotNetCoreThemeStamp -Path $state.ThemePath
            if ($stamp -ne $state.ThemeStamp) {
                $loaded = Import-PPFDotNetThemeInternal -Path $state.ThemePath -IgnoreUnsupported:$state.IgnoreUnsupported
                $state.Config = $loaded.Config
                $state.ThemeKind = $loaded.Kind
                $state.ThemeStamp = $stamp
                Write-PPFLog -Level "DEBUG" -Message "PPF .NET theme reloaded from '$($state.ThemePath)'."
            }
        }

        Sync-PPFDotNetPluginProviders

        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
        $context = [PablitusPrompt.Core.Segments.PromptContextFactory]::Create(
            $PWD.Path,
            $exitCode,
            $TerminalWidth,
            $CommandLine,
            $false,
            $Column)

        $options = [PablitusPrompt.Core.PromptEngineOptions]::new()
        if (-not [string]::IsNullOrWhiteSpace($RendererOverride)) {
            $options.RendererOverride = $RendererOverride
        }
        $options.UseAnsi = $true
        $options.TerminalWidth = $TerminalWidth

        if ($Transient) {
            $renderMethod = $state.Engine.GetType().GetMethod(
                'RenderTransient',
                [System.Reflection.BindingFlags]'Public,Instance',
                $null,
                [Type[]]@($state.Config.GetType(), $context.GetType(), $options.GetType()),
                $null)
            try {
                $transientResult = $renderMethod.Invoke(
                    $state.Engine,
                    [object[]]@($state.Config, $context, $options))
            }
            catch {
                $state.LastError = $_.Exception.Message
                $state.LastErrorAt = [datetime]::UtcNow
                throw
            }

            $state.RenderCount = [int]$state.RenderCount + 1

            if ([string]::IsNullOrEmpty($transientResult)) {
                return [pscustomobject]@{ Output = $null; RightPrompt = $null }
            }

            return [pscustomobject]@{ Output = $transientResult; RightPrompt = $null }
        }

        $result = $state.Engine.RenderAsync(
            $state.Config,
            $context,
            $options,
            [System.Threading.CancellationToken]::None
        ).GetAwaiter().GetResult()

        $state.RenderCount = [int]$state.RenderCount + 1
        return [pscustomobject]@{
            Output      = $result.Output
            RightPrompt = $result.RightPrompt
        }
    }
    catch {
        $state.LastError = $_.Exception.Message
        $state.LastErrorAt = [datetime]::UtcNow
        throw
    }
}

function Invoke-PPFDotNetTooltip {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,

        [int]$TerminalWidth = 0,

        [int]$Column = 0
    )

    $state = $script:PPFDotNetCore
    if (-not $state.Enabled -or $null -eq $state.Engine -or $null -eq $state.Config) {
        throw "PPF .NET core is not enabled. Call Enable-PPFDotNetCore or set PPF_USE_DOTNET_CORE=1 with PPF_DOTNET_THEME."
    }

    try {
        if ($state.ThemePath -and (Test-Path -LiteralPath $state.ThemePath -PathType Leaf)) {
            $stamp = Get-PPFDotNetCoreThemeStamp -Path $state.ThemePath
            if ($stamp -ne $state.ThemeStamp) {
                $loaded = Import-PPFDotNetThemeInternal -Path $state.ThemePath -IgnoreUnsupported:$state.IgnoreUnsupported
                $state.Config = $loaded.Config
                $state.ThemeKind = $loaded.Kind
                $state.ThemeStamp = $stamp
                Write-PPFLog -Level "DEBUG" -Message "PPF .NET theme reloaded from '$($state.ThemePath)'."
            }
        }

        Sync-PPFDotNetPluginProviders

        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
        $context = [PablitusPrompt.Core.Segments.PromptContextFactory]::Create(
            $PWD.Path,
            $exitCode,
            $TerminalWidth,
            $Command,
            $false,
            $Column)

        $options = [PablitusPrompt.Core.PromptEngineOptions]::new()
        $options.UseAnsi = $true
        $options.TerminalWidth = $TerminalWidth

        $tooltip = $state.Engine.RenderTooltipAsync(
            $state.Config,
            $context,
            $Command,
            $TerminalWidth,
            $Column,
            $options,
            [System.Threading.CancellationToken]::None
        ).GetAwaiter().GetResult()

        $state.RenderCount = [int]$state.RenderCount + 1

        return [pscustomobject]@{
            Output       = $tooltip.Output
            Text         = $tooltip.Text
            RightPrompt  = $tooltip.RightPrompt
            Action       = $tooltip.Action
            MatchedSegments = $tooltip.MatchedSegments
        }
    }
    catch {
        $state.LastError = $_.Exception.Message
        $state.LastErrorAt = [datetime]::UtcNow
        throw
    }
}
