# Initialize stack-specific configuration (Windows)
# Usage: .\init-stack.ps1 [preset-name]

param(
    [string]$Preset
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot

Write-Host "🔧 Initializing Stack Configuration" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

if (-not $Preset) {
    Write-Host "Available presets:" -ForegroundColor Yellow
    Write-Host ""
    Get-ChildItem -Path (Join-Path $SCRIPT_DIR "presets") -Filter "*.md" | ForEach-Object {
        $name = $_.BaseName
        Write-Host "  - $name" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Usage: .\init-stack.ps1 <preset-name>"
    Write-Host "   or: .\init-stack.ps1 custom (to create your own)"
    exit 1
}

if ($Preset -eq "custom") {
    Write-Host "Creating custom configuration..." -ForegroundColor Yellow
    $templateSrc = Join-Path $SCRIPT_DIR "templates\config-template.md"
    Copy-Item $templateSrc -Destination "spec\config.md"
    Write-Host "✅ Created spec\config.md - please edit with your project details" -ForegroundColor Green
} else {
    $presetFile = Join-Path $SCRIPT_DIR "presets\$Preset.md"
    if (-not (Test-Path $presetFile)) {
        Write-Host "❌ Error: Preset '$Preset' not found" -ForegroundColor Red
        exit 1
    }

    Copy-Item $presetFile -Destination "spec\config.md"
    Write-Host "✅ Initialized with $Preset configuration" -ForegroundColor Green
}

Write-Host ""
Write-Host "Configuration saved to spec\config.md"
Write-Host "You can customize it further if needed"
