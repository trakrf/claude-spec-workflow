# Feature: Script Library Phase 1 - Build the Toolkit

## Origin
Part 1 of 3-phase refactoring to extract ~400 lines of bash from markdown commands into maintainable script library. This phase builds the primitive functions and CLI wrapper without any integration.

## Outcome
Core script library infrastructure created with reusable functions for git operations, validation, archiving, and common utilities. CLI wrapper (`csw`) established with routing logic. Nothing uses these yet - Phase 2 will extract command logic, Phase 3 will wire it up.

## User Story
As a developer refactoring claude-spec-workflow
I want to build the primitive function library first
So that Phase 2 can extract command logic using well-tested building blocks

## Context

**Current State**: ~400 lines of bash scattered across 5 command files with duplicated logic and no reusability.

**This Phase**: Build the toolkit - 5 library modules and 1 CLI wrapper. No integration yet.

**Next Phases**:
- Phase 2: Extract command bash into scripts that use this toolkit
- Phase 3: Update commands and installers to wire everything together

**Why this sequence**: Build primitives → compose primitives → integrate. Classic bottom-up refactoring.

## Technical Requirements

### Directory Structure

Create:
```
scripts/
├── lib/
│   ├── common.sh          # Logging, paths, validation helpers (~80 lines)
│   ├── git.sh             # Git operations (~100 lines)
│   ├── validation.sh      # Test/lint/build runners (~80 lines)
│   └── archive.sh         # Archive operations (~60 lines)
bin/
└── csw                     # CLI wrapper with routing (~50 lines)
```

### scripts/lib/common.sh (~80 lines)

**Purpose**: Base layer - logging, path helpers, file operations, validation helpers

**Functions to implement**:
```bash
#!/bin/bash
# Shared utilities used by all scripts

# Color output (info, success, error, warning)
info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
warning() { echo -e "\033[0;33m[WARNING]\033[0m $*"; }

# Path helpers
get_project_root()           # Returns git root or pwd
get_spec_dir()               # Returns {project_root}/spec
extract_feature_from_path()  # Extract feature name from spec/active/feature/spec.md

# File operations
ensure_directory()           # mkdir -p wrapper
safe_delete()                # rm -rf with existence check

# Validation helpers
check_file_exists()          # Verify file exists, error if not
check_command_exists()       # Verify command available, error if not
```

**Dependencies**: None (base layer)

### scripts/lib/git.sh (~100 lines)

**Purpose**: Git operations - branches, merging, repository state

**Functions to implement**:
```bash
#!/bin/bash
# Git operations

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Branch operations
get_current_branch()         # git branch --show-current
get_main_branch()            # Detect main or master
is_branch_merged()           # Check if branch merged to main
create_feature_branch()      # Create feature/{name} branch
delete_merged_branch()       # Delete after merge confirmation

# Merge detection
is_merge_commit()            # Check if commit has 2 parents
extract_pr_from_commit()     # Parse PR number from merge message
get_merge_commit_hash()      # Get short hash

# Repository state
ensure_clean_working_tree()  # Error if uncommitted changes
sync_with_remote()           # Fetch and pull from origin

# High-level workflow
handle_branch_transition()   # Switch from merged feature to new feature
```

**Dependencies**: `common.sh`

### scripts/lib/validation.sh (~80 lines)

**Purpose**: Test/lint/build runners with package manager detection

**Functions to implement**:
```bash
#!/bin/bash
# Test and validation runners

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Package manager detection
detect_package_manager()     # Detect npm/yarn/pnpm from lock files

# Individual runners
run_tests()                  # Run package manager test command
run_linter()                 # Run lint if script exists in package.json
run_type_checker()           # Run tsc --noEmit if tsconfig.json exists
run_build()                  # Run build if script exists

# Orchestration
run_validation_suite()       # Run all checks, report results
```

**Dependencies**: `common.sh`

### scripts/lib/archive.sh (~60 lines)

**Purpose**: Archive operations for completed features

**Functions to implement**:
```bash
#!/bin/bash
# Archive operations for completed features

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git.sh"

# Shipping metadata
create_shipped_entry_template()  # Create .shipped-entry with placeholder
update_shipped_md()              # Prepend entry to SHIPPED.md (reverse chronological)

# Cleanup
delete_spec_directory()          # Remove spec/active/{feature}/

# High-level workflow
archive_feature()                # Full archive: update SHIPPED.md, delete spec, commit
```

**Dependencies**: `common.sh`, `git.sh`

### bin/csw (~50 lines)

**Purpose**: CLI wrapper that routes commands to scripts

**Implementation**:
```bash
#!/bin/bash
# Claude Spec Workflow CLI wrapper

set -e

CSW_HOME="$HOME/.claude-spec-workflow"
SCRIPT_DIR="$CSW_HOME/scripts"

# Show usage
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

# Route to appropriate script
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

**Dependencies**: None (but expects scripts/*.sh to exist eventually)

## Validation Criteria

 **Directory structure created**: `scripts/lib/`, `bin/` exist
 **All files executable**: `chmod +x` on all scripts
 **common.sh sources successfully**: No syntax errors, functions defined
 **git.sh sources common.sh**: All dependencies resolve
 **validation.sh sources common.sh**: All dependencies resolve
 **archive.sh sources common.sh and git.sh**: All dependencies resolve
 **csw wrapper executes**: `./bin/csw --help` shows usage
 **csw version works**: `./bin/csw --version` shows "csw 0.3.0"
 **Shellcheck clean**: No shellcheck warnings on any file

## Success Metrics

 **5 library files created**: common.sh, git.sh, validation.sh, archive.sh (~320 lines)
 **1 CLI wrapper created**: bin/csw (~50 lines)
 **All scripts pass shellcheck**: Zero warnings
 **All sourcing works**: No missing dependencies
 **Functions are well-documented**: Comments explain purpose and usage

## Testing Strategy

### Syntax Validation
```bash
# Check all scripts for syntax errors
bash -n scripts/lib/common.sh
bash -n scripts/lib/git.sh
bash -n scripts/lib/validation.sh
bash -n scripts/lib/archive.sh
bash -n bin/csw
```

### Shellcheck
```bash
# Run shellcheck on all scripts
shellcheck scripts/lib/*.sh
shellcheck bin/csw
```

### Source Testing
```bash
# Verify sourcing works
bash -c "source scripts/lib/common.sh && echo 'common.sh OK'"
bash -c "source scripts/lib/git.sh && echo 'git.sh OK'"
bash -c "source scripts/lib/validation.sh && echo 'validation.sh OK'"
bash -c "source scripts/lib/archive.sh && echo 'archive.sh OK'"
```

### CLI Wrapper Testing
```bash
# Test basic csw commands
./bin/csw --help
./bin/csw --version
./bin/csw check 2>&1 | grep "scripts/check.sh" # Should show missing script error
```

## Implementation Notes

**Key decisions**:
- Use `set -e` in all scripts for fail-fast behavior
- Color output for better UX (info=blue, success=green, error=red, warning=yellow)
- All errors go to stderr (`>&2`)
- Functions return proper exit codes (0=success, 1=failure)
- Use `local` for all function variables to avoid pollution
- Source using `$(dirname "${BASH_SOURCE[0]}")` for portability

**Bash best practices**:
- Quote all variables: `"$var"` not `$var`
- Use `[[ ]]` not `[ ]` for conditionals
- Use `$()` not backticks for command substitution
- Check command existence with `command -v` not `which`

**What this phase does NOT do**:
- ❌ No integration with existing commands
- ❌ No modification of commands/*.md
- ❌ No installer updates
- ❌ No scripts/*.sh files (Phase 2)
- ❌ No functional testing (nothing calls these yet)

**After this phase**:
- Review: Are these primitive functions correct?
- Ship: Merge to main
- Learn: Any patterns to improve before Phase 2?

## References

- **Bash best practices**: https://google.github.io/styleguide/shellguide.html
- **XDG Base Directory**: https://specifications.freedesktop.org/basedir-spec/latest/
- **Phase 2**: Will extract command logic using these primitives
- **Phase 3**: Will wire everything together with installers
