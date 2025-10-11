#!/bin/bash

# Claude Spec Workflow Installer
# https://github.com/trakrf/claude-spec-workflow

set -e

CLAUDE_COMMANDS_DIR="$HOME/.config/claude/commands"
REPO_COMMANDS_DIR="$(dirname "$0")/commands"

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
        cp "$cmd" "$CLAUDE_COMMANDS_DIR/$filename"
        echo "   ✓ Installed $filename"
    fi
done

# Create project spec directory template
echo ""
echo "📋 Project Setup Instructions:"
echo "------------------------------"
echo "In your project directory, create:"
echo ""
echo "  mkdir -p spec/active"
echo "  touch spec/SHIPPED.md"
echo ""
echo "Optionally, copy templates:"
echo "  cp $(pwd)/templates/spec-template.md spec/template.md"
echo "  cp $(pwd)/templates/README.md spec/README.md"
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
