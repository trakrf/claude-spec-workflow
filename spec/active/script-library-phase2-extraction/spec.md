# Feature: Script Library Phase 2 - Extract Command Logic

## Origin
Part 2 of 3-phase refactoring. Phase 1 built the primitive functions. This phase extracts bash logic from command markdown files into scripts that use those primitives. Commands still run old embedded bash - Phase 3 will wire them to use these scripts.

## Outcome
Six executable scripts (`scripts/{spec,plan,build,check,ship,archive}.sh`) created by extracting ~400 lines of bash from `commands/*.md`. Scripts use Phase 1 library functions. No integration yet - commands unchanged.

## User Story
As a developer refactoring claude-spec-workflow
I want to extract command logic into standalone scripts
So that Phase 3 can wire commands to call these scripts

## Context

**Phase 1 Complete**: Library functions and csw wrapper exist, tested, merged
**This Phase**: Extract command bash → scripts using library functions
**Next Phase**: Wire commands and installers to use these scripts

**Why this sequence**: Build primitives (✅) → compose primitives (this phase) → integrate (Phase 3)

## Technical Requirements

### Scripts to Create

Extract bash from these command files into standalone scripts:

**1. scripts/spec.sh** (from commands/spec.md)
- Directory setup for new specs
- Template processing
- Uses: `common.sh` functions

**2. scripts/plan.sh** (from commands/plan.md)
- Branch transition handling
- Archive detection for merged features
- Plan generation orchestration
- Uses: `common.sh`, `git.sh` functions

**3. scripts/build.sh** (from commands/build.md)
- Progress tracking
- Test/build execution
- Log management
- Uses: `common.sh`, `validation.sh` functions

**4. scripts/check.sh** (from commands/check.md)
- Validation suite runner
- Test/lint/typecheck/build orchestration
- Uses: `common.sh`, `validation.sh` functions

**5. scripts/ship.sh** (from commands/ship.md)
- Check execution before shipping
- PR creation via gh CLI
- Metadata capture (.shipped-entry, .pr-url)
- Uses: `common.sh`, `validation.sh`, `archive.sh` functions

**6. scripts/archive.sh** (from commands/archive.md)
- SHIPPED.md updates
- Spec directory cleanup
- Archive commit creation
- **Auto-tagging**: Read VERSION (or package.json version), create git tag, push tags
- Uses: `common.sh`, `git.sh`, `archive.sh` (lib) functions

### Enhanced Archive Script with Auto-Tagging

When extracting `scripts/archive.sh`, add auto-tagging functionality:

```bash
#!/bin/bash
# scripts/archive.sh

set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/archive.sh"

# Extract from commands/archive.md
# Add auto-tagging after archive

auto_tag_release() {
    # Try VERSION file first
    if [[ -f "VERSION" ]]; then
        local version=$(cat VERSION | tr -d '[:space:]')
        local tag="v$version"

        if ! git tag | grep -q "^$tag$"; then
            info "Auto-tagging release: $tag"
            git tag "$tag"
            git push --tags
            success "Tagged $tag"
        else
            warning "Tag $tag already exists, skipping"
        fi
        return 0
    fi

    # Try package.json as fallback
    if [[ -f "package.json" ]] && command -v jq &>/dev/null; then
        local version=$(jq -r '.version' package.json)
        if [[ "$version" != "null" ]]; then
            local tag="v$version"

            if ! git tag | grep -q "^$tag$"; then
                info "Auto-tagging release: $tag"
                git tag "$tag"
                git push --tags
                success "Tagged $tag"
            else
                warning "Tag $tag already exists, skipping"
            fi
            return 0
        fi
    fi

    # No version file found
    warning "No VERSION or package.json found, skipping auto-tag"
    return 0
}

# Main logic from commands/archive.md
FEATURE="$1"

if [[ -z "$FEATURE" ]]; then
    error "Usage: archive.sh <feature-name>"
    exit 1
fi

# Run archive (from lib)
archive_feature "$FEATURE"

# Auto-tag the release
auto_tag_release
```

### Extraction Guidelines

**Pattern to follow**:
```bash
#!/bin/bash
# scripts/{command}.sh

set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/{other-deps}.sh"

# Argument parsing
ARG1="$1"

# Validation
check_file_exists "$ARG1" "Required argument missing"

# Main logic using library functions
info "Starting {command}"
result=$(some_library_function "$ARG1")

if [[ $? -eq 0 ]]; then
    success "Completed {command}"
else
    error "Failed {command}"
    exit 1
fi
```

**Key principles**:
- Use `set -e` for fail-fast
- Source only needed library files
- Use library functions instead of duplicating logic
- Proper error handling with exit codes
- Clear info/success/error messages
- Validate arguments before processing

### Current Bash Locations (What to Extract)

**commands/spec.md** (~50 lines):
- Lines 30-80: Directory creation, template copying

**commands/plan.md** (~120 lines):
- Lines 40-70: Branch transition logic
- Lines 80-110: Archive detection
- Lines 120-160: Plan generation coordination

**commands/build.md** (~60 lines):
- Lines 25-85: Progress tracking, validation running

**commands/check.md** (~80 lines):
- Lines 20-100: Test/lint/typecheck/build orchestration

**commands/ship.md** (~90 lines):
- Lines 30-60: Check execution
- Lines 70-120: PR creation, metadata capture

**commands/archive.md** (~50 lines):
- Lines 20-70: SHIPPED.md update, cleanup, commit

## Validation Criteria

 **6 scripts created**: spec.sh, plan.sh, build.sh, check.sh, ship.sh, archive.sh
 **All scripts executable**: `chmod +x` applied
 **All scripts have proper shebang**: `#!/bin/bash` at line 1
 **All scripts use set -e**: Fail-fast behavior
 **All scripts source dependencies**: Proper sourcing of lib files
 **No syntax errors**: `bash -n` passes on all scripts
 **Shellcheck clean**: No warnings
 **No duplicate logic**: Logic moved to lib, not duplicated in scripts
 **Auto-tagging works**: archive.sh creates and pushes git tags from VERSION
 **Commands unchanged**: commands/*.md still have embedded bash (Phase 3 will update)

## Success Metrics

 **~400 lines extracted**: From 5 command files to 6 script files
 **6 scripts created**: All in scripts/ directory
 **Zero duplication**: Reused library functions, no copy/paste
 **Shellcheck passes**: All scripts clean
 **Scripts executable independently**: Can run `./scripts/check.sh` (even if it fails due to no wiring)
 **Auto-tagging implemented**: archive.sh reads VERSION/package.json and creates git tags

## Testing Strategy

### Syntax Validation
```bash
bash -n scripts/spec.sh
bash -n scripts/plan.sh
bash -n scripts/build.sh
bash -n scripts/check.sh
bash -n scripts/ship.sh
bash -n scripts/archive.sh
```

### Shellcheck
```bash
shellcheck scripts/*.sh
```

### Source Verification
```bash
# Verify each script can source its dependencies without error
bash -c "source scripts/check.sh 2>&1 | head -5"
# Should show script starting, not sourcing errors
```

### Independence Test
```bash
# Try running scripts directly (may fail at runtime, but should load)
./scripts/check.sh 2>&1 | grep -v "not found" || echo "Script loaded"
```

## Implementation Notes

**Extraction process**:
1. Read current bash in commands/*.md
2. Identify reusable logic → use library functions
3. Identify unique logic → keep in script
4. Replace hard-coded paths with `get_project_root()` etc
5. Replace echo with info/success/error functions
6. Add proper argument validation
7. Add exit code handling

**What this phase does NOT do**:
- ❌ No modification of commands/*.md (Phase 3)
- ❌ No installer updates (Phase 3)
- ❌ No integration testing (commands still use old bash)
- ❌ No end-to-end workflow testing (Phase 3)

**After this phase**:
- Review: Did extraction preserve logic correctly?
- Ship: Merge to main
- Learn: Any patterns to adjust in Phase 3?

## Example: check.sh Extraction

**Before** (commands/check.md lines 20-100):
```bash
echo "Running validation suite..."

# Run tests
if [ -f "package.json" ]; then
    npm test || exit 1
fi

# Run linter
if grep -q '"lint"' package.json; then
    npm run lint || exit 1
fi

echo "All checks passed"
```

**After** (scripts/check.sh):
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validation.sh"

info "Running validation suite"

if run_validation_suite; then
    success "All checks passed"
    exit 0
else
    error "Validation failed"
    exit 1
fi
```

## References

- **Phase 1**: Library functions (merged)
- **Current commands**: commands/*.md (source of bash to extract)
- **Phase 3**: Will update commands to call these scripts
- **Bash best practices**: https://google.github.io/styleguide/shellguide.html
