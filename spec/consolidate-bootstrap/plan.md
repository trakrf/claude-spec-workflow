# Implementation Plan: Consolidate Bootstrap into csw
Generated: 2025-10-15
Specification: spec.md

## Understanding

This feature consolidates the bootstrap experience by:
1. Moving `bin/csw` to project root for maximum discoverability (`./csw install`)
2. Adding `csw install` subcommand to replace `install.sh`
3. Adding `csw init` subcommand to replace `init-project.sh`
4. Adding `csw uninstall` subcommand to replace `uninstall.sh`
5. Deleting old bootstrap scripts (install.sh, init-project.sh, uninstall.sh)
6. Updating all documentation to reference new paths

**Key Design Decisions** (from clarifications):
- Defer spec/active/ vs spec/ structure changes to separate work
- Bootstrap spec is **default for everyone** (beginners, power users, monorepos)
  - Beginners: Learn workflow through guided setup
  - Monorepos: Customize multi-workspace stack.md configurations
  - Power users: Validate installation, customize as needed
  - Explicit `--no-bootstrap-spec` flag to opt-out (rare)
- Preset selection orthogonal to bootstrap (can specify preset AND get bootstrap)
- Use bash fuzzy matching for presets (not Claude API integration)
- Use positive logic: CREATE_BOOTSTRAP=true (clearer than NO_BOOTSTRAP=false)
- Install is idempotent (detect existing, update/confirm)
- After move: CSW_HOME uses single dirname (not double)
- spec/csw symlink always points to direct path (fallback use case)
- Add CHANGELOG entry with placeholder version
- No migration docs needed (self-dogfooding)
- Use shellcheck for validation during implementation only
- Include uninstall subcommand (minimal scope, completes trilogy)

## Relevant Files

**Reference Patterns** (existing code to follow):
- `scripts/cleanup.sh` (lines 1-124) - Script structure with lib imports, main() pattern, colored output
- `scripts/plan.sh` (lines 1-124) - Branch setup logic, git operations, prompting patterns
- `scripts/lib/common.sh` (lines 1-60) - Output functions (info, success, error, warning), path helpers
- `scripts/lib/git.sh` - Git utility functions (get_current_branch, get_main_branch, etc.)
- `install.sh` (lines 1-98) - Current install logic to preserve
- `init-project.sh` (lines 1-281) - Current init logic to preserve
- `uninstall.sh` (lines 1-35) - Current uninstall logic to migrate

**Files to Modify**:
- `bin/csw` → `csw` (move to root) - Add install/init/uninstall cases, update CSW_HOME calculation
- `README.md` (lines 75-93, 450-454, 602-621) - Update installation instructions, uninstall section, add backlog item
- `CONTRIBUTING.md` (lines 34-50) - Update dev setup instructions
- `TESTING.md` - Update test instructions (references to install.sh)
- `CHANGELOG.md` - Add entry for breaking changes
- `commands/*.md` (5 files) - Update any install.sh references
- `install.sh` - DELETE after migration
- `init-project.sh` - DELETE after migration
- `uninstall.sh` - DELETE after migration

**Files to Keep Unchanged**:
- `templates/bootstrap-spec.md` - Referenced by csw init, format stays same
- `presets/*.md` (6 files) - Preset files unchanged
- `scripts/lib/*.sh` - Library functions unchanged

## Architecture Impact

- **Subsystems affected**: Bootstrap/installation only (CLI wrapper)
- **New dependencies**: None
- **Breaking changes**:
  - `./install.sh` → `./csw install`
  - `./init-project.sh <dir>` → `csw init <dir>`
  - `./uninstall.sh` → `csw uninstall`
  - `bin/csw` → `csw` (symlinks need updating)

## Task Breakdown

### Task 1: Move bin/csw to project root
**File**: bin/csw → csw
**Action**: MOVE + MODIFY

**Implementation**:
```bash
# Move file
mv bin/csw csw

# Update CSW_HOME calculation (was: double dirname for bin/csw, now: single dirname)
# Before: CSW_HOME="$(cd -P "$(dirname "$(dirname "$SOURCE")")" && pwd)"
# After: CSW_HOME="$(cd -P "$(dirname "$SOURCE")" && pwd)"
```

**Changes needed in csw**:
- Line 14: Change `dirname "$(dirname "$SOURCE")"` → `dirname "$SOURCE"`
- Lines 41-65: Add new cases for install, init, uninstall before existing spec|plan|build|check|ship|cleanup case

**Validation**:
- Run `./csw --version` from project root
- Verify CSW_HOME resolves correctly: `./csw` should find scripts/

---

### Task 2: Add csw install subcommand
**File**: csw
**Action**: MODIFY (add install case)
**Pattern**: Inline implementation (Option A from spec)

**Implementation**:
Add case before existing commands (after usage function, around line 41):

```bash
case "${1:-}" in
    install)
        # csw install - Replace install.sh functionality
        info "🚀 Installing Claude Spec Workflow"
        echo ""

        # Detect installation directory
        INSTALL_DIR="$CSW_HOME"
        info "Installation directory: $INSTALL_DIR"
        echo ""

        # Install Claude commands
        CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
        REPO_COMMANDS_DIR="$INSTALL_DIR/commands"

        if [ ! -d "$REPO_COMMANDS_DIR" ]; then
            error "❌ Error: commands directory not found at $REPO_COMMANDS_DIR"
            echo "   This should not happen. Please report this issue."
            exit 1
        fi

        if [ ! -d "$CLAUDE_COMMANDS_DIR" ]; then
            info "📁 Creating Claude commands directory..."
            mkdir -p "$CLAUDE_COMMANDS_DIR"
        fi

        info "📦 Installing commands..."
        updated=0
        installed=0
        for cmd in "$REPO_COMMANDS_DIR"/*.md; do
            if [ -f "$cmd" ]; then
                filename=$(basename "$cmd")
                target="$CLAUDE_COMMANDS_DIR/$filename"
                if [ -f "$target" ]; then
                    echo "   ↻ Updated $filename"
                    ((updated++))
                else
                    echo "   ✓ Installed $filename"
                    ((installed++))
                fi
                cp "$cmd" "$target"
            fi
        done
        echo ""

        # Install csw CLI
        info "🔧 Installing csw CLI..."
        CSW_BIN_DIR="$HOME/.local/bin"
        if [ ! -d "$CSW_BIN_DIR" ]; then
            info "   📁 Creating $CSW_BIN_DIR..."
            mkdir -p "$CSW_BIN_DIR"
        fi

        # Check if already installed
        if [ -L "$CSW_BIN_DIR/csw" ]; then
            existing_target=$(readlink "$CSW_BIN_DIR/csw")
            if [ "$existing_target" = "$INSTALL_DIR/csw" ]; then
                info "   ✅ Already installed (up to date)"
            else
                info "   ↻ Updating symlink"
                ln -sf "$INSTALL_DIR/csw" "$CSW_BIN_DIR/csw"
            fi
        else
            info "   🔗 Creating symlink: csw -> $INSTALL_DIR/csw"
            ln -sf "$INSTALL_DIR/csw" "$CSW_BIN_DIR/csw"
        fi
        echo ""

        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$CSW_BIN_DIR:"* ]]; then
            warning "⚠️  Note: $CSW_BIN_DIR is not in your PATH"
            echo "   Add this line to your ~/.bashrc or ~/.zshrc:"
            echo ""
            echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo ""
            echo "   Then run: source ~/.bashrc (or ~/.zshrc)"
            echo ""
            echo "   Alternatively, use ./spec/csw in your projects"
            echo ""
        fi

        success "✅ Installation complete!"
        echo ""
        echo "Installed: $installed command(s)"
        echo "Updated: $updated command(s)"
        echo ""
        info "📋 Next: Initialize a project"
        echo "   csw init /path/to/project [preset]"
        echo ""
        exit 0
        ;;
    # ... existing spec|plan|build|check|ship|cleanup cases
```

**Validation**:
- Run `./csw install` from project root
- Verify commands copied to ~/.claude/commands/
- Verify symlink created at ~/.local/bin/csw
- Run shellcheck on modified csw file

---

### Task 3: Add csw init subcommand (Part 1: Core logic)
**File**: csw
**Action**: MODIFY (add init case)
**Pattern**: Inline implementation with helper functions

**Implementation**:
Add init case after install case. Due to complexity, split into substasks:

**3a: Argument parsing and directory validation**

```bash
    init)
        # csw init <project-dir> [preset] [--no-bootstrap-spec]
        shift  # Remove 'init' from arguments

        PROJECT_DIR="${1:-.}"
        PRESET="${2:-typescript-react-vite}"
        CREATE_BOOTSTRAP=true  # Default: always create bootstrap

        # Parse flags
        for arg in "$@"; do
            case "$arg" in
                --no-bootstrap-spec)
                    CREATE_BOOTSTRAP=false
                    ;;
            esac
        done

        # Handle 'default' literal
        if [[ $PRESET == "default" ]]; then
            PRESET="typescript-react-vite"
        fi

        info "🏗️  Initializing Claude Spec Workflow"
        echo "   Project: $PROJECT_DIR"
        echo "   Preset: $PRESET"
        echo ""

        # Directory validation with prompt
        if [ ! -d "$PROJECT_DIR" ]; then
            warning "⚠️  Directory does not exist: $PROJECT_DIR"
            read -p "Create it? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                error "❌ Cancelled"
                exit 1
            fi
            mkdir -p "$PROJECT_DIR"
            success "✅ Created directory: $PROJECT_DIR"
            echo ""
        fi

        # Check if spec/ already exists
        if [ -d "$PROJECT_DIR/spec" ]; then
            warning "⚠️  spec/ already exists in $PROJECT_DIR"
            read -p "Reinitialize? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "ℹ️  Cancelled"
                exit 0
            fi
            echo ""
        fi
```

---

### Task 4: Add csw init subcommand (Part 2: Preset matching)
**File**: csw
**Action**: MODIFY (continue init case)
**Pattern**: Bash fuzzy matching

**Implementation**:
Add preset matching logic (after directory validation in init case):

```bash
        # Preset fuzzy matching
        PRESETS_DIR="$CSW_HOME/presets"

        # Check if PRESET is a file path (contains /)
        if [[ $PRESET == */* ]]; then
            PRESET_FILE="$PRESET"
            [[ ! $PRESET_FILE =~ \.md$ ]] && PRESET_FILE="${PRESET_FILE}.md"
        else
            # Strip .md if user provided it
            [[ $PRESET =~ \.md$ ]] && PRESET="${PRESET%.md}"

            # Try exact match first
            if [ -f "$PRESETS_DIR/$PRESET.md" ]; then
                PRESET_FILE="$PRESETS_DIR/$PRESET.md"
            else
                # Try case-insensitive match
                PRESET_LOWER="${PRESET,,}"
                EXACT_MATCH=$(find "$PRESETS_DIR" -maxdepth 1 -iname "$PRESET_LOWER.md" 2>/dev/null | head -1)

                if [ -n "$EXACT_MATCH" ]; then
                    PRESET_FILE="$EXACT_MATCH"
                else
                    # Try substring match
                    MATCHES=$(find "$PRESETS_DIR" -maxdepth 1 -name "*$PRESET*.md" 2>/dev/null)
                    MATCH_COUNT=$(echo "$MATCHES" | grep -c . || echo 0)

                    if [ "$MATCH_COUNT" -eq 0 ]; then
                        error "❌ Error: Preset '$PRESET' not found"
                        echo ""
                        echo "Available presets:"
                        for p in "$PRESETS_DIR"/*.md; do
                            basename "$p" .md | sed 's/^/  - /'
                        done
                        exit 1
                    elif [ "$MATCH_COUNT" -eq 1 ]; then
                        PRESET_FILE="$MATCHES"
                        info "ℹ️  Matched preset: $(basename "$PRESET_FILE" .md)"
                        echo ""
                    else
                        error "❌ Error: Multiple presets match '$PRESET'"
                        echo ""
                        echo "Matching presets:"
                        echo "$MATCHES" | while read -r match; do
                            basename "$match" .md | sed 's/^/  - /'
                        done
                        echo ""
                        echo "Please be more specific"
                        exit 1
                    fi
                fi
            fi
        fi

        # Validate preset file exists
        if [ ! -f "$PRESET_FILE" ]; then
            error "❌ Error: Preset file not found: $PRESET_FILE"
            exit 1
        fi
```

---

### Task 5: Add csw init subcommand (Part 3: Create spec structure)
**File**: csw
**Action**: MODIFY (continue init case)
**Pattern**: Follow init-project.sh structure creation logic

**Implementation**:
Add spec directory creation (after preset matching):

```bash
        # Create spec directory structure
        info "📁 Creating spec directories..."
        mkdir -p "$PROJECT_DIR/spec/active"

        # Initialize SHIPPED.md if it doesn't exist
        if [ ! -f "$PROJECT_DIR/spec/SHIPPED.md" ]; then
            touch "$PROJECT_DIR/spec/SHIPPED.md"
        fi

        # Check for existing files and prompt for overwrite
        FILES_TO_OVERWRITE=()
        [ -f "$PROJECT_DIR/spec/stack.md" ] && FILES_TO_OVERWRITE+=("spec/stack.md")
        [ -f "$PROJECT_DIR/spec/template.md" ] && FILES_TO_OVERWRITE+=("spec/template.md")
        [ -f "$PROJECT_DIR/spec/README.md" ] && FILES_TO_OVERWRITE+=("spec/README.md")

        if [ ${#FILES_TO_OVERWRITE[@]} -gt 0 ]; then
            warning "⚠️  The following files will be overwritten:"
            for file in "${FILES_TO_OVERWRITE[@]}"; do
                echo "   - $file"
            done
            echo ""
            echo "You can revert with: git checkout -- spec/"
            echo ""
            read -p "Continue? (y/n) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "ℹ️  Cancelled"
                exit 0
            fi
            echo ""
        fi

        # Copy files
        info "📄 Copying configuration files..."
        cp "$PRESET_FILE" "$PROJECT_DIR/spec/stack.md"
        echo "   ✓ stack.md (preset: $(basename "$PRESET_FILE" .md))"
        cp "$CSW_HOME/templates/spec-template.md" "$PROJECT_DIR/spec/template.md"
        echo "   ✓ template.md"
        cp "$CSW_HOME/templates/README.md" "$PROJECT_DIR/spec/README.md"
        echo "   ✓ README.md"
        echo ""

        # Add to .gitignore
        if [ -f "$PROJECT_DIR/.gitignore" ]; then
            if ! grep -q "spec/active/\*/log.md" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
                info "📝 Adding spec logs to .gitignore..."
                echo -e "\n# Spec workflow logs\nspec/active/*/log.md" >> "$PROJECT_DIR/.gitignore"
            fi
        fi
```

---

### Task 6: Add csw init subcommand (Part 4: Create symlink and bootstrap spec)
**File**: csw
**Action**: MODIFY (continue init case)
**Pattern**: Direct path symlink, bootstrap spec with variable substitution

**Implementation**:
Add symlink creation and bootstrap spec (after file copying):

```bash
        # Create spec/csw symlink (always direct path - fallback use case)
        info "🔗 Creating spec/csw symlink..."
        CSW_BIN="$CSW_HOME/csw"
        ln -sf "$CSW_BIN" "$PROJECT_DIR/spec/csw"
        echo "   ✓ spec/csw -> $CSW_BIN"
        echo ""

        # Generate bootstrap validation spec (default for everyone)
        if [ "$CREATE_BOOTSTRAP" = true ]; then
            # Check if spec directory already has content (reinit scenario)
            EXISTING_SPECS=$(find "$PROJECT_DIR/spec" -mindepth 1 -maxdepth 1 -type d ! -name active 2>/dev/null | wc -l)

            if [ "$EXISTING_SPECS" -gt 0 ]; then
                warning "⚠️  Spec directory has existing content"
                read -p "Create bootstrap spec anyway? (y/n) " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    CREATE_BOOTSTRAP=false
                fi
            fi
        fi

        if [ "$CREATE_BOOTSTRAP" = true ]; then
            info "📝 Creating bootstrap validation spec..."
            BOOTSTRAP_DIR="$PROJECT_DIR/spec/bootstrap"
            mkdir -p "$BOOTSTRAP_DIR"

            # Get current date and stack name
            CURRENT_DATE=$(date +%Y-%m-%d)
            PRESET_NAME=$(basename "$PRESET_FILE" .md)

            # Get human-readable stack name
            case "$PRESET_NAME" in
                "typescript-react-vite") STACK_NAME="TypeScript + React + Vite" ;;
                "nextjs-app-router") STACK_NAME="Next.js App Router + TypeScript" ;;
                "python-fastapi") STACK_NAME="Python + FastAPI" ;;
                "go-standard") STACK_NAME="Go" ;;
                "monorepo-go-react") STACK_NAME="Go + React Monorepo" ;;
                "shell-scripts") STACK_NAME="Shell Scripts (Bash)" ;;
                *) STACK_NAME="$PRESET_NAME" ;;
            esac

            # Copy and populate template
            if [ -f "$CSW_HOME/templates/bootstrap-spec.md" ]; then
                cp "$CSW_HOME/templates/bootstrap-spec.md" "$BOOTSTRAP_DIR/spec.md"

                # Replace placeholders (use | as delimiter to avoid issues with /)
                sed -i "s|{{STACK_NAME}}|$STACK_NAME|g" "$BOOTSTRAP_DIR/spec.md"
                sed -i "s|{{PRESET_NAME}}|$PRESET_NAME|g" "$BOOTSTRAP_DIR/spec.md"
                sed -i "s|{{INSTALL_DATE}}|$CURRENT_DATE|g" "$BOOTSTRAP_DIR/spec.md"

                echo "   ✓ bootstrap/spec.md"
            else
                warning "   ⚠️  Bootstrap template not found, skipping"
            fi
            echo ""
        fi

        # Success message
        success "✅ Claude Spec Workflow Setup Complete!"
        echo ""
        echo "📂 Directory structure:"
        echo "   spec/"
        echo "   ├── README.md       # Workflow documentation"
        echo "   ├── template.md     # Spec template"
        echo "   ├── stack.md        # Validation commands"
        echo "   ├── SHIPPED.md      # Completed features log"

        if [ "$CREATE_BOOTSTRAP" = true ]; then
            echo "   └── bootstrap/      # Bootstrap validation spec ⭐"
            echo ""
            echo "🚀 Next: Validate installation"
            echo ""
            echo "   In Claude Code:"
            echo "   1. /plan bootstrap"
            echo "   2. /build"
            echo "   3. /check"
            echo "   4. /ship"
        fi

        echo ""
        info "💡 Three ways to run commands:"
        echo "   - In Claude Code:  /plan my-feature"
        echo "   - In terminal:     csw plan my-feature"
        echo "   - In project:      ./spec/csw plan my-feature"
        echo ""
        exit 0
        ;;
```

**Validation**:
- Test `csw init /tmp/test-project` (create directory, bootstrap created by default)
- Test `csw init . python` (substring match, bootstrap created with python preset)
- Test `csw init . xyz` (no match error)
- Test `csw init . --no-bootstrap-spec` (skip bootstrap explicitly)
- Test `csw init . python --no-bootstrap-spec` (preset without bootstrap)
- Test `csw init .` when spec/ exists (reinit prompt)
- Run shellcheck on csw

---

### Task 7: Add csw uninstall subcommand
**File**: csw
**Action**: MODIFY (add uninstall case)
**Pattern**: Migrate uninstall.sh logic + add csw symlink removal

**Implementation**:
Add uninstall case after init case:

```bash
    uninstall)
        # csw uninstall - Remove installed components
        info "🗑️  Uninstalling Claude Spec Workflow"
        echo ""

        CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
        COMMANDS=("spec.md" "plan.md" "build.md" "check.md" "ship.md" "cleanup.md")

        # Remove Claude commands
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
            info "ℹ️  No commands found to remove"
        else
            success "✅ Removed $removed command(s)"
        fi
        echo ""

        # Remove csw symlink
        CSW_BIN="$HOME/.local/bin/csw"
        if [ -L "$CSW_BIN" ] || [ -f "$CSW_BIN" ]; then
            rm "$CSW_BIN"
            success "✅ Removed csw from ~/.local/bin"
        else
            info "ℹ️  No csw symlink found in ~/.local/bin"
        fi
        echo ""

        info "ℹ️  Note: Project spec/ directories remain untouched"
        echo "   Installation directory: $CSW_HOME"
        echo "   Remove manually if desired: rm -rf $CSW_HOME"
        echo ""

        success "✅ Uninstall complete!"
        exit 0
        ;;
```

**Validation**:
- Run `csw uninstall`
- Verify commands removed from ~/.claude/commands/
- Verify symlink removed from ~/.local/bin/csw
- Verify spec/ directories in projects are untouched
- Run shellcheck on csw

---

### Task 8: Update csw help text
**File**: csw
**Action**: MODIFY
**Pattern**: Add install/init/uninstall to usage function

**Implementation**:
Update usage() function (lines 17-39) to include new commands:

```bash
usage() {
    cat << EOF
Claude Spec Workflow (csw) - Specification-driven development CLI

Usage: csw <command> [arguments]

Bootstrap Commands:
  install            Install CSW globally (creates ~/.local/bin/csw)
  init <dir> [preset] [--no-bootstrap-spec]
                     Initialize project with spec workflow
  uninstall          Remove CSW installation

Workflow Commands:
  spec [name]        Create specification from conversation
  plan <spec-file>   Generate implementation plan
  build              Execute build with progress tracking
  check              Run validation suite (test/lint/build)
  ship <feature>     Create PR and prepare for merge
  cleanup            Clean up shipped features (delete specs)

Examples:
  csw install
  csw init . typescript-react-vite
  csw init /path/to/project python --no-bootstrap-spec
  csw spec auth-system
  csw plan spec/active/auth-system/spec.md
  csw check
  csw ship auth-system
  csw uninstall

For more information: https://github.com/trakrf/claude-spec-workflow
EOF
}
```

**Validation**:
- Run `csw --help`
- Verify new commands listed
- Verify examples show new syntax

---

### Task 9: Remove bin/ directory
**File**: bin/ (directory)
**Action**: DELETE

**Implementation**:
```bash
# After csw is moved to root and tested
rmdir bin/
```

**Validation**:
- Verify bin/ no longer exists
- Verify `./csw --version` still works from root

---

### Task 10: Delete obsolete bootstrap scripts
**Files**: install.sh, init-project.sh, uninstall.sh
**Action**: DELETE

**Implementation**:
```bash
rm install.sh init-project.sh uninstall.sh
```

**Validation**:
- Verify files deleted
- Verify no references remain (grep -r "install.sh" .)

---

### Task 11: Update README.md
**File**: README.md
**Action**: MODIFY

**Changes needed**:
1. Lines 75-93 (Installation section):
```markdown
## Installation

\```bash
# Clone the repository
git clone https://github.com/trakrf/claude-spec-workflow
cd claude-spec-workflow

# Install commands globally
./csw install

# Initialize a project (creates bootstrap spec for guided setup)
csw init /path/to/your/project

# Or initialize with a specific preset (still creates bootstrap for customization)
csw init /path/to/your/project python-fastapi

# Expert mode: skip bootstrap if you're 100% confident
csw init /path/to/your/project python-fastapi --no-bootstrap-spec
\```
```

2. Line 450 (Uninstalling section):
```markdown
## Uninstalling

\```bash
csw uninstall
\```

This removes the Claude commands and ~/.local/bin/csw symlink, but leaves your project spec directories intact.
```

3. Lines 602-621 (Roadmap section) - Add to Future section:
```markdown
**Future**:
- Convenience install script (curl-based one-liner for installation without checkout)
- Package manager distribution (Homebrew, npm)
```

**Validation**:
- Grep for "install.sh" - should find zero in README.md
- Grep for "init-project.sh" - should find zero in README.md
- Run shellcheck on any bash examples

---

### Task 12: Update CONTRIBUTING.md
**File**: CONTRIBUTING.md
**Action**: MODIFY

**Changes needed**:
Lines 34-50 (Testing section):
```markdown
2. **Test with a sample project**
   \```bash
   mkdir /tmp/test-project
   cd /tmp/test-project
   git init

   # Initialize with spec workflow (includes stack preset)
   csw init . typescript-react-vite

   # Create a test spec
   mkdir -p spec/active/test-feature
   cp spec/template.md spec/active/test-feature/spec.md
   \```

3. **Test commands manually**
   - Edit the spec with a simple feature
   - Run `/plan spec/active/test-feature/spec.md`
   - Verify the plan is generated correctly
   - Test other commands as applicable

4. **After modifying commands**

   If you modify files in `commands/` (slash command prompts) or the `csw` CLI:

   \```bash
   # Re-run install to update global commands
   ./csw install

   # Restart Claude Code to pick up changes
   # (Command palette > "Reload Window" or restart application)
   \```
```

**Validation**:
- Grep for "install.sh" - should find zero
- Grep for "init-project.sh" - should find zero

---

### Task 13: Update TESTING.md
**File**: TESTING.md
**Action**: MODIFY

**Changes needed**:
- Search and replace all `./install.sh` → `./csw install`
- Search and replace all `init-project.sh` → `csw init`
- Update any test procedures that reference bin/csw → csw

**Validation**:
- Grep for "install.sh" - should find zero
- Grep for "bin/csw" - should find zero (except in comments/git logs)
- Run shellcheck on any bash examples

---

### Task 14: Update commands/*.md files
**Files**: commands/spec.md, commands/plan.md, commands/build.md, commands/check.md, commands/ship.md
**Action**: MODIFY (if they contain references)

**Implementation**:
Search each file for references to:
- `install.sh` → replace with `./csw install`
- `init-project.sh` → replace with `csw init`
- `bin/csw` → replace with `csw` (if user-facing) or keep (if describing internal structure)

**Validation**:
- Grep commands/ for install.sh
- Grep commands/ for init-project.sh

---

### Task 15: Add CHANGELOG.md entry
**File**: CHANGELOG.md
**Action**: MODIFY (prepend new section)

**Implementation**:
Add at top of file:

```markdown
## [Unreleased]

### Breaking Changes
- **Bootstrap consolidated into csw**: Installation and initialization now happen through `csw` subcommands instead of shell scripts
  - `./install.sh` → `./csw install`
  - `./init-project.sh <dir> [preset]` → `csw init <dir> [preset]`
  - `./uninstall.sh` → `csw uninstall`
  - `bin/csw` moved to project root as `csw` for cleaner bootstrap

### Added
- `csw install` subcommand with idempotent installation
- `csw init` subcommand with:
  - Bash fuzzy matching for preset selection
  - `--no-bootstrap-spec` flag to skip bootstrap spec generation
  - Interactive prompts for directory creation and overwrite confirmation
- `csw uninstall` subcommand for clean removal

### Removed
- `install.sh` (replaced by `csw install`)
- `init-project.sh` (replaced by `csw init`)
- `uninstall.sh` (replaced by `csw uninstall`)
- `bin/` directory (csw moved to project root)

### Fixed
- Bootstrap self-reference: csw now correctly resolves its own location after move to root
- Symlink resolution: spec/csw now uses direct path for reliable fallback

### Migration
For existing installations:
1. Remove old symlink: `rm ~/.local/bin/csw`
2. Run new install: `cd claude-spec-workflow && ./csw install`
3. Projects with `spec/csw` will continue working (symlink auto-updates on next init)

---
```

**Validation**:
- Entry follows existing CHANGELOG format
- Breaking changes clearly documented
- Migration instructions provided

---

### Task 16: Final integration test
**Action**: COMPREHENSIVE TEST
**Pattern**: Full workflow validation

**Test Procedure**:
```bash
# 1. Clean test (simulate new user)
cd /tmp
git clone /path/to/claude-spec-workflow test-csw
cd test-csw

# 2. Test install
./csw install
# Verify: commands copied, symlink created, PATH message shown

# 3. Test csw from PATH
csw --version
csw --help
# Verify: version shown, help includes install/init/uninstall

# 4. Test init (new project)
cd /tmp
mkdir test-project
cd test-project
git init
csw init .
# Verify: spec/ created, bootstrap/ created, files correct

# 5. Test init with preset fuzzy match
cd /tmp
mkdir test-python
cd test-python
csw init . python
# Verify: matched python-fastapi, stack.md correct

# 6. Test init with --no-bootstrap-spec
cd /tmp
mkdir test-no-bootstrap
cd test-no-bootstrap
csw init . --no-bootstrap-spec
# Verify: spec/ created, no bootstrap/ directory

# 7. Test reinit prompt
cd /tmp/test-project
csw init .
# Verify: prompts for reinit, respects y/n answer

# 8. Test uninstall
csw uninstall
# Verify: commands removed, symlink removed, spec/ untouched

# 9. Shellcheck validation
cd /tmp/test-csw
shellcheck csw
# Verify: no errors

# 10. Documentation check
grep -r "install\.sh" . --exclude-dir=.git
grep -r "init-project\.sh" . --exclude-dir=.git
grep -r "bin/csw" . --exclude-dir=.git | grep -v CHANGELOG | grep -v ".git"
# Verify: no references found (except in CHANGELOG/history)
```

**Success Criteria**:
- All tests pass
- No shellcheck errors
- No old references in docs
- Bootstrap workflow works end-to-end

---

## Risk Assessment

**Risk**: Symlink resolution breaks in edge cases
**Mitigation**: Test on Linux, macOS, and Windows (Git Bash). Use absolute paths for symlinks.

**Risk**: Fuzzy preset matching produces unexpected results
**Mitigation**: Exact match first, case-insensitive second, substring last. Show matches before proceeding.

**Risk**: Users have existing ~/.local/bin/csw from old install
**Mitigation**: Install is idempotent, detects existing symlink, updates or confirms.

**Risk**: Breaking change disrupts existing workflows
**Mitigation**: Clear migration instructions in CHANGELOG, simple migration path (one command).

**Risk**: Missing references to old scripts in docs
**Mitigation**: Comprehensive grep for install.sh, init-project.sh, bin/csw before finalizing.

## Integration Points

- **CLI wrapper**: csw gains three new subcommands (install, init, uninstall)
- **Bootstrap flow**: New user path is `git clone` → `./csw install` → `csw init .`
- **Symlink structure**: spec/csw → direct path (fallback when ~/.local/bin/csw unavailable)
- **Documentation**: All docs updated to reference new commands
- **Claude commands**: Copied by csw install, no changes to command content

## VALIDATION GATES (MANDATORY)

**CRITICAL**: Shell scripts must pass validation before proceeding.

After EVERY code change:
- **Gate 1: Shellcheck** - Run `shellcheck csw` - must pass with zero errors
- **Gate 2: Syntax Check** - Run `bash -n csw` - must parse without errors
- **Gate 3: Manual Test** - Run relevant test from Task 16 - must complete successfully

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task: Run shellcheck on modified files

Final validation (Task 16): Comprehensive integration test covering all subcommands and documentation

## Plan Quality Assessment

**Complexity Score**: 5/10 (LOW)
- File Impact: Modify ~10 files, delete 3 files, move 1 file = 14 files (2pts)
- Subsystems: 1 (Bootstrap/CLI only) (0pts)
- Task Estimate: 16 subtasks (3pts)
- Dependencies: 0 new packages (0pts)
- Pattern Novelty: Existing patterns (0pts)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec with comprehensive clarifications
✅ Similar patterns found in codebase:
   - scripts/cleanup.sh (script structure, lib imports, colored output)
   - scripts/plan.sh (git operations, prompting patterns)
   - install.sh/init-project.sh (exact logic to preserve)
✅ All clarifying questions answered with specific decisions
✅ Existing validation pattern: shellcheck available
✅ Straightforward bash scripting (no complex dependencies)
✅ Well-defined success criteria and test procedure
⚠️ Symlink behavior varies by platform (test on Windows Git Bash, macOS, Linux)
⚠️ Documentation references spread across 7+ files (grep coverage critical)

**Assessment**: High-confidence implementation. Primary risk is missing documentation references, mitigated by comprehensive grep validation. Platform-specific symlink behavior tested during Task 16.

**Estimated one-pass success probability**: 85%

**Reasoning**: Straightforward refactoring with clear patterns to follow. Main challenges are:
1. Comprehensive documentation updates (many files)
2. Symlink cross-platform behavior
3. Fuzzy matching edge cases

All challenges have clear mitigation strategies in place.
