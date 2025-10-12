#!/bin/bash

# Claude Spec Workflow Installer
# https://github.com/trakrf/claude-spec-workflow

set -e

CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_COMMANDS_DIR="$SCRIPT_DIR/commands"

echo "🚀 Installing Claude Spec Workflow Commands"
echo "=========================================="

# Check if running from the right directory
if [ ! -d "$REPO_COMMANDS_DIR" ]; then
    echo "❌ Error: commands directory not found!"
    echo "   Please run this script from the claude-spec-workflow directory"
    exit 1
fi

# Create Claude commands directory if it doesn't exist
if [ ! -d "$CLAUDE_COMMANDS_DIR" ]; then
    echo "📁 Creating Claude commands directory..."
    mkdir -p "$CLAUDE_COMMANDS_DIR"
fi

# Install commands
echo "📦 Installing commands..."
for cmd in "$REPO_COMMANDS_DIR"/*.md; do
    if [ -f "$cmd" ]; then
        filename=$(basename "$cmd")
        target="$CLAUDE_COMMANDS_DIR/$filename"
        if [ -f "$target" ]; then
            echo "   ↻ Updated $filename"
        else
            echo "   ✓ Installed $filename"
        fi
        cp "$cmd" "$target"
    fi
done

# Create project spec directory template
echo ""
echo "📋 Project Setup Instructions:"
echo "------------------------------"
echo "Initialize the spec workflow in your project:"
echo ""
echo "  $(dirname $0)/init-project.sh /path/to/your-project [preset]"
echo ""
echo "Available presets:"
for preset in "$REPO_COMMANDS_DIR/../presets"/*.md; do
    basename "$preset" .md | sed 's/^/  - /'
done
echo ""
echo "Example:"
echo "  $(dirname $0)/init-project.sh ~/my-app default"
echo ""

echo "✅ Installation complete!"
echo ""
echo "Available commands:"
echo "  /spec   - Convert conversation to specification"
echo "  /plan   - Generate implementation plan (interactive)"
echo "  /build  - Execute implementation with validation"
echo "  /check  - Pre-release validation check"
echo "  /ship   - Complete feature and prepare PR"
echo ""
echo "Get started: Create a spec in spec/active/feature-name/spec.md"
echo "Then run: /plan spec/active/feature-name/spec.md"
