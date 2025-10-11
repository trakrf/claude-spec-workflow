# Claude Spec Workflow Uninstaller for Windows
# https://github.com/trakrf/claude-spec-workflow

$ErrorActionPreference = "Stop"

$CLAUDE_COMMANDS_DIR = "$env:APPDATA\claude\commands"
$COMMANDS = @("spec.md", "plan.md", "build.md", "check.md", "ship.md")

Write-Host "🗑️  Uninstalling Claude Spec Workflow Commands" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Remove each command
$removed = 0
foreach ($cmd in $COMMANDS) {
    $cmdPath = Join-Path $CLAUDE_COMMANDS_DIR $cmd
    if (Test-Path $cmdPath) {
        Remove-Item $cmdPath -Force
        Write-Host "   ✓ Removed $cmd" -ForegroundColor Green
        $removed++
    }
}

if ($removed -eq 0) {
    Write-Host "ℹ️  No commands found to remove" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Uninstalled $removed commands" -ForegroundColor Green
}

Write-Host ""
Write-Host "Note: Project spec\ directories remain untouched"
Write-Host "      Remove them manually if desired"
