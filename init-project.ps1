# Initialize a project for spec-driven development (Windows)
# Usage: .\init-project.ps1 [project-path] [preset]
#
# Arguments:
#   project-path: Target directory (default: current directory)
#   preset: Stack preset to use (default: typescript-react-vite)
#
# Available presets:
#   - typescript-react-vite (default)
#   - nextjs-app-router
#   - python-fastapi
#   - go-standard
#   - monorepo-go-react

param(
    [string]$ProjectDir = ".",
    [string]$Preset = "typescript-react-vite"
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
$DEFAULT_PRESET = "typescript-react-vite"

# Handle 'default' literal
if ($Preset -eq "default") {
    $Preset = $DEFAULT_PRESET
}

# Check if PRESET is a file path (contains / or \)
if ($Preset -match '[/\\]') {
    # It's a path, use it directly
    $presetFile = $Preset
    # Add .md extension if not present
    if ($presetFile -notmatch '\.md$') {
        $presetFile = "$presetFile.md"
    }
} else {
    # It's a preset name, look in presets directory
    # Strip .md extension if user provided it
    if ($Preset -match '\.md$') {
        $Preset = $Preset -replace '\.md$', ''
    }
    $presetFile = Join-Path $SCRIPT_DIR "presets\$Preset.md"
}

# Validate preset exists
if (-not (Test-Path $presetFile)) {
    Write-Host "❌ Error: Preset '$Preset' not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available presets:"
    Get-ChildItem -Path (Join-Path $SCRIPT_DIR "presets") -Filter "*.md" | ForEach-Object {
        Write-Host "  - $($_.BaseName)"
    }
    exit 1
}

Write-Host "🏗️  Initializing Spec-Driven Development" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectDir"
Write-Host "Preset: $Preset"
Write-Host ""

# Create spec directory structure
Write-Host "📁 Creating spec directories..." -ForegroundColor Yellow
$specActiveDir = Join-Path $ProjectDir "spec\active"
New-Item -ItemType Directory -Path $specActiveDir -Force | Out-Null

# Initialize SHIPPED.md if it doesn't exist
$shippedFile = Join-Path $ProjectDir "spec\SHIPPED.md"
if (-not (Test-Path $shippedFile)) {
    New-Item -ItemType File -Path $shippedFile -Force | Out-Null
}

# Check for existing files and prompt for overwrite
$filesToOverwrite = @()

$stackMd = Join-Path $ProjectDir "spec\stack.md"
if (Test-Path $stackMd) {
    $filesToOverwrite += "spec\stack.md"
}

$templateMd = Join-Path $ProjectDir "spec\template.md"
if (Test-Path $templateMd) {
    $filesToOverwrite += "spec\template.md"
}

$readmeMd = Join-Path $ProjectDir "spec\README.md"
if (Test-Path $readmeMd) {
    $filesToOverwrite += "spec\README.md"
}

# Prompt if files exist
if ($filesToOverwrite.Count -gt 0) {
    Write-Host "⚠️  The following files already exist and will be overwritten:" -ForegroundColor Yellow
    foreach ($file in $filesToOverwrite) {
        Write-Host "   - $file"
    }
    Write-Host ""
    Write-Host "You can revert changes with: git checkout -- spec/"
    Write-Host ""
    $response = Read-Host "Continue? (y/n)"
    if ($response -notmatch "^[Yy]$") {
        Write-Host "Cancelled."
        exit 1
    }
    Write-Host ""
}

# Copy stack configuration from preset
Write-Host "📄 Copying stack configuration ($Preset)..." -ForegroundColor Yellow
Copy-Item $presetFile -Destination $stackMd -Force

# Copy spec template
Write-Host "📄 Copying spec template..." -ForegroundColor Yellow
$templateSrc = Join-Path $SCRIPT_DIR "templates\spec-template.md"
Copy-Item $templateSrc -Destination $templateMd -Force

# Copy spec README
Write-Host "📄 Copying spec README..." -ForegroundColor Yellow
$readmeSrc = Join-Path $SCRIPT_DIR "templates\README.md"
Copy-Item $readmeSrc -Destination $readmeMd -Force

# Add to .gitignore if it exists
$gitignorePath = Join-Path $ProjectDir ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -notmatch "spec/active/\*/log\.md") {
        Write-Host "📝 Adding spec logs to .gitignore..." -ForegroundColor Yellow
        Add-Content -Path $gitignorePath -Value "`n# Spec workflow logs`nspec/active/*/log.md"
    }
}

Write-Host ""
Write-Host "✅ Project initialized for spec-driven development!" -ForegroundColor Green
Write-Host ""
Write-Host "Stack configured: $Preset"
Write-Host "  - Review and customize: spec\stack.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Create your first spec:"
Write-Host "   cd $ProjectDir"
Write-Host "   mkdir spec\active\my-feature"
Write-Host "   Copy-Item spec\template.md spec\active\my-feature\spec.md"
Write-Host ""
Write-Host "2. Edit the spec with your requirements"
Write-Host ""
Write-Host "3. Generate implementation plan:"
Write-Host "   /plan spec/active/my-feature"
Write-Host ""
Write-Host "To change your stack configuration later, either:"
Write-Host "  - Edit spec\stack.md directly, or"
Write-Host "  - Re-run: .\init-project.ps1 . [different-preset]"
