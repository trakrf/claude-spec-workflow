#!/bin/bash

# Initialize a project for spec-driven development
# Usage: ./init-project.sh [project-path] [preset]
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

set -e

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PRESET="typescript-react-vite"
PRESET="${2:-$DEFAULT_PRESET}"

# Handle 'default' literal
if [[ $PRESET == "default" ]]; then
  PRESET=$DEFAULT_PRESET
fi

# Check if PRESET is a file path (contains /)
if [[ $PRESET == */* ]]; then
  # It's a path, use it directly
  PRESET_FILE="$PRESET"
  # Add .md extension if not present
  if [[ ! $PRESET_FILE =~ \.md$ ]]; then
    PRESET_FILE="${PRESET_FILE}.md"
  fi
else
  # It's a preset name, look in presets directory
  # Strip .md extension if user provided it
  if [[ $PRESET =~ \.md$ ]]; then
    PRESET="${PRESET%.md}"
  fi
  PRESET_FILE="$SCRIPT_DIR/presets/$PRESET.md"
fi

# Validate preset exists
if [ ! -f "$PRESET_FILE" ]; then
    echo "❌ Error: Preset '$PRESET' not found"
    echo ""
    echo "Available presets:"
    for preset in "$SCRIPT_DIR/presets"/*.md; do
        basename "$preset" .md | sed 's/^/  - /'
    done
    exit 1
fi

echo "🏗️  Initializing Spec-Driven Development"
echo "======================================"
echo "Project: $PROJECT_DIR"
echo "Preset: $PRESET"
echo ""

# Create spec directory structure
echo "📁 Creating spec directories..."
mkdir -p "$PROJECT_DIR/spec/active"

# Initialize SHIPPED.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/spec/SHIPPED.md" ]; then
    touch "$PROJECT_DIR/spec/SHIPPED.md"
fi

# Check for existing files and prompt for overwrite
FILES_TO_OVERWRITE=()

if [ -f "$PROJECT_DIR/spec/stack.md" ]; then
    FILES_TO_OVERWRITE+=("spec/stack.md")
fi

if [ -f "$PROJECT_DIR/spec/template.md" ]; then
    FILES_TO_OVERWRITE+=("spec/template.md")
fi

if [ -f "$PROJECT_DIR/spec/README.md" ]; then
    FILES_TO_OVERWRITE+=("spec/README.md")
fi

# Prompt if files exist
if [ ${#FILES_TO_OVERWRITE[@]} -gt 0 ]; then
    echo "⚠️  The following files already exist and will be overwritten:"
    for file in "${FILES_TO_OVERWRITE[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "You can revert changes with: git checkout -- spec/"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
    echo ""
fi

# Copy stack configuration from preset
echo "📄 Copying stack configuration ($PRESET)..."
cp "$PRESET_FILE" "$PROJECT_DIR/spec/stack.md"

# Copy spec template
echo "📄 Copying spec template..."
cp "$SCRIPT_DIR/templates/spec-template.md" "$PROJECT_DIR/spec/template.md"

# Copy spec README
echo "📄 Copying spec README..."
cp "$SCRIPT_DIR/templates/README.md" "$PROJECT_DIR/spec/README.md"

# Add to .gitignore if it exists
if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q "spec/active/\*/log.md" "$PROJECT_DIR/.gitignore"; then
        echo "📝 Adding spec logs to .gitignore..."
        echo -e "\n# Spec workflow logs\nspec/active/*/log.md" >> "$PROJECT_DIR/.gitignore"
    fi
fi

echo ""
echo "✅ Project initialized for spec-driven development!"
echo ""
echo "Stack configured: $PRESET"
echo "  - Review and customize: spec/stack.md"
echo ""
echo "Next steps:"
echo "1. Create your first spec:"
echo "   cd $PROJECT_DIR"
echo "   mkdir spec/active/my-feature"
echo "   cp spec/template.md spec/active/my-feature/spec.md"
echo ""
echo "2. Edit the spec with your requirements"
echo ""
echo "3. Generate implementation plan:"
echo "   /plan spec/active/my-feature"
echo ""
echo "To change your stack configuration later, either:"
echo "  - Edit spec/stack.md directly, or"
echo "  - Re-run: ./init-project.sh . [different-preset]"
