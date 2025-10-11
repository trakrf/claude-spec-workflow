# Initialize a project for spec-driven development (Windows)
# Usage: .\init-project.ps1 [project-path]

param(
    [string]$ProjectDir = "."
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot

Write-Host "🏗️  Initializing Spec-Driven Development" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Create spec directory structure
Write-Host "📁 Creating spec directories..." -ForegroundColor Yellow
$specActiveDir = Join-Path $ProjectDir "spec\active"
New-Item -ItemType Directory -Path $specActiveDir -Force | Out-Null
$shippedFile = Join-Path $ProjectDir "spec\SHIPPED.md"
New-Item -ItemType File -Path $shippedFile -Force | Out-Null

# Copy templates if they don't exist
$templateDest = Join-Path $ProjectDir "spec\template.md"
if (-not (Test-Path $templateDest)) {
    Write-Host "📄 Copying spec template..." -ForegroundColor Yellow
    $templateSrc = Join-Path $SCRIPT_DIR "templates\spec-template.md"
    Copy-Item $templateSrc -Destination $templateDest
}

$readmeDest = Join-Path $ProjectDir "spec\README.md"
if (-not (Test-Path $readmeDest)) {
    Write-Host "📄 Copying spec README..." -ForegroundColor Yellow
    $readmeSrc = Join-Path $SCRIPT_DIR "templates\README.md"
    Copy-Item $readmeSrc -Destination $readmeDest
}

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
Write-Host "Next steps:"
Write-Host "1. Create your first spec:"
Write-Host "   cd $ProjectDir"
Write-Host "   mkdir spec\active\my-feature"
Write-Host "   Copy-Item spec\template.md spec\active\my-feature\spec.md"
Write-Host ""
Write-Host "2. Edit the spec with your requirements"
Write-Host ""
Write-Host "3. Generate implementation plan:"
Write-Host "   /plan spec/active/my-feature/spec.md"
