# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-11

> **Pre-release for dogfooding**: This version represents the initial implementation of the claude-spec-workflow system. It will be validated through real-world use on production projects (trakrf/platform) for 1-2 weeks before the v1.0.0 public release.

### Added

**Core Workflow System**:
- Specification-driven development workflow with 5 slash commands:
  - `/spec` - Convert conversations to formal specifications
  - `/plan` - Generate implementation plans with clarifying questions
  - `/build` - Execute plans with continuous validation
  - `/check` - Comprehensive pre-release validation
  - `/ship` - Complete features and prepare pull requests
- Cross-platform installation scripts (Unix .sh + Windows .ps1)
- Project initialization system (`init-project` and `init-stack`)
- Stack configuration presets:
  - TypeScript + React + Vite
  - Next.js App Router
  - Python + FastAPI
  - Go (standard library + frameworks)
  - Monorepo (Go backend + React frontend + TimescaleDB)
- Template system for specs, configs, and documentation
- Example specification: User Profile Editing feature (frontend-focused, accessible)

**Scope Protection & Quality Gates**:
- **Automatic complexity assessment** (0-10 scoring) in `/plan` command
  - Evaluates file impact, subsystem coupling, task count, dependencies, and pattern novelty
  - Recommends split for features scoring 6-10/10
  - Optional phase breakdown generation
  - Simple y/n override confirmation
- **Mandatory clarifying questions** gate before plan generation
  - Structured with numbered/lettered lists for easy responses
  - Categorized by: requirements, technical approach, integration, edge cases, testing
- **Quality/confidence scoring** in implementation plans
  - 1-10 confidence score with confidence factors breakdown
  - Estimated one-pass success probability percentage
- **ULTRATHINK strategic thinking checkpoints** in all 5 commands
  - Deep analysis before key decisions
  - Pattern-based approach synthesis
  - Risk assessment and mitigation planning

**Validation Gate Enforcement**:
- **Mandatory validation gates** (BLOCKING requirements):
  - Lint must be clean
  - Types must be correct
  - Tests must pass
  - Build must succeed
  - "Fix → Re-run → Repeat until pass" loop requirement
- **Full test suite gate** before any commit in `/build`
  - BLOCKING requirement - cannot skip
  - Must pass 100% of tests
- **Code cleanup gate** before final validation
  - Mandatory removal of console.log, debugger, commented code

**Stack-Agnostic Support**:
- Auto-detection and defaults for Node/TypeScript, Rust, Go, Python
- Stack-aware validation commands and patterns
- Workspace-aware validation for monorepo projects

**Success Metrics & Tracking**:
- Success Metrics section in spec template
- Tracked in SHIPPED.md with actual results
- Overall success percentage calculation
- Conventional Commits format with semantic versioning

**Role-Based Personas**:
- Senior Product Engineer for `/spec` (requirements clarity)
- Senior Software Architect for `/plan` (design decisions)
- Senior Software Engineer for `/build` (clean implementation)
- Senior Test Engineer for `/check` (quality assessment)
- Tech Lead for `/ship` (production readiness)

**Spec Lifecycle Management**:
- Automatic archival of shipped features during `/plan`
- Simple y/n archive prompts
- SHIPPED.md tracking with date, commit, and success metrics

### Documentation
- Comprehensive README with installation and usage instructions
- Installation guides for macOS, Linux, and Windows
- Quick start guide with step-by-step workflow
- Stack configuration examples for single-stack and monorepo projects
- Complexity assessment methodology and examples
- Conventional commit format examples
- Troubleshooting sections for validation and workflow issues
- MIT License

## [Unreleased]

### Planned for Future Releases
- Package manager distribution (Homebrew, npm)
- Integration tests for workflow validation
- Video walkthrough tutorials
- Community preset library (users share configs via PRs)

## [0.2.0] - 2025-10-12

> **Token Optimization Release**: This version dramatically reduces token usage by extracting stack-specific conditionals into a required configuration file. Achieves 60-93% token reduction per command invocation.

### Changed

**Stack Configuration System**:
- **BREAKING**: Replaced `spec/config.md` (YAML format) with `spec/stack.md` (Markdown with bash code blocks)
- **BREAKING**: Removed ~800 lines of inline stack conditionals from commands (`/build`, `/check`, `/ship`)
- **BREAKING**: Removed `init-stack.sh` and `init-stack.ps1` - functionality consolidated into `init-project`
- Commands now error with helpful message if `spec/stack.md` is missing
- Token reduction achieved:
  - `/build`: ~240 lines removed (60% reduction)
  - `/check`: ~200 lines removed (93% reduction in stack-specific code)
  - `/ship`: ~150 lines removed (70% reduction in stack-specific sections)

**Init System**:
- `init-project.sh` and `init-project.ps1` now accept `[target-path] [preset]` arguments
- Made init-project scripts re-runnable with overwrite warnings
- Default preset is `typescript-react-vite` if not specified
- Simple y/n confirmation prompts with git revert instructions
- Automatic preset validation with helpful error listing available presets
- Script auto-detects its location for flexible invocation

**Preset Format**:
- Converted all 5 presets from YAML to markdown with bash code blocks:
  - `typescript-react-vite.md`
  - `nextjs-app-router.md`
  - `python-fastapi.md`
  - `go-standard.md`
  - `monorepo-go-react.md`
- Simpler, more readable format with section headers (## Lint, ## Test, etc.)
- Commands in bash code blocks instead of YAML config
- Metadata in markdown blockquotes instead of structured fields

### Added

**Templates**:
- `templates/stack-template.md` - Reference template showing single-stack and monorepo structure
- Shows how to customize validation commands for any tech stack
- Includes customization tips and examples

**Documentation**:
- Updated README.md Stack Configuration section to reference `spec/stack.md`
- Updated troubleshooting section for new configuration system
- Added `spec/stack.md` to project structure documentation
- Updated templates/README.md validation standards section

### Removed

- `init-stack.sh` and `init-stack.ps1` (functionality consolidated into init-project)
- Inline stack detection and defaults from all commands
- YAML config format and parsing logic
- `spec/config.md` references throughout documentation

### Technical Impact

**For Users**:
- Must run `init-project.sh` (or re-run if upgrading) to create `spec/stack.md`
- Commands will error with clear instructions if `spec/stack.md` is missing
- No migration path needed (no public users yet for v0.1.0)
- Simpler mental model: one initialization script instead of two

**For Claude**:
- Commands load only 100-250 lines instead of 1500+ lines
- Faster command execution with less context pollution
- Clearer command structure focused on workflow logic
- Stack-specific logic extracted to single source of truth

**Why This Matters**:
- Reduces token usage by 60-93% per command invocation
- Eliminates unused stack conditionals from context
- Makes commands more maintainable and extensible
- Prepares system for dogfooding and real-world validation
