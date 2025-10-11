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

## [Unreleased]

### Planned
- Additional stack presets (Rust, Ruby, Java)
- Package manager distribution (Homebrew, npm)
- Integration tests for workflow validation
- Video walkthrough tutorials
