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

# Detect project stack by inspecting project files
detect_project_stack() {
    local project_dir="$1"

    # Check for Node.js projects
    if [[ -f "$project_dir/package.json" ]]; then
        if grep -q '"vite"' "$project_dir/package.json" 2>/dev/null; then
            echo "typescript-react-vite"
            return 0
        elif grep -q '"next"' "$project_dir/package.json" 2>/dev/null; then
            echo "nextjs-app-router"
            return 0
        else
            # Generic Node.js project, default to React+Vite
            echo "typescript-react-vite"
            return 0
        fi
    fi

    # Check for Python projects
    if [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/pyproject.toml" ]]; then
        echo "python-fastapi"
        return 0
    fi

    # Check for Go projects
    if [[ -f "$project_dir/go.mod" ]]; then
        echo "go-standard"
        return 0
    fi

    # Check for shell script projects (look for multiple .sh files)
    local sh_count
    sh_count=$(find "$project_dir" -maxdepth 2 -name "*.sh" -type f 2>/dev/null | wc -l)
    if [[ $sh_count -gt 2 ]]; then
        echo "shell-scripts"
        return 0
    fi

    # Could not detect, return empty
    return 1
}

# Get human-readable stack name from preset identifier
get_stack_display_name() {
    local preset="$1"
    case "$preset" in
        "typescript-react-vite") echo "TypeScript + React + Vite" ;;
        "nextjs-app-router") echo "Next.js App Router + TypeScript" ;;
        "python-fastapi") echo "Python + FastAPI" ;;
        "go-standard") echo "Go" ;;
        "monorepo-go-react") echo "Go + React Monorepo" ;;
        "shell-scripts") echo "Shell Scripts (Bash)" ;;
        *) echo "$preset" ;;
    esac
}

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

# Create spec/csw symlink for project-local csw access
echo "🔗 Creating spec/csw symlink..."
CSW_BIN="$SCRIPT_DIR/bin/csw"
if [ -f "$CSW_BIN" ]; then
    ln -sf "$CSW_BIN" "$PROJECT_DIR/spec/csw"
    echo "   ✓ Created: spec/csw -> $CSW_BIN"
else
    echo "   ⚠️  Warning: csw binary not found at $CSW_BIN"
    echo "   Run install.sh to set up csw CLI"
fi

# Generate bootstrap validation spec
echo ""
echo "📝 Creating bootstrap validation spec..."

# Check if spec directory already has content (reinit scenario)
if [[ -d "$PROJECT_DIR/spec" ]] && [[ $(find "$PROJECT_DIR/spec" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) -gt 0 ]]; then
    echo ""
    echo "⚠️  Spec directory already has content (existing features or previous init)"
    read -p "Create bootstrap spec anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping bootstrap spec creation."
        SKIP_BOOTSTRAP=1
    fi
fi

if [[ -z "$SKIP_BOOTSTRAP" ]]; then
    BOOTSTRAP_DIR="$PROJECT_DIR/spec/bootstrap"
    mkdir -p "$BOOTSTRAP_DIR"

    # Get current date
    CURRENT_DATE=$(date +%Y-%m-%d)

    # Get human-readable stack name
    STACK_NAME=$(get_stack_display_name "$PRESET")

    # Copy and populate template
    if [[ -f "$SCRIPT_DIR/templates/bootstrap-spec.md" ]]; then
        cp "$SCRIPT_DIR/templates/bootstrap-spec.md" "$BOOTSTRAP_DIR/spec.md"

        # Replace placeholders (use | as delimiter to avoid issues with /)
        sed -i "s|{{STACK_NAME}}|$STACK_NAME|g" "$BOOTSTRAP_DIR/spec.md"
        sed -i "s|{{PRESET_NAME}}|$PRESET|g" "$BOOTSTRAP_DIR/spec.md"
        sed -i "s|{{INSTALL_DATE}}|$CURRENT_DATE|g" "$BOOTSTRAP_DIR/spec.md"

        echo "   ✓ Bootstrap spec created at spec/bootstrap/spec.md"
    else
        echo "   ⚠️  Warning: Bootstrap template not found at $SCRIPT_DIR/templates/bootstrap-spec.md"
        echo "   Bootstrap spec creation skipped."
    fi
fi

echo ""
echo "✅ Claude Spec Workflow Setup Complete!"
echo ""
echo "📂 Directory structure:"
echo "   spec/"
echo "   ├── README.md       # Workflow documentation"
echo "   ├── template.md     # Spec template"
echo "   ├── stack.md        # $STACK_NAME validation commands"
echo "   ├── SHIPPED.md      # Completed features log"

if [[ -z "$SKIP_BOOTSTRAP" ]]; then
    echo "   └── bootstrap/      # Bootstrap validation spec ⭐"
    echo ""
    echo "🚀 Next: Validate installation by shipping the bootstrap spec"
    echo ""
    echo "   Run these commands in Claude Code:"
    echo ""
    echo "   1. Generate plan:      /plan bootstrap"
    echo "   2. Execute plan:       /build"
    echo "   3. Validate quality:   /check"
    echo "   4. Ship it:            /ship"
    echo ""
    echo "   This will:"
    echo "     • Validate CSW installation works correctly"
    echo "     • Commit CSW infrastructure using CSW itself (meta!)"
    echo "     • Create your first SHIPPED.md entry"
    echo "     • Give you hands-on experience with the workflow"
else
    echo ""
fi

echo ""
echo "Stack configured: $PRESET"
echo "  - Review and customize: spec/stack.md"
echo ""
echo "📖 Learn more: spec/README.md"
echo ""

# Show alternative access methods
if [[ -L "$PROJECT_DIR/spec/csw" ]]; then
    echo "💡 Three ways to run commands:"
    echo "   - In Claude Code:  /plan my-feature"
    echo "   - In terminal:     csw plan my-feature"
    echo "   - In project:      ./spec/csw plan my-feature"
    echo ""
fi
