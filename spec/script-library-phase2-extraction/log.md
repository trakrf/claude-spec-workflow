# Build Log: Script Library Phase 2 - Extract Command Logic

## Session: 2025-10-14
Starting task: 1
Total tasks: 18

This build extracts bash logic from commands/*.md into standalone scripts, simplifies paths from spec/active/ to spec/, and documents the workflow.

**Strategy**:
1. Update library functions first (common.sh, archive.sh) - Tasks 1-2
2. Migrate spec directories (spec/active/ → spec/) - Task 3
3. Create 6 new scripts - Tasks 4-9
4. Update documentation (README.md, commands/*.md) - Tasks 10-15
5. Run comprehensive validation - Tasks 16-18

Validation after each task, commits every 3-5 tasks.

---

### Task 1: Update common.sh for new path structure
Started: 2025-10-14
File: scripts/lib/common.sh

**Changes**:
- Updated `extract_feature_from_path()` to support nested paths
- Returns full relative path under spec/ (e.g., "frontend/auth" for spec/frontend/auth/)
- Properly quoted variable in parameter expansion (shellcheck fix)

**Validation**: ✅ shellcheck passed, bash -n passed
Status: ✅ Complete
Completed: 2025-10-14

### Task 2: Update archive.sh library for nested paths
Started: 2025-10-14
File: scripts/lib/archive.sh

**Changes**:
- Updated `create_shipped_entry_template()`: spec/active/$feature → spec/$feature (line 12)
- Updated `update_shipped_md()`: spec/active/$feature → spec/$feature (line 37)
- Updated `delete_spec_directory()`: spec/active/$feature → spec/$feature (line 79)

**Validation**: ✅ bash -n passed (SC1091 info messages expected)
Status: ✅ Complete
Completed: 2025-10-14

### Task 3: Migrate existing spec directories
Started: 2025-10-14

**Changes**:
- Migrated 4 specs from spec/active/ to spec/:
  - bootstrap-spec-generation
  - robust-pr-creation
  - script-library-phase2-extraction (current feature)
  - script-library-phase3-wiring
- Removed spec/active/ directory
- Git detected moves as renames (preserves history)

**Validation**: ✅ Directory structure verified
Status: ✅ Complete
Completed: 2025-10-14

**Note**: spec/archive/ directory exists but is unrelated to this migration. Per spec, archive means DELETE (not move to archive/), so that directory may be from older workflow.

### Task 4: Create scripts/spec.sh
Started: 2025-10-14
File: scripts/spec.sh

**Implementation**:
- Directory setup for new specs
- Template copying from spec/template.md
- Sources common.sh for utility functions
- Proper error handling and exit codes

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

### Task 5: Create scripts/plan.sh
Started: 2025-10-14
File: scripts/plan.sh

**Implementation**:
- Finds all spec.md files recursively under spec/
- Returns complete list for Claude to fuzzy match
- Exits with count for easy detection
- No filtering - Claude handles matching

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

### Task 6: Create scripts/build.sh
Started: 2025-10-14
File: scripts/build.sh

**Implementation**:
- Finds all plan.md files recursively
- Same pattern as plan.sh but for build targets
- Command-specific filtering (build looks for plan.md)

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

### Task 7: Create scripts/check.sh
Started: 2025-10-14
File: scripts/check.sh

**Implementation**:
- Validation suite orchestration
- Sources validation.sh library
- Runs run_validation_suite() from library
- Proper exit codes for CI/CD

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

### Task 8: Create scripts/ship.sh
Started: 2025-10-14
File: scripts/ship.sh

**Implementation**:
- Finds all plan.md files for shipping candidates
- Same pattern as build.sh (ship looks for completed builds)
- Claude handles PR creation and breadcrumbs in prompt layer

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

### Task 9: Create scripts/archive.sh with auto-tagging
Started: 2025-10-14
File: scripts/archive.sh

**Implementation**:
- Sources common.sh, git.sh, archive.sh (lib)
- Calls archive_feature() from library
- Auto-tagging: reads VERSION file, creates git tag, pushes tags
- Fallback to package.json if VERSION not found
- Checks for duplicate tags before creating

**Validation**: ✅ bash -n passed, executable
Status: ✅ Complete
Completed: 2025-10-14

**Summary**: 6 scripts created (spec, plan, build, check, ship, archive), all executable, all validated.
**Commit point**: Tasks 1-9 complete - foundational changes and scripts done.
