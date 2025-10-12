# Feature: End-of-Life PowerShell Installation Scripts

## Origin
This specification emerged from dogfooding the workflow on claude-spec-workflow itself. During development of the shell-scripts preset and cross-platform compatibility analysis, we identified that maintaining dual bash/PowerShell installers creates unnecessary maintenance burden for a fundamentally bash-centric tool.

## Outcome
Remove PowerShell installation scripts (`.ps1` files) and standardize on bash-only installation with clear Windows documentation. This simplifies the codebase, reduces maintenance overhead, and aligns with the tool's fundamental architecture.

## User Story
As a **maintainer of claude-spec-workflow**
I want **a single bash-based installation system**
So that **I can iterate faster without duplicating every change across bash and PowerShell implementations**

As a **Windows developer using the tool**
I want **clear documentation on bash requirements**
So that **I understand how to set up my environment properly**

## Context

### Discovery
While dogfooding the workflow, we observed:
- Every installer enhancement required updating both bash and PowerShell versions
- Recent changes (path fixes, preset handling) meant **33% of development time** was spent porting bash → PowerShell
- The tool itself executes bash commands through Claude Code regardless of installer language
- PowerShell installers solve the wrong problem: they let users install a tool they can't actually use without bash

### Current State
- 3 bash scripts: `install.sh`, `init-project.sh`, `uninstall.sh`
- 3 PowerShell scripts: `install.ps1`, `init-project.ps1`, `uninstall.ps1`
- All `spec/stack.md` validation commands are bash (even for TypeScript, Python, Go projects)
- Maintenance overhead: every change requires dual implementation

### Desired State
- Bash-only installation: `install.sh`, `init-project.sh`, `uninstall.sh`
- Comprehensive Windows setup documentation
- Clear explanation of WHY bash is required (not arbitrary)
- Single source of truth for installer logic

## Technical Requirements

### 1. Remove PowerShell Scripts
- Delete `install.ps1`
- Delete `init-project.ps1`
- Delete `uninstall.ps1`
- Update version control to track removal

### 2. Update README.md
Add prominent Windows section:

**Prerequisites**
- macOS/Linux: Native bash support ✓
- Windows: Git Bash (recommended) or WSL2
  - [Install Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
  - [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)

**Installation instructions should assume bash**
```bash
git clone https://github.com/trakrf/claude-spec-workflow.git
cd claude-spec-workflow
./install.sh
```

**Add Windows troubleshooting section**:
- Git Bash setup (right-click → "Git Bash Here")
- WSL2 setup for power users
- Why bash is required (Claude Code executes bash commands)

### 3. Update CONTRIBUTING.md
- Development requires bash environment
- Windows contributors should use Git Bash or WSL
- Testing procedures assume bash

### 4. Update TESTING.md
- Remove PowerShell testing instructions
- Document bash-only validation
- Update test commands to reflect single implementation

### 5. Migration Path
No migration needed - Windows userbase is hypothetical and non-existent.

## Rationale

### Why This Makes Sense

**1. The tool requires bash anyway**
- All validation commands in `spec/stack.md` are bash
- Claude Code executes commands through bash
- PowerShell installers are just a gateway to a bash-required tool

**2. Target audience already has bash**
- Professional developers use Git (includes Git Bash on Windows)
- WSL2 is Microsoft's recommended approach for development
- Anyone doing serious development has bash access

**3. Ecosystem precedent**
- Homebrew, nvm, rbenv: bash-only
- Most Docker/k8s examples: bash
- Most CI/CD scripts: bash
- Dev tool installers are typically bash-first

**4. Maintenance burden is real**
- 33% of recent development was bash → PowerShell porting
- Risk of divergence (bugs in one not the other)
- Testing matrix complexity
- Future features double the work

**5. Trade-off is favorable**
- **Cost**: <1% of potential users excluded (Windows-only, no Git Bash, won't install)
- **Benefit**: 33% reduction in maintenance overhead, faster iteration, single source of truth

### What We're NOT Doing
- ❌ Making bash optional (it's fundamental to the tool)
- ❌ Supporting cmd.exe (too limited for dev workflows)
- ❌ Creating PowerShell versions of validation commands (defeats the purpose)

## Validation Criteria

### Functional
- [ ] All bash scripts pass shellcheck validation
- [ ] Installation works on macOS
- [ ] Installation works on Linux
- [ ] Installation works on Windows Git Bash
- [ ] Installation works on Windows WSL2
- [ ] Commands install to correct location (`~/.claude/commands`)

### Documentation
- [ ] README clearly states bash requirement
- [ ] Windows setup instructions are prominent
- [ ] Git Bash installation link is provided
- [ ] WSL2 is mentioned as alternative
- [ ] Explanation of WHY bash is required is clear
- [ ] Troubleshooting section covers common Windows issues

### User Experience
- [ ] Windows developers aren't confused
- [ ] Installation process is straightforward
- [ ] Error messages guide users to solutions

## Success Metrics

### Quantitative
- Reduce installer codebase by 50% (3 files → 6 files)
- Eliminate dual-implementation testing
- Future installer changes require single implementation

### Qualitative
- Windows users understand bash requirement before installing
- No increase in "doesn't work on Windows" issues
- Contribution friction reduced (no need to port changes)

## Edge Cases & Considerations

### Corporate Windows Environments
- Some enterprises block WSL/Git Bash installation
- **Response**: These users likely can't use dev tools anyway (no Git access)
- Document alternative: portable Git Bash

### Pure PowerShell Users
- Some Windows devs prefer PowerShell ecosystem
- **Response**: This tool targets cross-platform workflows, bash is standard
- Alternative tools may better suit PowerShell-exclusive workflows

### Existing Users
- No existing PowerShell users to migrate (Windows userbase is hypothetical)

## Conversation References

**Key Insight:**
> "The tool itself runs bash commands. If a user can't run bash, the tool doesn't work regardless of installer language. So PowerShell installers are solving the wrong problem."

**Decision Rationale:**
> "Don't be afraid to require bash. Our target users (professional developers) either already have it, can install it in 2 minutes, or should have it anyway for modern development."

**Maintenance Reality:**
> "Every change requires updating BOTH [bash and PowerShell]. That's a 33% maintenance tax we just paid while fixing paths and adding preset features."

**Trade-off Analysis:**
> "How many users are we losing? Professional developers on Windows who don't have Git Bash, can't install it, won't use WSL, but still want spec-driven development. This is <1% of potential users. Trade-off: 33% reduction in maintenance for <1% exclusion. That's a good trade."

## Implementation Notes

**Order of operations:**
1. Update documentation FIRST (README, CONTRIBUTING, TESTING)
2. Remove PowerShell files
3. Test installation on all platforms
4. Commit with clear explanation in commit message

**Communication:**
- Commit message should explain rationale
- PR description should link to this spec
- Emphasize this is about sustainability, not platform preference

## Open Questions

None. This decision has been thoroughly analyzed through the ULTRATHINK process.
