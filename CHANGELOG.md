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

_No unreleased changes yet. See README.md Roadmap section for planned features._

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
