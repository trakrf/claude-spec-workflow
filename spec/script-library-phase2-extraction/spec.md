# Feature: Script Library Phase 2 - Extract Command Logic

## Origin
Part 2 of 3-phase refactoring. Phase 1 built the primitive functions. This phase extracts bash logic from command markdown files into scripts that use those primitives. Commands still run old embedded bash - Phase 3 will wire them to use these scripts.

## Outcome
Six executable scripts (`scripts/{spec,plan,build,check,ship,archive}.sh`) created by extracting ~400 lines of bash from `commands/*.md`. Scripts use Phase 1 library functions. Path simplified from `spec/active/feature/` to `spec/feature/` throughout codebase. README.md updated with Feature Lifecycle & Archive Workflow documentation. No integration yet - commands unchanged.

## User Story
As a developer refactoring claude-spec-workflow
I want to extract command logic into standalone scripts
So that Phase 3 can wire commands to call these scripts

## Context

**Phase 1 Complete**: Library functions and csw wrapper exist, tested, merged (v0.2.2)
**This Phase**: Extract command bash → scripts using library functions (v0.2.3)
**Next Phase**: Wire commands and installers to use these scripts (v0.3.0)

**Version**: This phase should be released as **0.2.3** (internal refactoring, PATCH version)

**Why this sequence**: Build primitives (✅) → compose primitives + simplify paths (this phase) → integrate (Phase 3)

**Path Simplification**: Removing `active/` from spec paths because specs are by definition active (we DELETE them when done). Simpler: `spec/feature/` instead of `spec/active/feature/`. Makes sense to do now while touching all path references.

**Arbitrary Nesting**: After `spec/`, developers can organize however they want. Flat (`spec/auth/`) or nested (`spec/frontend/auth/`, `spec/team-a/feature-x/`). Feature identity = full relative path under spec/. Enables monorepo team namespacing and custom organization.

**Smart Path Resolution**: Commands accept fragments, not full paths. Type `/plan auth` not `/plan spec/frontend/auth/spec.md`. Zero arguments? Auto-detect single spec. Reduces typing dramatically, especially with nested paths.

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
- Uses: `common.sh`, `git.sh`, `archive.sh` functions

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
- Uses: `common.sh`, `validation.sh` functions

**6. scripts/archive.sh** (from commands/archive.md)
- SHIPPED.md updates from metadata if available, git log if not
- Spec directory cleanup
- Archive commit creation
- Delete merged branch if applicable
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

### Path Simplification & Smart Resolution

**Current state**: `spec/active/feature/spec.md`
**New state**: `spec/feature/spec.md` (or nested: `spec/team/feature/spec.md`)

**Rationale**: "active" is redundant because we DELETE specs when done (they're always active).

**Smart Path Resolution**: Commands resolve specs intelligently, reducing typing. **Each command looks for the file it needs**, naturally filtering to actionable specs.

**Command-specific file lookup:**
- `/spec` → Looks for `spec.md` (checks to see if there is spec to revise rather than create)
- `/plan` → Looks for `spec.md` (needs spec to plan from)
- `/build` → Looks for `plan.md` (needs plan to build from)
- `/ship` → Looks for `plan.md` (needs completed build to ship)

**Resolution algorithm** (separation of concerns):

**Shell layer** - Returns ALL matching files:
```bash
# Just find everything - no filtering, no fragment matching
find spec/ -name "spec.md"    # for /plan
find spec/ -name "plan.md"    # for /build, /ship
```
- It's not as DRY but would it be more efficient to inline this into prompts

**Claude layer** - Intelligent fuzzy matching:
- Gets complete list of specs/plans from shell
- User provides fragment: `/plan auth` or `/plan authentication` (typo) or `/plan the frontend one`
- Claude fuzzy matches against the list
- Interprets results:
  1. **0 files exist** → "No specs found. Create one with /spec"
  2. **1 file exists** → Use it immediately
  3. **N files exist + fragment matches 1** → Use it immediately
  4. **N files exist + fragment matches multiple** → Prompt with numbered list
  5. **N files exist + no fragment** → Prompt with numbered list

**Why this works**: Claude is excellent at fuzzy matching, typo tolerance, and natural language understanding. Let the model do what it's good at.

**Examples:**

**Solo sequential workflow** (zero typing):
```bash
/spec new-feature              # Create spec/new-feature/
/plan                          # Auto-detect (only 1 spec exists)
/build                         # Auto-detect (only 1 spec exists)
/ship                          # Auto-detect (only 1 spec exists)
```

**Multi-spec workflow** (natural filtering):
```bash
/spec                          # Create a spec interactively, end up splitting it into 3 phase specs (3× spec.md)
/plan phase-1                  # Fragment matches spec/phase-1/, creates plan.md
/build                         # Auto-detect (only 1 plan.md exists - phase-1!)
/ship                          # Auto-detect (only 1 plan.md exists - phase-1!)
# User merges PR
/plan phase-2                  # Deletes phase-1, creates phase-2/plan.md
/build                         # Auto-detect (only phase-2/plan.md now)
/ship                          # Auto-detect (only phase-2/plan.md)
```

**Key insight**: Build/ship look for `plan.md`, so they automatically target the spec that's been planned, even if other specs exist!

**Nested paths** (Claude fuzzy matching):
```bash
# Specs exist: spec/frontend/auth/, spec/backend/auth/
/plan auth

# Bash returns ALL specs
# Claude fuzzy matches "auth" → finds both
# Claude prompts:
I found 2 specs matching "auth":
  1. frontend/auth
  2. backend/auth
Which one?

# User: "1" or "frontend" or "the frontend one"
# Claude resolves and proceeds

# Alternatively:
/plan frontend           # Claude fuzzy matches → unique match → immediate
/plan frontend/auth      # Claude exact match → immediate
/plan authenication      # Claude tolerates typo → matches "auth" specs
```

**Arbitrary Nesting Support**: After `spec/`, organize however you want:
- Flat: `spec/auth/`, `spec/dashboard/`
- By layer: `spec/frontend/auth/`, `spec/backend/users/`
- By team: `spec/team-a/feature-x/`, `spec/team-b/feature-y/`
- Deep nesting: `spec/v2/api/endpoints/users/`

**Feature Identity**: Full relative path under spec/
- `spec/auth/` → feature: `"auth"`
- `spec/frontend/auth/` → feature: `"frontend/auth"`
- `spec/team-a/feature-x/` → feature: `"team-a/feature-x"`

**Files to update**:
1. **scripts/lib/common.sh** - Update `extract_feature_from_path()` for nested paths (no resolve function needed - Claude does matching)
2. **scripts/lib/archive.sh** - Update to handle nested paths
3. **scripts/plan.sh** - Find all spec.md files, output list, exit with count
4. **scripts/build.sh** - Find all plan.md files, output list, exit with count
5. **scripts/ship.sh** - Find all plan.md files, output list, exit with count
6. **commands/*.md** - Document fuzzy matching flow: Claude gets list from bash, fuzzy matches user fragment, prompts if ambiguous
7. **spec/README.md** - Update directory structure diagram, document separation (bash=find, Claude=match)
8. **spec/template.md** - If paths are referenced

### Documentation Requirements

**Update spec/README.md** to document the archive/breadcrumb workflow:

**Location**: Add new section after "Workflow Overview" (around line 60)

**Content**: New section titled "## Feature Lifecycle & Archive Workflow"

**What to document**:
1. **Breadcrumb pattern**: How /ship creates .shipped-entry breadcrumbs with PR details before merge commit is known
2. **Archive = DELETE**: Clarify that "archive" means DELETE from spec/feature/, not move to spec/archive/ directory
3. **Piggybacking cleanup**: Why cleanup commits go on the next feature branch (avoids extra merge)
4. **Git history preservation**: Specs preserved at merge commit, SHIPPED.md provides reference
5. **Path simplification**: Note the change from spec/active/feature to spec/feature
6. **Arbitrary nesting**: After spec/, organize however you want (flat, by team, by layer, etc.)
7. **Smart resolution**: How `/plan`, `/plan auth`, and `/plan spec/auth/spec.md` all work
8. **Command-specific filtering**: /plan looks for spec.md, /build and /ship look for plan.md
9. **Interactive disambiguation**: Multiple matches prompt with numbered list (no need to re-run command)
10. **Zero-arg workflow**: Solo sequential work needs no path arguments, commands auto-target actionable specs

**Visual aid**: Include mermaid sequence diagram showing:
```
User → /build → /ship (breadcrumb) → merge PR → /plan (read breadcrumb, update SHIPPED.md, DELETE spec/feature)
```

**Directory structure update**: Update the structure diagram to reflect `spec/feature/` instead of `spec/active/feature/`, with examples of nested organization:
```
spec/
├── auth/              # Flat organization
├── frontend/          # Nested by layer
│   ├── dashboard/
│   └── settings/
└── team-a/            # Nested by team
    └── feature-x/
```

**Tone**: Explain the "why" behind the complexity - it's elegant once understood.

## Validation Gates

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
 **README.md updated**: Feature Lifecycle & Archive Workflow section added with mermaid diagram
 **Paths simplified**: All references changed from `spec/active/feature/` to `spec/feature/`
 **Directories migrated**: Existing spec/active/* moved to spec/, spec/active/ removed
 **No broken references**: All paths updated consistently across codebase
 **Nested paths supported**: Works with flat (`spec/auth/`) and nested (`spec/frontend/auth/`) organization
 **Recursive discovery**: Feature detection uses find, not glob patterns
 **Smart resolution works**: `/plan` auto-detects, `/plan auth` finds uniquely, ambiguity prompts interactively
 **Zero-arg workflow**: Single-spec projects need zero path arguments
 **Interactive prompts**: Multiple matches show numbered list, user selects by number or name

## Success Metrics

 **~400 lines extracted**: From 5 command files to 6 script files
 **6 scripts created**: All in scripts/ directory
 **Zero duplication**: Reused library functions, no copy/paste
 **Shellcheck passes**: All scripts clean
 **Scripts executable independently**: Can run `./scripts/check.sh` (even if it fails due to no wiring)
 **Auto-tagging implemented**: archive.sh reads VERSION/package.json and creates git tags
 **Workflow documented**: README.md updated with Feature Lifecycle section including mermaid diagram
 **Paths simplified**: `spec/feature/` used consistently, no more `spec/active/`
 **Migration complete**: All existing specs moved from spec/active/ to spec/
 **Arbitrary nesting supported**: Developers can organize specs in subdirectories (spec/team/feature/)
 **Nested organization documented**: README.md explains flat vs nested organization patterns
 **Smart resolution implemented**: Fragment matching and auto-detection reduce typing
 **Zero-arg workflow**: Commands work without arguments when single spec exists
 **Interactive disambiguation**: Multiple matches prompt with numbered list for selection

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

**Path simplification process**:
1. Update `get_spec_dir()` to return `spec/` instead of `spec/active/`
2. Update `extract_feature_from_path()` to return full relative path from spec/, not just basename
3. Update archive detection to use recursive discovery (find command) instead of `spec/active/*/`
4. Update all command documentation examples (show both flat and nested)
5. Update README.md structure diagram and document arbitrary nesting
6. Migrate existing directories from spec/active/* to spec/*
7. Verify no broken references remain

**Handling nested paths**:
- Discovery: `find spec/ -name "spec.md"` (recursive)
- Feature extraction: Remove `$(get_spec_dir)/` prefix, get dirname of remaining path
- Branch naming: Replace `/` with `-` for branch names (e.g., `frontend/auth` → `feature/frontend-auth`)
- SHIPPED.md: Use full feature path (e.g., `## frontend/auth`)

**Smart resolution implementation**:

**Shell script** (scripts/{plan,build,ship}.sh) - **Trivial, just find:**
```bash
#!/bin/bash
# scripts/plan.sh

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"

# Get ALL specs - no filtering
ALL_SPECS=($(find "$(get_spec_dir)" -name "spec.md"))

# Output them for Claude to process
for spec in "${ALL_SPECS[@]}"; do
    echo "$spec"
done

# Exit with count for easy checking
exit ${#ALL_SPECS[@]}
```

**Claude prompt** (commands/plan.md) - **Intelligent matching:**
```markdown
When user runs /plan [fragment]:

1. Run scripts/plan.sh to get all specs
2. Parse output into list of available specs
3. If fragment provided:
   - Fuzzy match fragment against spec paths
   - Handle typos, partial matches, natural language
4. Determine action:
   - 0 specs total → "No specs found. Run /spec to create one."
   - 1 spec total → Use it immediately
   - N specs + fragment matches 1 → Use matched spec
   - N specs + fragment matches multiple → Show numbered list, prompt user
   - N specs + no fragment → Show numbered list, prompt user
5. Once spec selected, proceed with planning

Example fuzzy matching:
- User: "/plan auth"
- Specs: ["frontend/auth", "backend/auth"]
- Match: Both contain "auth"
- Action: Prompt "Which one: 1) frontend/auth, 2) backend/auth?"

- User: "/plan frontend"
- Match: Only "frontend/auth" matches
- Action: Use frontend/auth immediately
```

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
