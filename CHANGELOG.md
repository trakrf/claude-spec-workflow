# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-11

> **Pre-release for dogfooding**: Initial implementation to be validated through real-world use before v1.0.0 public release.

### Added

- Specification-driven development workflow with 5 slash commands: `/spec`, `/plan`, `/build`, `/check`, `/ship`
- Cross-platform installation scripts (Unix .sh + Windows .ps1)
- Project initialization system (`init-project` and `init-stack`)
- Stack configuration presets: TypeScript + React + Vite, Next.js App Router, Python + FastAPI, Go standard, Monorepo (Go + React + TimescaleDB)
- Template system for specs, configs, and documentation
- Example specification: User Profile Editing feature
- Automatic complexity assessment (0-10 scoring) in `/plan` command
- Complexity scoring based on file impact, subsystem coupling, task count, dependencies, and pattern novelty
- Mandatory split recommendation for features scoring 6-10/10
- Optional phase breakdown generation for complex features
- Mandatory clarifying questions gate before plan generation
- Quality/confidence scoring in implementation plans with one-pass success probability
- ULTRATHINK strategic thinking checkpoints in all 5 commands
- Mandatory validation gates: lint, types, tests, build (BLOCKING requirements)
- Full test suite gate before any commit in `/build` (cannot skip, 100% pass required)
- Code cleanup gate before final validation (removes console.log, debugger, commented code)
- Auto-detection and defaults for Node/TypeScript, Rust, Go, Python stacks
- Stack-aware validation commands and patterns
- Workspace-aware validation for monorepo projects
- Success Metrics section in spec template with tracking in SHIPPED.md
- Conventional Commits format with semantic versioning support
- Role-based personas for each command (Product Engineer, Architect, Engineer, Test Engineer, Tech Lead)
- Automatic archival of shipped features during `/plan` with y/n prompts
- SHIPPED.md tracking with date, commit, and success metrics
- Comprehensive README with installation and usage instructions
- Installation guides for macOS, Linux, and Windows
- Quick start guide with step-by-step workflow
- Stack configuration examples for single-stack and monorepo projects
- Complexity assessment methodology and examples
- Conventional commit format examples
- Troubleshooting sections for validation and workflow issues
- MIT License

## [Unreleased]

### Fixed

- Fix output formatting across all workflow commands (/plan, /check, /build, /ship)
  - Added explicit OUTPUT FORMATTING RULES sections to prevent list item concatenation
  - Each command now includes visual examples (✅ correct vs ❌ wrong) for clear guidance
  - Resolves issue where multiple choice options, checkmarks, and bullet points were rendered as walls of text
- Fix `csw install` failing to create CLI symlink due to arithmetic operator bug with `set -e`
- Fix similar counter increment bugs in `csw uninstall`, validation suite, and cleanup workflow
- All bash scripts now use `var=$((var + 1))` instead of `((var++))` for `set -e` compatibility

## [0.3.0] - 2025-10-15

> **Bootstrap & Workflow Consolidation**: Unified CLI + workflow automation + infrastructure refactoring

This release consolidates 10 shipped features since v0.2.2, including major bootstrap improvements, new workflow commands, bug fixes, and internal refactoring. All changes have been dogfooded and validated.

### Added

#### Bootstrap & Installation (PR #15, #10, #5)
- **`csw install` subcommand** - Replaces `install.sh` with idempotent installation
  - Installs commands to `~/.claude/commands/`
  - Creates `~/.local/bin/csw` symlink
  - Checks PATH and provides setup guidance
- **`csw init` subcommand** - Replaces `init-project.sh` with enhanced project initialization
  - Fuzzy preset matching (exact → case-insensitive → substring): "shell" → "shell-scripts"
  - Bootstrap spec generation by default for all users (teaches workflow + monorepo customization)
  - `--no-bootstrap-spec` flag to opt out
  - Interactive prompts for directory creation and reinit confirmation
  - Creates `spec/csw` symlink for project-local usage
  - Auto-updates `.gitignore` with spec log patterns
- **`csw uninstall` subcommand** - Replaces `uninstall.sh` with clean removal
  - Removes commands from `~/.claude/commands/`
  - Removes `~/.local/bin/csw` symlink
  - Preserves project `spec/` directories
- **Bootstrap validation spec template** (`templates/bootstrap-spec.md`)
  - Auto-generated during `csw init` to guide first workflow experience
  - Variable substitution: {{STACK_NAME}}, {{PRESET_NAME}}, {{INSTALL_DATE}}
  - Validates installation and teaches /plan → /build → /check → /ship cycle

#### Workflow Automation (PR #12, #11)
- **`/cleanup` command** - Post-ship workflow automation for solo developers
  - One-shot cleanup: sync main, delete merged branches, delete shipped specs
  - Creates `cleanup/merged` staging branch for seamless handoff to `/plan`
  - Aggressive and opinionated (no confirmations), trusts git history as backup
  - Optional for teams (can use manual cleanup per conventions)
- **`/plan` auto-cleanup** - Pre-flight cleanup of shipped features
  - Detects shipped branches via SHIPPED.md
  - Automatic branch deletion with safety checks
  - Prompts for each shipped feature found

#### Script Library Infrastructure (PR #6, #7, #9)
- **scripts/lib/** modules: common.sh, git.sh, validation.sh, cleanup.sh (456 lines, 29 functions)
- **bin/csw** CLI wrapper with command routing
- Three access methods work identically: `/command`, `csw command`, `./spec/csw command`

### Changed

#### Breaking Changes
- **BREAKING**: Moved `bin/csw` to project root as `csw` (PR #15)
  - Simpler bootstrap: `./csw install` vs `./bin/csw install`
  - Maximum discoverability: visible immediately after clone
  - Follows industry patterns (gradlew, mvnw, configure)
- **BREAKING**: Removed `bin/` directory (empty after csw move)
- **BREAKING**: Deleted `install.sh`, `init-project.sh`, `uninstall.sh` (replaced by csw subcommands)
- **BREAKING**: EOL PowerShell installation scripts (PR #5)
  - Removed install.ps1, init-project.ps1, uninstall.ps1
  - Windows users must use Git Bash or WSL2
  - Reduces installer codebase by 50%

#### Workflow Improvements
- **`/ship` workflow** - Single-commit SHIPPED.md update (PR #14)
  - Reordered steps: push → PR → SHIPPED.md (eliminates "PR: pending" states)
  - Updated template: short commit hash, full PR URL on separate line
  - Commit format: `docs: ship {feature} (#{pr-number})`
  - Method 4 (manual fallback) now fails fast
- **Commands simplified** - From ~100 lines to ~15 lines each (PR #9)
  - Replaced 28 embedded bash blocks with 5 clean csw calls
  - All instructional prompt text preserved
- **Paths simplified** - `spec/active/` → `spec/` throughout codebase (PR #7)
- **Documentation updates** (13 files across all PRs)
  - README.md: Installation, troubleshooting, Feature Lifecycle diagram
  - CONTRIBUTING.md: Development setup
  - TESTING.md: All test procedures
  - commands/*.md: All command references
  - templates/: stack-template.md, bootstrap-spec.md

### Fixed

- **CSW symlink resolution** (PR #13)
  - Fixed critical bug where commands failed when invoked via `~/.local/bin/csw` symlink
  - Implemented industry-standard symlink resolution (Node.js/Homebrew pattern)
  - Handles absolute/relative symlinks, multi-level chains
  - POSIX compliant (Linux, macOS, WSL, Git Bash)

### Internal

- **Script library refactoring** (PR #6, #7, #9)
  - Extracted ~400 lines from commands into standalone scripts
  - Created 6 executable scripts: spec.sh, plan.sh, build.sh, check.sh, ship.sh, cleanup.sh
  - Zero duplication: all use Phase 1 library functions
  - All scripts pass shellcheck with zero errors/warnings
- **Terminology shift**: "archive" → "cleanup" throughout codebase (PR #11)

### Migration Guide

If upgrading from v0.2.x:

1. **Reinstall globally**:
   ```bash
   cd claude-spec-workflow
   git pull
   ./csw install  # New command location and syntax
   ```

2. **Update existing projects** (optional):
   - Projects with `spec/` already initialized will continue to work
   - To update project-local wrapper: `cd your-project && csw init .` (confirm overwrite)
   - To skip bootstrap spec: use `--no-bootstrap-spec` flag

3. **Update scripts/automation**:
   - Replace `./install.sh` → `./csw install`
   - Replace `init-project.sh /path/to/project` → `csw init /path/to/project`
   - Replace `./uninstall.sh` → `csw uninstall`

4. **Windows users**: Use Git Bash or WSL2 (PowerShell no longer supported)

**No data loss**: All existing `spec/` directories and SHIPPED.md files preserved.

**See SHIPPED.md** for detailed success metrics (10 features, 100% metrics achieved on most)

_No other unreleased changes. See README.md Roadmap section for planned features._

## [0.2.2] - 2025-10-13

> **Script Library Phase 1**: Build primitive function library and CLI wrapper (internal refactoring, no user-facing changes yet)

### Added

- Script library infrastructure in `scripts/lib/` with 4 modules:
  - `common.sh` (54 lines) - Logging, path helpers, file operations, validation helpers
  - `git.sh` (123 lines) - Git operations: branches, merging, repository state
  - `validation.sh` (117 lines) - Test/lint/build runners with package manager detection
  - `archive.sh` (106 lines) - Archive operations for completed features
- CLI wrapper `bin/csw` (56 lines) with command routing
- Total: 5 files, 456 lines, 29 functions + CLI wrapper

### Technical Notes

- **Phase 1 of 3**: Primitives only (no integration)
- All scripts pass shellcheck with zero errors/warnings
- All sourcing chains tested and functional
- CLI wrapper tested: help, version, error handling, routing
- **Phase 2 (0.2.3)**: Will extract command logic
- **Phase 3 (0.3.0)**: Will wire everything and enable csw CLI for users

## [0.2.0] - 2025-10-12

> Stack configuration system rewritten. Achieves 60-93% token reduction per command invocation.

### Changed

- Replaced `spec/config.md` (YAML format) with `spec/stack.md` (Markdown with bash code blocks)
- Removed `init-stack.sh` and `init-stack.ps1` scripts - functionality consolidated into `init-project`
- Commands now require `spec/stack.md` and error with helpful message if missing
- Removed ~800 lines of inline stack conditionals from `/build`, `/check`, `/ship` commands
- Commands now load only 100-250 lines instead of 1500+ lines (60-93% token reduction)
- `init-project.sh` and `init-project.ps1` now accept `[target-path] [preset]` arguments
- Init scripts are now re-runnable with overwrite warnings and y/n confirmation prompts
- Default preset is `typescript-react-vite` if not specified
- Init scripts auto-detect their location for flexible invocation
- Converted all 5 presets from YAML to markdown with bash code blocks
- Preset format now uses section headers (## Lint, ## Test, etc.) with commands in bash blocks
- Updated README.md Stack Configuration section to reference `spec/stack.md`
- Updated troubleshooting section for new configuration system
- Updated templates/README.md validation standards section

### Added

- `templates/stack-template.md` - Reference template showing single-stack and monorepo structure
- Customization tips and examples in stack template
- Roadmap section in README.md with v0.3.0 plans
- `spec/stack.md` to project structure documentation

### Removed

- `init-stack.sh` and `init-stack.ps1` scripts
- Inline stack detection and defaults from all commands
- YAML config format and parsing logic
- `spec/config.md` references throughout documentation
