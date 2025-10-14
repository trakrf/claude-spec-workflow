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
