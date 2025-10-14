# Implementation Plan: Bootstrap Spec Auto-Generation
Generated: 2025-10-14
Specification: spec.md

## Understanding
This feature solves the chicken-and-egg problem when setting up CSW in a new project. Currently, after running `init-project.sh`, users are left wondering "Did this work? What now?" This feature automatically creates a bootstrap validation spec that users can immediately plan, build, and ship - validating the installation, committing CSW infrastructure cleanly, and providing hands-on workflow experience before building real features.

**Key Design Decisions** (from clarification):
- **Scope**: Bootstrap generation only, no workflow resequencing (forked to backlog spec)
- **Path**: `spec/bootstrap/` (simplified path pattern)
- **Validation**: Light touch - file existence checks, not full validation command execution
- **Lifecycle**: Archive like any other spec (no special treatment)
- **Reinit behavior**: Prompt user if spec/ already exists (don't assume why)
- **Stack detection**: Inspect project files (package.json, requirements.txt, go.mod, etc.)
- **Git**: Leave unstaged (user decides when to commit)

## Relevant Files

**Reference Patterns** (existing code to follow):
- `/home/mike/claude-spec-workflow/init-project.sh` (lines 105-116) - Template copying and sed replacement pattern
- `/home/mike/claude-spec-workflow/scripts/lib/validation.sh` (lines 7-19) - Stack detection pattern with `detect_package_manager()`
- `/home/mike/claude-spec-workflow/templates/spec-template.md` - Template structure to mirror
- `/home/mike/claude-spec-workflow/presets/typescript-react-vite.md` - Preset format (header with stack name)

**Files to Create**:
- `templates/bootstrap-spec.md` - Bootstrap validation spec template with placeholders

**Files to Modify**:
- `init-project.sh` (add after line 116, before line 137) - Add stack detection function and bootstrap spec generation
- `templates/README.md` (Quick Start section, after line 5) - Add bootstrap workflow guidance

## Architecture Impact
- **Subsystems affected**: Installation/Setup scripts only
- **New dependencies**: None
- **Breaking changes**: None (additive feature)

## Task Breakdown

### Task 1: Create Bootstrap Spec Template
**File**: `templates/bootstrap-spec.md`
**Action**: CREATE
**Pattern**: Mirror structure of `templates/spec-template.md` but specialized for CSW setup validation

**Implementation**:
```markdown
# Feature: Claude Spec Workflow Setup

## Metadata
**Type**: infrastructure

## Outcome
Validate CSW installation and commit workflow infrastructure to repository via CSW's own workflow.

## User Story
As a developer
I want CSW infrastructure validated and committed
So that the team can use specification-driven development

## Context
**Installed**: Claude Spec Workflow from https://github.com/trakrf/claude-spec-workflow
**Stack**: {{STACK_NAME}}
**Preset**: {{PRESET_NAME}}
**Date**: {{INSTALL_DATE}}

## Technical Requirements
- `spec/` directory structure is complete and correct
- `spec/stack.md` validation commands work for our stack
- Slash commands (/plan, /build, /check, /ship) are accessible in Claude Code
- Templates are ready for use

## Validation Criteria
- [ ] spec/README.md exists and describes the workflow
- [ ] spec/template.md exists and is ready for copying
- [ ] spec/stack.md contains validation commands for {{STACK_NAME}}
- [ ] spec/ directory structure matches documentation
- [ ] Slash commands installed in Claude Code (verify with: /help)

## Success Metrics
- [ ] Directory structure matches spec/README.md documentation
- [ ] Template can be copied to create new specs
- [ ] This bootstrap spec itself gets shipped to SHIPPED.md
- [ ] First hands-on experience with CSW workflow completed successfully

## References
- CSW Source: https://github.com/trakrf/claude-spec-workflow
- Stack Preset: {{PRESET_NAME}}
- Installation Date: {{INSTALL_DATE}}
```

**Validation**:
```bash
# Verify file created and placeholders present
grep -q "{{STACK_NAME}}" templates/bootstrap-spec.md
grep -q "{{PRESET_NAME}}" templates/bootstrap-spec.md
grep -q "{{INSTALL_DATE}}" templates/bootstrap-spec.md
```

### Task 2: Add Stack Detection Function to init-project.sh
**File**: `init-project.sh`
**Action**: MODIFY
**Pattern**: Reference `scripts/lib/validation.sh` lines 7-19 for detection pattern

**Implementation**:
Add function after the PRESET validation (after line 55), before the main execution:

```bash
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
```

**Validation**:
```bash
bash -n init-project.sh
shellcheck init-project.sh
```

### Task 3: Add Bootstrap Spec Generation Logic
**File**: `init-project.sh`
**Action**: MODIFY
**Pattern**: Reference lines 105-116 for template copying and sed replacement

**Implementation**:
Add before the final success message (before line 137):

```bash
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
```

**Validation**:
```bash
bash -n init-project.sh
shellcheck init-project.sh
```

### Task 4: Update Success Message
**File**: `init-project.sh`
**Action**: MODIFY
**Pattern**: Enhance existing success message (lines 137-158)

**Implementation**:
Replace the final echo block (lines 137-158) with:

```bash
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
```

**Validation**:
```bash
bash -n init-project.sh
```

### Task 5: Update spec/README.md Quick Start Section
**File**: `templates/README.md`
**Action**: MODIFY
**Pattern**: Add guidance after line 5 (Quick Start section)

**Implementation**:
Replace Quick Start section (lines 6-24) with:

```markdown
## Quick Start

### First Time: Ship the Bootstrap Spec

After installation, you'll find a bootstrap spec at `spec/bootstrap/`. This validates your setup:

```
/plan bootstrap
/build
/check
/ship
```

This proves CSW works and commits the infrastructure cleanly. You'll experience the full workflow and create your first SHIPPED.md entry.

### Creating New Features

1. **Create a specification**
   ```bash
   mkdir -p spec/my-feature
   cp spec/template.md spec/my-feature/spec.md
   # Edit spec.md with your requirements
   ```

2. **Generate implementation plan**
   ```
   /plan my-feature
   # or just: /plan (auto-detects if only one spec)
   ```

3. **Build the feature**
   ```
   /build
   # Auto-detects the spec with plan.md
   ```

4. **Validate readiness**
   ```
   /check
   ```

5. **Ship it**
   ```
   /ship
   # Auto-detects the spec ready to ship
   ```
```

**Validation**:
```bash
# Verify markdown syntax
grep -q "Ship the Bootstrap Spec" templates/README.md
```

### Task 6: Test Bootstrap Spec Generation
**File**: N/A (testing task)
**Action**: TEST
**Pattern**: Dry-run init-project.sh to verify bootstrap spec generation

**Implementation**:
```bash
# Test in a temporary directory
cd /tmp
mkdir -p csw-test-bootstrap
cd csw-test-bootstrap

# Create dummy project files to trigger shell-scripts detection
touch script1.sh script2.sh script3.sh

# Run init-project.sh
/home/mike/claude-spec-workflow/init-project.sh . shell-scripts

# Verify bootstrap spec created
[[ -f "spec/bootstrap/spec.md" ]]

# Verify placeholders replaced
grep -q "Shell Scripts (Bash)" spec/bootstrap/spec.md
grep -q "shell-scripts" spec/bootstrap/spec.md
grep -q "$(date +%Y-%m-%d)" spec/bootstrap/spec.md

# Verify no {{PLACEHOLDERS}} remain
! grep -q "{{" spec/bootstrap/spec.md

# Cleanup
cd /tmp
rm -rf csw-test-bootstrap

echo "✅ Bootstrap spec generation test passed"
```

**Validation**:
```bash
# Test passes if all checks succeed
echo "All validation checks must pass"
```

## Risk Assessment

**Risk**: Stack detection misidentifies project type
**Mitigation**: User provided explicit preset as argument 2, detection only used if no preset given. Fallback to prompt if detection fails.

**Risk**: Template placeholders not replaced correctly
**Mitigation**: Use `|` as sed delimiter instead of `/` to handle paths with slashes. Test with actual init run (Task 6).

**Risk**: Reinit scenario overwrites existing bootstrap spec
**Mitigation**: Prompt user if spec/ already has content (Task 3).

**Risk**: Paths in spec reference old `spec/active/` pattern
**Mitigation**: Use simplified `spec/bootstrap/` throughout (verified in template Task 1).

## Integration Points
- **init-project.sh**: Add stack detection and bootstrap generation after template copying
- **templates/**: Add bootstrap-spec.md alongside existing templates
- **spec/README.md**: Update Quick Start to feature bootstrap workflow
- **User workflow**: Bootstrap spec becomes natural first action after init

## VALIDATION GATES (MANDATORY)

After EVERY code change, run:

```bash
# Gate 1: Syntax Check
bash -n init-project.sh

# Gate 2: Shellcheck
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Gate 3: Template Validation
grep -q "{{STACK_NAME}}" templates/bootstrap-spec.md
grep -q "{{PRESET_NAME}}" templates/bootstrap-spec.md
grep -q "{{INSTALL_DATE}}" templates/bootstrap-spec.md
```

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task:
```bash
bash -n init-project.sh
shellcheck init-project.sh
# For template tasks:
cat templates/bootstrap-spec.md  # Visual inspection
```

Final validation:
```bash
# Full shellcheck suite
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Syntax validation
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done

# Integration test (Task 6)
# Test actual init run in temporary directory
```

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Similar patterns found in codebase (init-project.sh:105-116, validation.sh:7-19)
✅ All clarifying questions answered with concrete decisions
✅ Existing template patterns to follow
✅ Simple sed replacement pattern already used in codebase
✅ Stack detection logic mirrors existing validation.sh pattern
✅ No new dependencies or external integrations
✅ Additive feature (no breaking changes)
✅ Clear validation path with integration test

**Assessment**: High confidence implementation. All patterns exist in codebase, requirements are clear and scoped, and we have concrete examples to follow. Stack detection logic mirrors existing code. Template replacement pattern is already proven in init-project.sh.

**Estimated one-pass success probability**: 85%

**Reasoning**: Straightforward feature with clear patterns to follow. Main risk is edge cases in stack detection (mitigated by prompt fallback) and placeholder replacement (mitigated by integration test). The user's clarifying answers removed all ambiguity about scope and behavior.
