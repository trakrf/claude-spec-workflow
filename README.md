# Claude Spec Workflow

Specification-driven development commands for Claude Code by [TrakRF](https://trakrf.id)

Created by Mike Stankavich ([@mikestankavich](https://github.com/mikestankavich))

## What is this?

A specification-driven development workflow for Claude Code that helps you ship production-ready features with confidence.

### Origin Story

This project builds on excellent work from two pioneers in AI-assisted development:

**Cole Medin's [Context Engineering](https://github.com/coleam00/context-engineering-intro)** taught us the power of comprehensive context and validation loops. His methodology showed how structured context dramatically improves AI output quality and prevents the "big bang integration" failures we've all experienced.

**Ryan Carson's [3-File PRD System](https://creatoreconomy.so/p/full-tutorial-a-proven-3-file-system-to-vibe-code-production-apps-ryan)** ([repo](https://github.com/snarktank/ai-dev-tasks)) demonstrated the value of progress tracking and clarifying questions. His approach to breaking down work and maintaining visible state throughout development inspired our specification lifecycle.

### Our Contribution

We loved what both Cole and Ryan created, and found ourselves naturally combining techniques from both approaches. This project synthesizes those ideas into a **single, opinionated workflow** that:

- **Starts with clarity** (spec-first approach)
- **Plans with questions** (mandatory clarification gates)
- **Builds with validation** (continuous testing, not cleanup)
- **Ships with confidence** (comprehensive pre-release checks)

The key difference: where their approaches offer flexibility and exploration, we provide a **Rails-style opinionated process**. We believe the best creativity happens within constraints, and that AI-assisted development benefits from clear guard rails and validation gates.

Think of it as "the best of both worlds, with training wheels" - structured enough to prevent common pitfalls, flexible enough to adapt to your stack.

## Features

- 🎯 **Conversation to Spec** - Extract formal specifications from exploratory chats
- 🤔 **Interactive Planning** - Get clarifying questions before implementation
- ✅ **Continuous Validation** - Test and fix as you build, not after
- 📊 **Pre-release Checks** - Comprehensive validation before creating PRs
- 🚀 **Clean Shipping** - Automated cleanup and git workflow
- 🔧 **Stack Agnostic** - Works with TypeScript, Python, Go, and more via presets

## Prerequisites

**All Platforms:**
- Git installed
- Bash shell

**Platform-Specific Setup:**
- **macOS/Linux**: Native bash support ✓
- **Windows**: Requires Git Bash or WSL2
  - [Install Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
  - [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)

**Why bash?** This is a bash-based workflow system. Claude Code executes all commands through bash, and the workflow depends on bash tools (git, grep, find, etc.) for every operation from installation to validation to shipping. Whether your project uses TypeScript, Python, Go, or Rust - you're still running those commands through bash. Git Bash or WSL2 provides this bash environment.

**GitHub Authentication (for automatic PR creation):**

The `/ship` command can create pull requests automatically if you authenticate with GitHub using any of these methods:

1. **GitHub CLI** (Recommended):
   ```bash
   gh auth login
   ```

2. **Personal Access Token**:
   ```bash
   export GH_TOKEN=your_token_here
   # Get token: https://github.com/settings/tokens
   # Scopes needed: repo, workflow
   ```

3. **gh config**: If gh CLI is installed, `/ship` will use stored credentials automatically

**Without authentication**: `/ship` will provide manual PR creation instructions.

## Installation

```bash
# Clone the repository
git clone https://github.com/trakrf/claude-spec-workflow
cd claude-spec-workflow

# Install commands globally
./install.sh

# Initialize a project with default preset (TypeScript + React + Vite)
./init-project.sh /path/to/your/project

# Or initialize with a specific preset
./init-project.sh /path/to/your/project python-fastapi
```

**Windows users**: Run these commands in Git Bash or WSL2 terminal.

## Quick Start

1. **Create a specification**
   ```bash
   mkdir -p spec/active/my-feature
   cp spec/template.md spec/active/my-feature/spec.md
   # Edit spec.md with your requirements
   ```

   See `examples/profile-feature/spec.md` for a complete example.

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
   Prepares for pull request with validation and git workflow.

## Stack Configuration

The workflow adapts to your project's tech stack through `spec/stack.md`, which is created automatically when you initialize a project.

### Available Presets

**Single-Stack:**
- `typescript-react-vite` - React + TypeScript + Vite + npm (default)
- `nextjs-app-router` - Next.js App Router + TypeScript
- `python-fastapi` - Python + FastAPI + pytest
- `go-standard` - Go with standard library or frameworks

**Monorepo:**
- `monorepo-go-react` - Go backend + React/Vite frontend + TimescaleDB

### Using a Preset

Presets are automatically applied during project initialization:

```bash
# Default preset (typescript-react-vite)
./init-project.sh /path/to/your/project

# Specific preset
./init-project.sh /path/to/your/project python-fastapi
```

### Changing Your Stack

To change your stack configuration, you have two options:

1. **Edit spec/stack.md directly** - Customize validation commands to match your setup
2. **Re-run init-project with a different preset** - Overwrites with new preset (prompts for confirmation)

```bash
# From your project directory, switch to a different preset
/path/to/claude-spec-workflow/init-project.sh . go-standard
```

### Custom Stack Configuration

If your stack doesn't match any preset, use `templates/stack-template.md` as a guide:

```bash
# Copy the template to see the format
cp templates/stack-template.md spec/stack.md
```

Then edit `spec/stack.md` with your validation commands:

```markdown
# Stack: My Custom Stack

> **Package Manager**: your-package-manager
> **Test Runner**: your-test-runner

## Lint
\```bash
your-lint-command --fix
\```

## Typecheck
\```bash
your-typecheck-command
\```

## Test
\```bash
your-test-command
\```

## Build
\```bash
your-build-command
\```
```

The commands `/build`, `/check`, and `/ship` automatically read and use these commands.

**Built a great stack definition?** Share it with the community! If you've created a stack configuration for a framework or toolchain not yet in our presets, consider contributing it back. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting new presets.

### Monorepo Support

For monorepos with multiple tech stacks (like Go backend + React frontend):

1. **Initialize with monorepo preset:**
   ```bash
   # From your project directory
   /path/to/claude-spec-workflow/init-project.sh . monorepo-go-react
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
   /check backend              # Validates only backend workspace (faster feedback)
   ```

The system uses workspace-specific validation commands from `spec/stack.md`:
- Backend changes use commands from `## Workspace: backend` section
- Frontend changes use commands from `## Workspace: frontend` section
- Database changes use commands from `## Workspace: database` section

## Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/spec` | Convert conversation to specification | After exploring an idea interactively |
| `/plan` | Generate implementation plan | When you have a clear spec |
| `/build` | Execute the plan | After plan is approved |
| `/check` | Validate everything | Before creating PR |
| `/ship` | Complete and PR | When ready to merge |

## Feature Lifecycle

CSW supports a complete feature development cycle:

([spec] | `<spec>`) → plan → build → [check] → ship → `<merge>` → repeat

**Legend**:
- [brackets] - Optional CSW command
- `<angle brackets>` - Manual/external action
- (A | B) - Choose either approach

```mermaid
flowchart LR
    Start([Start Feature]) --> Spec{Create Spec}
    Spec -->|/spec command| AutoSpec[spec/active/feature/]
    Spec -->|Write manually| ManualSpec[spec/feature/spec.md]
    AutoSpec --> Plan
    ManualSpec --> Plan
    Plan[/plan] --> Build[build]
    Build --> Check{/check?}
    Check -->|Optional| CheckRun[Validate]
    Check -->|Skip| Ship
    CheckRun --> Ship
    Ship[/ship] --> Merge(<merge PR>)
    Merge --> Next([Next Feature])
    Next --> Spec
```

**The cycle**:
1. **([spec] | `<spec>`)** - Create feature spec (tool-assisted or manual)
2. **plan** - Generate implementation plan
3. **build** - Implement the feature
4. **[check]** - Validate (optional: tests, lint, types, build)
5. **ship** - Create PR (logs to SHIPPED.md)
6. **`<merge>`** - Merge the PR (manual)
7. **repeat** - Start next feature

## Workflow vs History

CSW focuses on *current* work, not completed work.

- **spec/** - Workspace for active/planned features (transient)
- **SHIPPED.md** - Record of completed work (durable)
- **Git** - Full history and context

Complete a feature? `/ship` logs it to SHIPPED.md. After merging, the spec/ scaffolding can be cleaned up manually or left in place - it's already preserved in git history.

## Workflow Philosophy

1. **Context is King** - Provide comprehensive context for better AI execution
2. **Clarify Before Coding** - Interactive planning prevents false starts
3. **Validate Continuously** - Fix issues immediately, not in a big cleanup
4. **Ship Clean** - Comprehensive checks ensure professional results

## Complexity Assessment & Scope Protection

The `/plan` command includes automatic scope analysis to prevent scope creep and protect you from common pitfalls.

### The Problem We've All Experienced

**The Pattern**:
- **Hour 1**: "This is going great!"
- **Hour 3**: "Wait, why is this test failing?"
- **Hour 5**: "Which of the 15 changes broke this?"
- **Hour 6**: "I should have split this up..."

**Real story from the trenches**: One of our developers reviewed a 3,000-line PR diff until their eyes bled, spending hours trying to understand all the changes across multiple subsystems. They finally YOLO'd the merge. It worked, but the risk was enormous and the review was nearly impossible.

### The Solution: Automatic Complexity Scoring

The `/plan` command automatically calculates a **complexity score (0-10)** based on:

- **File Impact**: How many files you're creating/modifying
- **Subsystem Coupling**: How many different systems you're touching
- **Task Estimate**: Total number of implementation steps
- **New Dependencies**: External packages you're adding
- **Pattern Novelty**: Whether you're using existing patterns or creating new ones

**Threshold-based protection**:
- **0-3 (LOW)**: ✅ Green light, well-scoped feature
- **4-5 (MEDIUM-LOW)**: ⚠️ Suggested split, but manageable as-is
- **6-10 (MEDIUM-HIGH to CRITICAL)**: 🛑 Mandatory split or explicit YOLO override required

### How It Works

When complexity >= 6, `/plan` will:

1. **Show detailed complexity breakdown** with specific factors
2. **Optionally generate phase breakdown** if you want to see the split
3. **Explain why splitting reduces risk** (better validation, reviewable PRs, incremental value)
4. **Require simple y/n confirmation** to proceed with full scope

**Example output**:

```
🛑 COMPLEXITY: 7/10 (HIGH)

**Complexity Factors**:
📁 File Impact: Creating 5 files, modifying 4 files (9 total)
🔗 Subsystems: Touching 3 subsystems (UI, API, Database)
🔢 Task Estimate: ~10 subtasks
📦 Dependencies: 0 new packages
🆕 Pattern Novelty: Following existing patterns

**Why This Is Risky**:
- Context overload: 10 subtasks is manageable but pushing limits
- Validation isolation: Hard to isolate which of 10 steps caused failure
- PR review difficulty: 9 files is unreviewable in single PR
- Architectural pivot cost: If approach is wrong, significant time wasted
- Token limit risks: Large context may hit AI limits

**You know this feeling**:
- Hour 1: "This is going great!"
- Hour 3: "Wait, why is this test failing?"
- Hour 5: "Which of the 10 changes broke this?"
- Hour 6: "I should have split this up..."

**RECOMMENDATION: SPLIT INTO PHASES**

### Phase 1: Database Schema & Core Models (Complexity: 2/10) ✅
**Start here** - Foundation that other phases depend on
- Create database migrations
- Add TypeScript types
- Write database access layer tests
**Estimated**: 3 subtasks
**Can ship**: No - infrastructure only, but validates approach

### Phase 2: API Endpoints (Complexity: 3/10) ⚠️
**Do second** - Business logic implementation
- Implement CRUD endpoints
- Add request validation
- Write API integration tests
**Estimated**: 4 subtasks
**Can ship**: Yes - provides functional backend

### Phase 3: UI Components (Complexity: 3/10) ⚠️
**Do last** - User-facing features
- Create form components
- Add data fetching hooks
- Implement E2E tests
**Estimated**: 6 subtasks
**Can ship**: Yes - complete feature

**Why Splitting Works**:
✅ Each phase has meaningful validation gates (< 8 subtasks = debuggable)
✅ Ship Phase 1, get feedback, adjust Phase 2 accordingly
✅ PRs are reviewable size (Phase 1 = ~3 files vs 9 files)
✅ If Phase 1 reveals issues, haven't wasted time on Phase 2/3
✅ Incremental value delivery

**Your Decision** (required):
1. **Phase 1 only** - Generate full spec for Phase 1 (recommended)
2. **Full roadmap** - Generate Phase 1 spec + Phase 2/3 outlines
3. ⚠️ **YOLO OVERRIDE** - Proceed with full scope (not recommended)

Please choose: 1, 2, or 3
```

**If you choose YOLO override**:

The system will ask for simple y/n confirmation to proceed with full scope. This makes scope decisions **deliberate** rather than default, without adding unnecessary friction.

### Why This Matters

**For developers who self-select for quality**:

If you're using a specification-driven methodology like this, you probably care deeply about code quality. The complexity assessment helps you maintain that standard by:

- **Preventing context overload** that leads to bugs
- **Ensuring reviewable PRs** that actually get reviewed
- **Enabling incremental validation** so failures are easy to debug
- **Protecting your time** from architectural pivots late in development

**Bottom line**: The best time to split a feature is during planning, not at 2 AM when tests are failing and you can't remember which of 15 changes broke things.

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
    ├── stack.md          # Validation commands for your tech stack
    ├── template.md       # Spec template for new features
    ├── README.md         # Workflow documentation
    └── SHIPPED.md        # Log of completed features
```

## Uninstalling

```bash
./uninstall.sh
```

This removes the Claude commands but leaves your project spec directories intact.

## Troubleshooting

### Installation Issues

**Commands not showing up in Claude Code**
- Verify installation path:
  - macOS/Linux: `~/.claude/commands/`
  - Windows: `%APPDATA%\claude\commands\`
- Restart Claude Code after installation
- Check file permissions: `ls -la ~/.claude/commands/`

**Permission denied errors**
- Make scripts executable: `chmod +x *.sh`
- Check directory permissions: `mkdir -p ~/.claude/commands`

### Command Execution Issues

**`/plan` or `/build` can't find spec directory**
- Ensure you're in the project root
- Check `spec/` directory exists: `ls -la spec/`
- Run `/path/to/claude-spec-workflow/init-project.sh .` if spec directory is missing

**Commands run out of order**
- Recommended flow: `/spec` → `/plan` → `/build` → `/check` → `/ship`
- If missing plan.md, run `/plan` first
- If missing spec.md, create it or use `/spec`

**Validation commands fail**
- Missing `spec/stack.md`: Commands will error and ask you to run init-project.sh
- Check validation commands work: `npm run lint`, `npm test`, etc.
- Run `/path/to/claude-spec-workflow/init-project.sh . <preset-name>` to create or update stack.md
- Verify commands in spec/stack.md match your project setup

### Git Issues

**Not on a feature branch**
- `/plan` creates a branch automatically
- Or create manually: `git checkout -b feature/your-feature`
- Never run `/ship` from main/master branch

**Uncommitted changes block `/ship`**
- Commit or stash changes first
- `/ship` requires clean working directory
- Check status: `git status`

### Monorepo Issues

**Workspace not detected**
- Add `Workspace: backend` to spec.md metadata
- Or detect from file paths in plan.md
- Verify workspace exists in `spec/stack.md` as `## Workspace: backend`

**Wrong commands run for workspace**
- Check `spec/stack.md` has correct workspace sections
- Verify workspace-specific validation commands
- Test commands manually in workspace directory

### Configuration Issues

**Stack config not being read**
- Ensure file is named exactly `spec/stack.md`
- Check file is in spec/ directory (not inside spec/active/)
- Verify markdown format with bash code blocks

**Commands in stack.md don't work**
- Test commands manually first
- Check for typos in command paths
- Verify package.json scripts exist (for npm/pnpm/yarn projects)
- Commands should be in bash code blocks under section headers (## Lint, ## Test, etc.)

### Workflow Issues

**Spec too vague, plan is generic**
- Add more specific technical requirements
- Include code examples and patterns
- Reference similar features in your codebase
- Define clear validation criteria

**Build fails validation repeatedly**
- Check linter and test output carefully
- Fix issues incrementally, don't skip validation
- Review log.md for patterns in failures
- Consider if spec needs clarification

**`/check` finds unexpected issues**
- Review code quality patterns in config
- Some warnings are informational only
- Fix critical issues, decide on warnings
- Update config if checks don't fit your workflow

### Cross-Platform Issues

**Windows setup**
- Use Git Bash or WSL2 terminal for all commands
- Use forward slashes in paths: `/plan spec/active/feature/spec.md`
- If using Git Bash: Right-click in directory → "Git Bash Here"

**Symlink issues on Unix**
- Scripts now handle symlinks correctly (v1.0.0+)
- If issues persist, use absolute paths

### PR Creation Issues

**`/ship` doesn't create PR automatically**

The `/ship` command tries multiple authentication methods in order:
1. GitHub CLI (if authenticated)
2. GH_TOKEN environment variable
3. Token from gh config

If all fail, you'll get manual PR creation instructions.

**To fix**:
```bash
# Option 1: Use GitHub CLI
gh auth login

# Option 2: Set GH_TOKEN
export GH_TOKEN=your_token_here
# Add to ~/.bashrc or ~/.zshrc for persistence

# Then re-run
/ship spec/active/your-feature/
```

**After creating PR manually**:
Update SHIPPED.md:
```bash
# Find "PR: pending" in spec/SHIPPED.md and replace with actual URL
sed -i 's|PR: pending|PR: https://github.com/owner/repo/pull/123|' spec/SHIPPED.md
git add spec/SHIPPED.md
git commit -m "docs: update SHIPPED.md with PR URL"
git push
```

### Getting Help

Still stuck?
1. Check existing issues: https://github.com/trakrf/claude-spec-workflow/issues
2. Review TESTING.md for validation procedures
3. See CONTRIBUTING.md for reporting bugs
4. Include error messages and system details in reports

## Roadmap

### Upcoming Features

**v0.3.0**:
- Rewrite README.md and other docs as needed into my own voice
- Additional stack presets (Rust, Ruby on Rails, Bun, etc.)
- Enhanced error messages and validation feedback
- Performance profiling and optimization
- Investigate @ includes to DRY up slash commands (reduce repetition across command files)
- Project maturity config to control documentation verbosity (dogfooding=minimal docs, production=migration guides)

**Future**:
- Package manager distribution (Homebrew, npm)
- Integration tests for workflow validation
- Video walkthrough tutorials
- Community preset library (users share configs via PRs)
- Improved monorepo workspace detection
- Interactive preset creation wizard
- Multi-preset composition for monorepos (specify multiple presets to compose into single stack.md)

## Credits

This specification-driven development system synthesizes ideas from:

- **Cole Medin** - [Context Engineering](https://github.com/coleam00/context-engineering-intro) methodology, validation loops, and comprehensive context approach
- **Ryan Carson** - [3-File PRD System](https://creatoreconomy.so/p/full-tutorial-a-proven-3-file-system-to-vibe-code-production-apps-ryan) ([repo](https://github.com/snarktank/ai-dev-tasks)) for progress tracking and clarifying questions pattern

Special thanks to both for sharing their methodologies publicly.

## License

MIT License - See LICENSE file

## Contributing

Issues and PRs welcome! This is an evolving methodology based on real-world usage.

## About TrakRF

[TrakRF](https://trakrf.id) provides RFID asset tracking solutions for manufacturing and logistics. We use AI-assisted development to accelerate our platform development while maintaining high code quality.