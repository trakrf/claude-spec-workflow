# Claude Spec Workflow Installer for Windows
# https://github.com/trakrf/claude-spec-workflow

$ErrorActionPreference = "Stop"

$CLAUDE_COMMANDS_DIR = "$env:USERPROFILE\.claude\commands"
$REPO_COMMANDS_DIR = Join-Path $PSScriptRoot "commands"

Write-Host "🚀 Installing Claude Spec Workflow Commands" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if running from the right directory
if (-not (Test-Path $REPO_COMMANDS_DIR)) {
    Write-Host "❌ Error: commands directory not found!" -ForegroundColor Red
    Write-Host "   Please run this script from the claude-spec-workflow directory" -ForegroundColor Yellow
    exit 1
}

# Create Claude commands directory if it doesn't exist
if (-not (Test-Path $CLAUDE_COMMANDS_DIR)) {
    Write-Host "📁 Creating Claude commands directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $CLAUDE_COMMANDS_DIR -Force | Out-Null
}

# Install commands
Write-Host "📦 Installing commands..." -ForegroundColor Yellow
Get-ChildItem -Path $REPO_COMMANDS_DIR -Filter "*.md" | ForEach-Object {
    $target = Join-Path $CLAUDE_COMMANDS_DIR $_.Name
    if (Test-Path $target) {
        Write-Host "   ↻ Updated $($_.Name)" -ForegroundColor Cyan
    } else {
        Write-Host "   ✓ Installed $($_.Name)" -ForegroundColor Green
    }
    Copy-Item $_.FullName -Destination $target -Force
}

# Project setup instructions
Write-Host ""
Write-Host "📋 Project Setup Instructions:" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Cyan
Write-Host "Initialize the spec workflow in your project:"
Write-Host ""
Write-Host "  .\init-project.ps1 C:\path\to\your-project [preset]"
Write-Host ""
Write-Host "Available presets:"
Get-ChildItem -Path (Join-Path $PSScriptRoot "presets") -Filter "*.md" | ForEach-Object {
    Write-Host "  - $($_.BaseName)"
}
Write-Host ""
Write-Host "Example:"
Write-Host "  .\init-project.ps1 ~\my-app default"
Write-Host ""

Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:"
Write-Host "  /spec   - Convert conversation to specification"
Write-Host "  /plan   - Generate implementation plan (interactive)"
Write-Host "  /build  - Execute implementation with validation"
Write-Host "  /check  - Pre-release validation check"
Write-Host "  /ship   - Complete feature and prepare PR"
Write-Host ""
Write-Host "Get started: Create a spec in spec\active\feature-name\spec.md"
Write-Host "Then run: /plan spec/active/feature-name/spec.md"
