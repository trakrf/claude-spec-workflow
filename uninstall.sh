#!/bin/bash

# Claude Spec Workflow Uninstaller
# https://github.com/trakrf/claude-spec-workflow

set -e

CLAUDE_COMMANDS_DIR="$HOME/.config/claude/commands"
COMMANDS=("spec.md" "plan.md" "build.md" "check.md" "ship.md")

echo "🗑️  Uninstalling Claude Spec Workflow Commands"
echo "============================================"

# Remove each command
removed=0
for cmd in "${COMMANDS[@]}"; do
    cmd_path="$CLAUDE_COMMANDS_DIR/$cmd"
    if [ -f "$cmd_path" ]; then
        rm "$cmd_path"
        echo "   ✓ Removed $cmd"
        ((removed++))
    fi
done

if [ $removed -eq 0 ]; then
    echo "ℹ️  No commands found to remove"
else
    echo ""
    echo "✅ Uninstalled $removed commands"
fi

echo ""
echo "Note: Project spec/ directories remain untouched"
echo "      Remove them manually if desired"
