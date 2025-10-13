# Implementation Plan: Script Library Phase 1 - Build the Toolkit
Generated: 2025-10-13
Specification: spec.md

## Understanding

This is Phase 1 of a 3-phase refactoring to extract ~400 lines of bash from command markdown files into a maintainable script library.

**This Phase**: Build the primitive function library and CLI wrapper
- 4 library modules in scripts/lib/ (~320 lines)
- 1 CLI wrapper in bin/ (~50 lines)
- No integration with existing commands yet

**Why Phase 1 First**: Establish well-tested primitives before extraction (Phase 2) and integration (Phase 3). Review question: "Are these primitive functions correct?"

**Scope Boundaries**:
- ✅ Build reusable functions for git, validation, archiving, common utilities
- ✅ Build csw CLI wrapper with routing logic
- ✅ Test syntax, shellcheck, sourcing
- ❌ NO modification of commands/*.md (Phase 3)
- ❌ NO extraction of command bash (Phase 2)
- ❌ NO installer updates (Phase 3)
- ❌ NO functional end-to-end testing (nothing calls these yet)

## Relevant Files

**Files to Create**:
- `scripts/lib/common.sh` - Base layer: logging, paths, file ops, validation (~80 lines)
- `scripts/lib/git.sh` - Git operations: branches, merging, repo state (~100 lines)
- `scripts/lib/validation.sh` - Test/lint/build runners with package manager detection (~80 lines)
- `scripts/lib/archive.sh` - Archive operations for completed features (~60 lines)
- `bin/csw` - CLI wrapper with command routing (~50 lines)

**Reference Patterns** (for context, but not directly used in Phase 1):
- Similar CLI wrapper pattern: git-flow, npm, cargo
- Library sourcing pattern: Standard bash library approach

**Files NOT Modified in This Phase**:
- commands/*.md - Unchanged (Phase 3 will update)
- install.sh - Unchanged (Phase 3 will update)
- init-project.sh - Unchanged (Phase 3 will update)

## Architecture Impact

- **Subsystems affected**: Script library (new subsystem)
- **New dependencies**: None
- **Breaking changes**: None (additive only)

## Task Breakdown

### Task 1: Create Directory Structure
**Action**: CREATE
**Files**: scripts/, scripts/lib/, bin/

**Implementation**:
```bash
mkdir -p scripts/lib
mkdir -p bin
```

**Validation**:
```bash
test -d scripts/lib && echo "✓ scripts/lib exists"
test -d bin && echo "✓ bin exists"
```

---

### Task 2: Build scripts/lib/common.sh (Base Layer)
**File**: scripts/lib/common.sh
**Action**: CREATE
**Pattern**: Base layer with no dependencies

**Implementation**:
Create file with:
- Shebang: `#!/bin/bash`
- Color output functions: info(), success(), error(), warning()
- Path helpers: get_project_root(), get_spec_dir(), extract_feature_from_path()
- File operations: ensure_directory(), safe_delete()
- Validation helpers: check_file_exists(), check_command_exists()

**Key Functions**:
```bash
#!/bin/bash
# Shared utilities used by all scripts

# Color output functions
info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
warning() { echo -e "\033[0;33m[WARNING]\033[0m $*"; }

# Path helpers
get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

get_spec_dir() {
    echo "$(get_project_root)/spec"
}

extract_feature_from_path() {
    local path="$1"
    basename "$(dirname "$path")"
}

# File operations
ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
}

safe_delete() {
    local path="$1"
    if [[ -e "$path" ]]; then
        rm -rf "$path"
    fi
}

# Validation helpers
check_file_exists() {
    local file="$1"
    local message="${2:-File not found: $file}"
    if [[ ! -f "$file" ]]; then
        error "$message"
        return 1
    fi
}

check_command_exists() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        error "Required command not found: $cmd"
        return 1
    fi
}
```

**Validation**:
```bash
bash -n scripts/lib/common.sh
shellcheck scripts/lib/common.sh
bash -c "source scripts/lib/common.sh && info 'common.sh loaded successfully'"
```

---

### Task 3: Build scripts/lib/git.sh (Git Operations)
**File**: scripts/lib/git.sh
**Action**: CREATE
**Pattern**: Sources common.sh, provides git abstractions

**Implementation**:
Create file with:
- Shebang + sourcing: `source "$(dirname "${BASH_SOURCE[0]}")/common.sh"`
- Branch operations: get_current_branch(), get_main_branch(), is_branch_merged(), create_feature_branch(), delete_merged_branch()
- Merge detection: is_merge_commit(), extract_pr_from_commit(), get_merge_commit_hash()
- Repository state: ensure_clean_working_tree(), sync_with_remote()
- High-level workflow: handle_branch_transition()

**Key Functions**:
```bash
#!/bin/bash
# Git operations

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

get_current_branch() {
    git branch --show-current
}

get_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        error "Could not find main or master branch"
        return 1
    fi
}

is_branch_merged() {
    local branch="$1"
    local main_branch=$(get_main_branch)
    git fetch origin >/dev/null 2>&1
    git branch -r --merged "origin/$main_branch" | grep -q "$branch"
}

create_feature_branch() {
    local feature="$1"
    local branch="feature/$feature"

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        warning "Branch $branch already exists"
        git checkout "$branch"
    else
        info "Creating branch: $branch"
        git checkout -b "$branch"
    fi
}

delete_merged_branch() {
    local branch="$1"
    if is_branch_merged "$branch"; then
        info "Deleting merged branch: $branch"
        git branch -d "$branch" 2>/dev/null || git branch -D "$branch"
    else
        warning "Branch $branch is not fully merged, skipping delete"
    fi
}

is_merge_commit() {
    local commit="${1:-HEAD}"
    local parents=$(git rev-list --parents -n 1 "$commit" | wc -w)
    [[ $parents -gt 2 ]]
}

extract_pr_from_commit() {
    local commit="${1:-HEAD}"
    local message=$(git log -1 --format=%s "$commit")

    if [[ "$message" =~ Merge\ pull\ request\ \#([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

get_merge_commit_hash() {
    local commit="${1:-HEAD}"
    git rev-parse --short "$commit"
}

ensure_clean_working_tree() {
    if [[ -n $(git status --porcelain) ]]; then
        error "Working tree has uncommitted changes"
        git status --short
        return 1
    fi
}

sync_with_remote() {
    local branch="${1:-$(get_current_branch)}"
    info "Syncing with origin/$branch"
    git fetch origin
    git pull origin "$branch"
}

handle_branch_transition() {
    local new_feature="$1"
    local current_branch=$(get_current_branch)
    local main_branch=$(get_main_branch)

    if [[ "$current_branch" != "$main_branch" ]]; then
        if is_branch_merged "$current_branch"; then
            info "Detected merged branch: $current_branch"
        fi

        info "Switching to $main_branch"
        git checkout "$main_branch"
        sync_with_remote "$main_branch"
        delete_merged_branch "$current_branch"
    else
        sync_with_remote "$main_branch"
    fi

    create_feature_branch "$new_feature"
}
```

**Validation**:
```bash
bash -n scripts/lib/git.sh
shellcheck scripts/lib/git.sh
bash -c "source scripts/lib/git.sh && echo 'git.sh loaded successfully'"
```

---

### Task 4: Build scripts/lib/validation.sh (Test/Lint/Build Runners)
**File**: scripts/lib/validation.sh
**Action**: CREATE
**Pattern**: Sources common.sh, provides validation abstractions

**Implementation**:
Create file with:
- Shebang + sourcing
- Package manager detection: detect_package_manager()
- Individual runners: run_tests(), run_linter(), run_type_checker(), run_build()
- Orchestration: run_validation_suite()

**Key Functions**:
```bash
#!/bin/bash
# Test and validation runners

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

detect_package_manager() {
    if [[ -f "package.json" ]]; then
        if [[ -f "package-lock.json" ]]; then
            echo "npm"
        elif [[ -f "yarn.lock" ]]; then
            echo "yarn"
        elif [[ -f "pnpm-lock.yaml" ]]; then
            echo "pnpm"
        else
            echo "npm"
        fi
    fi
}

run_tests() {
    local pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        info "Running tests with $pm"
        $pm test
        return $?
    fi

    warning "No test runner detected"
    return 0
}

run_linter() {
    local pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        if grep -q '"lint"' package.json 2>/dev/null; then
            info "Running linter with $pm"
            $pm run lint
            return $?
        fi
    fi

    warning "No linter configured"
    return 0
}

run_type_checker() {
    local pm=$(detect_package_manager)

    if [[ -f "tsconfig.json" ]]; then
        info "Running TypeScript type checker"
        if [[ -n "$pm" ]]; then
            $pm run tsc --noEmit 2>/dev/null || tsc --noEmit
            return $?
        fi
    fi

    return 0
}

run_build() {
    local pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        if grep -q '"build"' package.json 2>/dev/null; then
            info "Running build with $pm"
            $pm run build
            return $?
        fi
    fi

    warning "No build script configured"
    return 0
}

run_validation_suite() {
    local failed=0

    echo ""
    info "=== Running Validation Suite ==="
    echo ""

    if ! run_tests; then
        error "Tests failed"
        ((failed++))
    fi

    if ! run_linter; then
        error "Linter failed"
        ((failed++))
    fi

    if ! run_type_checker; then
        error "Type checking failed"
        ((failed++))
    fi

    if ! run_build; then
        error "Build failed"
        ((failed++))
    fi

    echo ""
    if [[ $failed -eq 0 ]]; then
        success "=== All Validation Checks Passed ==="
        return 0
    else
        error "=== $failed Validation Check(s) Failed ==="
        return 1
    fi
}
```

**Validation**:
```bash
bash -n scripts/lib/validation.sh
shellcheck scripts/lib/validation.sh
bash -c "source scripts/lib/validation.sh && echo 'validation.sh loaded successfully'"
```

---

### Task 5: Build scripts/lib/archive.sh (Archive Operations)
**File**: scripts/lib/archive.sh
**Action**: CREATE
**Pattern**: Sources common.sh and git.sh, provides archive abstractions

**Implementation**:
Create file with:
- Shebang + sourcing both common.sh and git.sh
- Shipping metadata: create_shipped_entry_template(), update_shipped_md()
- Cleanup: delete_spec_directory()
- High-level workflow: archive_feature()

**Key Functions**:
```bash
#!/bin/bash
# Archive operations for completed features

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git.sh"

create_shipped_entry_template() {
    local feature="$1"
    local pr_number="$2"
    local pr_url="$3"
    local spec_dir="$(get_spec_dir)/active/$feature"

    ensure_directory "$spec_dir"

    cat > "$spec_dir/.shipped-entry" << EOF
## $feature
- **Date**: $(date +%Y-%m-%d)
- **PR**: [#$pr_number]($pr_url)
- **Commit**: MERGE_COMMIT_PLACEHOLDER
- **Branch**: feature/$feature
EOF

    echo "$pr_url" > "$spec_dir/.pr-url"

    success "Created shipping metadata for $feature"
}

update_shipped_md() {
    local feature="$1"
    local spec_dir="$(get_spec_dir)/active/$feature"
    local shipped_entry="$spec_dir/.shipped-entry"
    local shipped_md="$(get_spec_dir)/SHIPPED.md"

    if [[ ! -f "$shipped_entry" ]]; then
        error "No .shipped-entry found for $feature"
        error "Run /ship first to create PR and metadata"
        return 1
    fi

    local merge_commit=$(get_merge_commit_hash)
    local entry=$(cat "$shipped_entry" | sed "s/MERGE_COMMIT_PLACEHOLDER/$merge_commit/")

    if [[ -f "$shipped_md" ]]; then
        {
            head -n 2 "$shipped_md"
            echo ""
            echo "$entry"
            echo ""
            tail -n +3 "$shipped_md"
        } > "$shipped_md.tmp"
        mv "$shipped_md.tmp" "$shipped_md"
    else
        cat > "$shipped_md" << EOF
# Shipped Features

$entry
EOF
    fi

    success "Updated SHIPPED.md with $feature"
}

delete_spec_directory() {
    local feature="$1"
    local spec_dir="$(get_spec_dir)/active/$feature"

    if [[ -d "$spec_dir" ]]; then
        info "Archiving spec directory: $spec_dir"
        safe_delete "$spec_dir"
        success "Archived $feature"
    else
        warning "Spec directory not found: $spec_dir"
    fi
}

archive_feature() {
    local feature="$1"

    info "Archiving feature: $feature"

    update_shipped_md "$feature"
    delete_spec_directory "$feature"

    git add "$(get_spec_dir)/SHIPPED.md"
    git commit -m "chore: archive $feature specs"

    success "Feature $feature archived"
}
```

**Validation**:
```bash
bash -n scripts/lib/archive.sh
shellcheck scripts/lib/archive.sh
bash -c "source scripts/lib/archive.sh && echo 'archive.sh loaded successfully'"
```

---

### Task 6: Build bin/csw (CLI Wrapper)
**File**: bin/csw
**Action**: CREATE
**Pattern**: CLI wrapper with command routing, no dependencies

**Implementation**:
```bash
#!/bin/bash
# Claude Spec Workflow CLI wrapper

set -e

CSW_HOME="$HOME/.claude-spec-workflow"
SCRIPT_DIR="$CSW_HOME/scripts"

usage() {
    cat << EOF
Claude Spec Workflow (csw) - Specification-driven development CLI

Usage: csw <command> [arguments]

Commands:
  spec [name]        Create specification from conversation
  plan <spec-file>   Generate implementation plan
  build              Execute build with progress tracking
  check              Run validation suite (test/lint/build)
  ship <feature>     Create PR and prepare for merge
  archive <feature>  Archive completed feature

Examples:
  csw spec auth-system
  csw plan spec/active/auth-system/spec.md
  csw check
  csw ship auth-system

For more information: https://github.com/trakrf/claude-spec-workflow
EOF
}

case "${1:-}" in
    spec|plan|build|check|ship|archive)
        COMMAND="$1"
        shift
        exec "$SCRIPT_DIR/$COMMAND.sh" "$@"
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
    --version|-v)
        echo "csw 0.3.0"
        exit 0
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        usage
        exit 1
        ;;
esac
```

**Validation**:
```bash
bash -n bin/csw
shellcheck bin/csw
chmod +x bin/csw
./bin/csw --help
./bin/csw --version
```

---

### Task 7: Make All Scripts Executable
**Action**: MODIFY permissions
**Files**: All scripts in scripts/lib/ and bin/

**Implementation**:
```bash
chmod +x scripts/lib/common.sh
chmod +x scripts/lib/git.sh
chmod +x scripts/lib/validation.sh
chmod +x scripts/lib/archive.sh
chmod +x bin/csw
```

**Validation**:
```bash
test -x scripts/lib/common.sh && echo "✓ common.sh executable"
test -x scripts/lib/git.sh && echo "✓ git.sh executable"
test -x scripts/lib/validation.sh && echo "✓ validation.sh executable"
test -x scripts/lib/archive.sh && echo "✓ archive.sh executable"
test -x bin/csw && echo "✓ csw executable"
```

---

### Task 8: Run Shellcheck on All Scripts
**Action**: VALIDATE
**Pattern**: Use shellcheck to catch common bash issues

**Implementation**:
```bash
shellcheck scripts/lib/*.sh
shellcheck bin/csw
```

**Expected Output**: No warnings or errors

**If shellcheck not installed**:
```bash
# Install shellcheck (Ubuntu/Debian)
sudo apt-get install shellcheck

# Or use docker
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable scripts/lib/*.sh bin/csw
```

---

### Task 9: Test Sourcing Chain
**Action**: VALIDATE
**Pattern**: Verify all library files can be sourced without error

**Implementation**:
```bash
# Test common.sh (no dependencies)
bash -c "source scripts/lib/common.sh && info 'common.sh OK'"

# Test git.sh (depends on common.sh)
bash -c "source scripts/lib/git.sh && info 'git.sh OK'"

# Test validation.sh (depends on common.sh)
bash -c "source scripts/lib/validation.sh && info 'validation.sh OK'"

# Test archive.sh (depends on common.sh and git.sh)
bash -c "source scripts/lib/archive.sh && info 'archive.sh OK'"
```

**Expected Output**: All four show colored "[INFO] {file} OK" messages

---

### Task 10: Test csw Wrapper Basics
**Action**: VALIDATE
**Pattern**: Verify csw wrapper shows correct help and version

**Implementation**:
```bash
# Test help
./bin/csw --help

# Test version
./bin/csw --version

# Test unknown command
./bin/csw invalid-command 2>&1 | grep "Unknown command"

# Test missing script (should fail gracefully)
./bin/csw check 2>&1 | grep "scripts/check.sh"
```

**Expected Output**:
- Help shows usage with all 6 commands
- Version shows "csw 0.3.0"
- Unknown command shows error + usage
- Missing script shows exec error (expected since Phase 2 not done yet)

---

## Risk Assessment

**Low Risk Phase** - Building primitives with no integration

- **Risk**: Shellcheck warnings or syntax errors
  **Mitigation**: Run shellcheck after each file creation, fix immediately

- **Risk**: Sourcing circular dependencies
  **Mitigation**: common.sh has no dependencies, others only source common.sh

- **Risk**: Function naming conflicts
  **Mitigation**: Use descriptive names with context (get_current_branch not get_branch)

- **Risk**: Platform-specific bash features
  **Mitigation**: Use portable bash constructs, test on Linux/Mac

## Integration Points

None in this phase. Phase 2 will use these libraries, Phase 3 will integrate with commands and installers.

## VALIDATION GATES (MANDATORY)

After every code change:
```bash
# Gate 1: Syntax Check
bash -n {file}

# Gate 2: Shellcheck
shellcheck {file}

# Gate 3: Source Test
bash -c "source {file} && echo 'OK'"
```

**This is a shell script project** - use shellcheck as the primary validation tool.

## Validation Sequence

After each task:
```bash
bash -n {new-file}
shellcheck {new-file}
```

Final validation (after Task 10):
```bash
# All files pass shellcheck
shellcheck scripts/lib/*.sh bin/csw

# All files can be sourced
for f in scripts/lib/*.sh; do
    bash -c "source $f && echo '✓ $f'"
done

# csw wrapper works
./bin/csw --help
./bin/csw --version
```

## Plan Quality Assessment

**Complexity Score**: 3/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements - building primitive functions with specified signatures
✅ No external dependencies - pure bash
✅ No integration complexity - standalone scripts
✅ Similar patterns exist - git-flow, npm CLI wrappers
✅ Clear validation strategy - shellcheck + source testing
✅ No breaking changes - additive only
✅ Small scope - 5 files, ~370 lines
✅ Bash best practices guide available

**Assessment**: High confidence implementation. Building well-defined primitives with no integration complexity.

**Estimated one-pass success probability**: 95%

**Reasoning**: Straightforward bash function library creation with clear specifications, no dependencies, and clear validation criteria. Primary risk is minor shellcheck warnings, easily fixable. No architectural uncertainty or integration complexity.
