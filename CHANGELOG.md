# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-11

### Added
- Core specification-driven development workflow with 5 slash commands:
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
- Comprehensive README with installation and usage instructions
- MIT License

### Documentation
- Installation guides for macOS, Linux, and Windows
- Quick start guide with step-by-step workflow
- Stack configuration examples for single-stack and monorepo projects
- Workspace-aware validation for monorepo projects
- Contributing guidelines and testing documentation

## [1.1.0] - 2025-10-11

### Added

**Scope Protection & Planning Enhancements**:
- **Automatic complexity assessment** (0-10 scoring) in `/plan` command
  - Evaluates file impact, subsystem coupling, task count, dependencies, and pattern novelty
  - Mandatory split for features scoring >= 6/10
  - Auto-suggests 2-3 phases with individual complexity scores
  - YOLO override requires explicit typed confirmation
- **Mandatory clarifying questions** gate before plan generation
  - Cannot skip - ensures thorough requirement understanding
  - Structured with numbered/lettered lists for easy responses
  - Categorized by: requirements, technical approach, integration, edge cases, testing
- **Quality/confidence scoring** added to implementation plans
  - 1-10 confidence score with HIGH/MEDIUM/LOW rating
  - Confidence factors breakdown (clear requirements, similar patterns, uncertainties)
  - Estimated one-pass success probability percentage
- **Relevant Files section** in plan templates
  - Reference patterns (existing code to follow)
  - Files to create (with purposes)
  - Files to modify (with specific changes)

**Validation Gate Enforcement**:
- **Upgraded validation terminology** from "rules" to "MANDATORY GATES"
  - Added 🚫 NEVER / ✅ ALWAYS enforcement language
  - Explicit BLOCKING vs WARNINGS distinction
  - "Fix → Re-run → Repeat until pass" loop requirement
- **Full test suite gate** before any commit in `/build`
  - BLOCKING requirement - cannot skip
  - Must pass 100% of tests (no "technical debt" rationalization)
  - Build must succeed, types must be clean
- **Code cleanup gate** before final validation
  - Mandatory removal of console.log, debugger, commented code
  - Grep-based verification step
  - Dead code and unused imports cleanup

**Success Metrics & Tracking**:
- **Success Metrics section** added to spec template
  - Measurable criteria defined upfront in spec.md
  - Tracked in SHIPPED.md with actual results
  - Overall success percentage calculation
- **Conventional Commits format** in `/ship` command
  - Detailed examples for feat, fix, docs, refactor, perf, test, chore
  - Breaking change syntax (feat!, fix!)
  - Semantic versioning integration

**Documentation**:
- **Complexity Assessment & Scope Protection** section in README
  - Real-world 3,000-line PR story
  - Detailed scoring methodology
  - Phase split examples with rationale
  - "Why This Matters" explanation for quality-focused developers
- **spec/README.md** reference requirement in `/plan` and `/build`
  - Ensures workflow philosophy is consistently followed

### Changed
- Enhanced `/plan` command with multi-gate workflow:
  1. Load Philosophy (spec/README.md)
  2. Read Specification
  3. Complexity Assessment → WAIT for decision
  4. Ask Mandatory Clarifying Questions → WAIT for answers
  5. Research Codebase
  6. External Research (if needed)
  7. Create Implementation Plan
  8. Git Setup
- Enhanced `/build` command steps:
  - Added spec/README.md loading
  - Added code cleanup step (step 5)
  - Enhanced full test suite requirements (step 6)
  - Renumbered summary report (step 7)
- Enhanced `/ship` SHIPPED.md format with success metrics section
- Upgraded all commands with consistent validation gates terminology

### Documentation
- Added comprehensive complexity assessment examples in README
- Added conventional commit examples in ship.md
- Updated all command documentation with new gate terminology
- Added troubleshooting sections for validation and workflow issues

## [Unreleased]

### Planned
- Additional stack presets (Rust, Ruby, Java)
- Package manager distribution (Homebrew, npm)
- Integration tests for workflow validation
- Video walkthrough tutorials
- Interactive complexity calculator tool
