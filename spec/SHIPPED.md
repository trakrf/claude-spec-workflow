# Shipped Features

## End-of-Life PowerShell Installation Scripts
- **Date**: 2025-10-12
- **Branch**: feature/eol-powershell-support
- **Commit**: e34c8f51e650ccb5ec57dfb4ed7069eab93da5b2
- **Summary**: Standardized on bash-only installation, removing PowerShell scripts
- **Key Changes**:
  - Deleted 3 PowerShell installation scripts (install.ps1, init-project.ps1, uninstall.ps1)
  - Added Prerequisites section to README.md with Git Bash/WSL2 guidance
  - Updated CONTRIBUTING.md and TESTING.md to reflect bash-only workflow
  - Removed PowerShell linting commands from spec/stack.md and presets/shell-scripts.md
  - Consolidated all installation documentation to single bash path
- **Validation**:  All checks passed (shellcheck, syntax validation)

### Success Metrics
-  **Reduce installer codebase by 50%** - Result: Achieved (6 files ’ 3 files)
-  **Eliminate dual-implementation testing** - Result: Achieved (PowerShell tests removed)
-  **Future installer changes require single implementation** - Result: Achieved (only bash scripts remain)
-  **Windows users understand bash requirement** - Result: Achieved (Prerequisites section prominent)
- ó **No increase in "doesn't work on Windows" issues** - Result: To be measured in production
-  **Contribution friction reduced** - Result: Achieved (no more porting bash’PowerShell)

**Overall Success**: 83% of metrics achieved (5/6), 1 pending production measurement

- **PR**: Pending
