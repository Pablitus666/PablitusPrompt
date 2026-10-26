# ============================================================
# Pablitus Prompt Framework (PPF)
# Build-PPFDotNetCore.ps1
#
# Publishes the .NET core to dotnet/publish so the PowerShell adapter can
# load it without invoking the CLI. Do not call this from a profile or from
# the prompt hot path.
# ============================================================

[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$OutputPath,

    [switch]$NoRestore
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "dotnet/src/PablitusPrompt.Core/PablitusPrompt.Core.csproj"

if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
    throw "Core project not found at '$projectPath'."
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot "dotnet/publish"
}

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "The .NET SDK is required. Install .NET 8 or add 'dotnet' to PATH."
}

$arguments = @(
    "publish"
    $projectPath
    "--configuration"
    $Configuration
    "--output"
    $OutputPath
    "--nologo"
)

if ($NoRestore) {
    $arguments += "--no-restore"
}

Write-Host "Publishing PPF .NET core ($Configuration) to '$OutputPath'..." -ForegroundColor Cyan
& dotnet @arguments

if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

$assemblyPath = Join-Path $OutputPath "PablitusPrompt.Core.dll"
if (-not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw "Publish completed but '$assemblyPath' was not found."
}

$result = [pscustomobject]@{
    Configuration = $Configuration
    OutputPath    = $OutputPath
    AssemblyPath  = $assemblyPath
    SizeBytes     = (Get-Item -LiteralPath $assemblyPath).Length
    PublishedAt   = [datetime]::UtcNow
}

Write-Host "Published: $($result.AssemblyPath) ($($result.SizeBytes) bytes)" -ForegroundColor Green
return $result
