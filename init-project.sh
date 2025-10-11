#!/bin/bash

# Initialize a project for spec-driven development
# Usage: ./init-project.sh [project-path]

set -e

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(dirname "$0")"

echo "🏗️  Initializing Spec-Driven Development"
echo "======================================"

# Create spec directory structure
echo "📁 Creating spec directories..."
mkdir -p "$PROJECT_DIR/spec/active"
touch "$PROJECT_DIR/spec/SHIPPED.md"

# Copy templates if they don't exist
if [ ! -f "$PROJECT_DIR/spec/template.md" ]; then
    echo "📄 Copying spec template..."
    cp "$SCRIPT_DIR/templates/spec-template.md" "$PROJECT_DIR/spec/template.md"
fi

if [ ! -f "$PROJECT_DIR/spec/README.md" ]; then
    echo "📄 Copying spec README..."
    cp "$SCRIPT_DIR/templates/README.md" "$PROJECT_DIR/spec/README.md"
fi

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
echo "Next steps:"
echo "1. Create your first spec:"
echo "   cd $PROJECT_DIR"
echo "   mkdir spec/active/my-feature"
echo "   cp spec/template.md spec/active/my-feature/spec.md"
echo ""
echo "2. Edit the spec with your requirements"
echo ""
echo "3. Generate implementation plan:"
echo "   /plan spec/active/my-feature/spec.md"
