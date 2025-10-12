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

### Planned
- Additional stack presets (Rust, Ruby, Java)
- Package manager distribution (Homebrew, npm)
- Integration tests for workflow validation
- Video walkthrough tutorials
- Interactive complexity calculator tool
