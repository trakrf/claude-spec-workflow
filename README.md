# Claude Spec Workflow

Specification-driven development commands for Claude Code by [TrakRF](https://trakrf.id)

Created by Mike Stankavich ([@mikestankavich](https://github.com/mikestankavich))

## What is this?

A streamlined workflow for turning conversations and ideas into production-ready code using Claude Code. It combines the best practices from context engineering and progressive validation to enable high-quality, AI-assisted development.

## Features

- 🎯 **Conversation to Spec** - Extract formal specifications from exploratory chats
- 🤔 **Interactive Planning** - Get clarifying questions before implementation
- ✅ **Continuous Validation** - Test and fix as you build, not after
- 📊 **Pre-release Checks** - Comprehensive validation before creating PRs
- 🚀 **Clean Shipping** - Automated archival and git workflow
- 🔧 **Stack Agnostic** - Works with TypeScript, Python, Go, and more via presets

## Installation

### macOS / Linux

```bash
# Clone the repository
git clone https://github.com/trakrf/claude-spec-workflow
cd claude-spec-workflow

# Install commands globally
./install.sh

# Initialize a project (optional)
./init-project.sh /path/to/your/project
```

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/trakrf/claude-spec-workflow
cd claude-spec-workflow

# Install commands globally
.\install.ps1

# Initialize a project (optional)
.\init-project.ps1 C:\path\to\your\project
```

## Quick Start

1. **Create a specification**
   ```bash
   mkdir -p spec/active/my-feature
   cp spec/template.md spec/active/my-feature/spec.md
   # Edit spec.md with your requirements
   ```

   See `examples/auth-feature/spec.md` for a complete example.

2. **Generate implementation plan**
   ```
   /plan spec/active/my-feature/spec.md
   ```
   Claude will ask clarifying questions to ensure a solid plan.

3. **Build with validation**
   ```
   /build spec/active/my-feature/
   ```
   Implementation happens with continuous testing and progress tracking.

4. **Check readiness**
   ```
   /check
   ```
   Comprehensive validation ensures your code is PR-ready.

5. **Ship it**
   ```
   /ship spec/active/my-feature/
   ```
   Archives the spec and prepares for pull request.

## Stack Configuration

The workflow adapts to your project's tech stack through `spec/config.md`.

### Quick Setup with Presets

**macOS / Linux:**
```bash
cd your-project
~/path/to/claude-spec-workflow/init-stack.sh typescript-react-vite
```

**Windows (PowerShell):**
```powershell
cd your-project
C:\path\to\claude-spec-workflow\init-stack.ps1 typescript-react-vite
```

### Available Presets

**Single-Stack:**
- `typescript-react-vite` - React + TypeScript + Vite + pnpm
- `nextjs-app-router` - Next.js App Router + TypeScript
- `python-fastapi` - Python + FastAPI + pytest
- `go-standard` - Go with standard library or frameworks

**Monorepo:**
- `monorepo-go-react` - Go backend + React/Vite frontend + TimescaleDB

### Custom Configuration

Create your own stack config:
```bash
./init-stack.sh custom  # Creates spec/config.md template
```

Then edit `spec/config.md` with your project's commands:
```yaml
lint:
  command: your-lint-command
  autofix: your-lint-fix-command

test:
  command: your-test-command

build:
  command: your-build-command
```

The commands `/build`, `/check`, and `/ship` automatically use these settings.

### Monorepo Support

For monorepos with multiple tech stacks (like Go backend + React frontend):

1. **Initialize with monorepo preset:**
   ```bash
   ./init-stack.sh monorepo-go-react
   ```

2. **Add workspace metadata to specs:**
   ```markdown
   ## Metadata
   **Workspace**: backend
   **Type**: feature
   ```

3. **Commands auto-detect workspace:**
   ```bash
   /build spec/active/auth/   # Detects backend workspace from spec
   /check                      # Validates all workspaces (database → backend → frontend)
   ```

The system uses workspace-specific validation commands automatically:
- Backend changes use `go test`, `golangci-lint`
- Frontend changes use `pnpm test`, `pnpm lint`
- Database changes validate migrations

## Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/spec` | Convert conversation to specification | After exploring an idea interactively |
| `/plan` | Generate implementation plan | When you have a clear spec |
| `/build` | Execute the plan | After plan is approved |
| `/check` | Validate everything | Before creating PR |
| `/ship` | Complete and archive | When ready to merge |

## Workflow Philosophy

1. **Context is King** - Provide comprehensive context for better AI execution
2. **Clarify Before Coding** - Interactive planning prevents false starts
3. **Validate Continuously** - Fix issues immediately, not in a big cleanup
4. **Ship Clean** - Comprehensive checks ensure professional results

## Project Structure

After initialization, your project will have:

```
your-project/
└── spec/
    ├── active/           # Current features being developed
    │   └── feature-name/
    │       ├── spec.md   # Requirements
    │       ├── plan.md   # Implementation plan (generated)
    │       └── log.md    # Progress tracking (generated)
    ├── template.md       # Spec template for new features
    ├── README.md         # Workflow documentation
    └── SHIPPED.md        # Archive of completed features
```

## Uninstalling

**macOS / Linux:**
```bash
./uninstall.sh
```

**Windows (PowerShell):**
```powershell
.\uninstall.ps1
```

This removes the Claude commands but leaves your project spec directories intact.

## Credits

This specification-driven development system synthesizes ideas from:

- **Cole Medin** - [Context Engineering](https://github.com/coleam00/context-engineering-intro) methodology, validation loops, and comprehensive context approach
- **Ryan Carson** - [3-File PRD System](https://creatoreconomy.so/p/full-tutorial-a-proven-3-file-system-to-vibe-code-production-apps-ryan) for progress tracking and clarifying questions pattern

Special thanks to both for sharing their methodologies publicly.

## License

MIT License - See LICENSE file

## Contributing

Issues and PRs welcome! This is an evolving methodology based on real-world usage.

## About TrakRF

[TrakRF](https://trakrf.id) provides RFID asset tracking solutions for manufacturing and logistics. We use AI-assisted development to accelerate our platform development while maintaining high code quality.