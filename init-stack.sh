#!/bin/bash

# Initialize stack-specific configuration
# Usage: ./init-stack.sh [preset-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET="${1}"

echo "🔧 Initializing Stack Configuration"
echo "==================================="

if [ -z "$PRESET" ]; then
    echo "Available presets:"
    echo ""
    for preset in "$SCRIPT_DIR/presets"/*.md; do
        if [ -f "$preset" ]; then
            name=$(basename "$preset" .md)
            echo "  - $name"
        fi
    done
    echo ""
    echo "Usage: ./init-stack.sh <preset-name>"
    echo "   or: ./init-stack.sh custom (to create your own)"
    exit 1
fi

if [ "$PRESET" = "custom" ]; then
    echo "Creating custom configuration..."
    cp "$SCRIPT_DIR/templates/config-template.md" spec/config.md
    echo "✅ Created spec/config.md - please edit with your project details"
else
    PRESET_FILE="$SCRIPT_DIR/presets/$PRESET.md"
    if [ ! -f "$PRESET_FILE" ]; then
        echo "❌ Error: Preset '$PRESET' not found"
        exit 1
    fi

    cp "$PRESET_FILE" spec/config.md
    echo "✅ Initialized with $PRESET configuration"
fi

echo ""
echo "Configuration saved to spec/config.md"
echo "You can customize it further if needed"
