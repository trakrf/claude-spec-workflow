# Feature: Bootstrap Spec Auto-Generation

## Origin
Discovered while dogfooding CSW setup in other projects. When initializing CSW in a new repo, there's no clean way to validate installation or commit the CSW infrastructure using CSW's own workflow. This creates a chicken-and-egg problem and misses an opportunity for immediate hands-on learning.

## Outcome
When `init-project.sh` completes, it automatically creates a bootstrap validation spec that users can immediately plan, build, and ship. This validates the installation, commits CSW infrastructure cleanly, and provides hands-on experience with the workflow before building real features.

## User Story
As a **developer setting up CSW in a new project**
I want **a pre-created bootstrap spec**
So that **I can validate installation and commit CSW infrastructure via CSW itself**

As a **team lead onboarding developers to CSW**
I want **new users to experience the workflow immediately**
So that **they build confidence before tackling real features**

## Context

### Current State
When running `init-project.sh`:
1. Creates `spec/` directory structure
2. Copies templates (README.md, template.md, stack.md)
3. Updates .gitignore
4. Prints success message
5. **User is left wondering**: "Did this work? What do I do now?"

### Problem
- No validation that setup actually worked
- CSW infrastructure gets committed ad-hoc (or not at all)
- Users don't experience the workflow until building their first feature
- No natural "first PR" that demonstrates CSW in action
- Team members have no example shipped feature to reference

### Desired State
After `init-project.sh` completes:
1. Bootstrap spec automatically created at `spec/active/csw-bootstrap/spec.md`
2. Pre-populated with project-specific information (stack detected from preset)
3. Clear next steps guide user through first /plan → /build → /ship cycle
4. Results in clean PR that adds CSW infrastructure
5. First SHIPPED.md entry demonstrates workflow works

## Technical Requirements

### 1. Create Bootstrap Spec Template
Add `templates/bootstrap-spec.md` to CSW repository:

```markdown
# Feature: Claude Spec Workflow Setup

## Metadata
**Type**: infrastructure

## Outcome
Validate CSW installation and commit workflow infrastructure to repository via CSW's own workflow.

## User Story
As a developer
I want CSW infrastructure validated and committed
So that the team can use specification-driven development

## Context
**Installed**: Claude Spec Workflow from https://github.com/trakrf/claude-spec-workflow
**Stack**: {{STACK_NAME}}
**Preset**: {{PRESET_NAME}}

## Technical Requirements
- `spec/` directory structure is complete and correct
- `stack.md` validation commands work for our stack
- Slash commands (/plan, /build, /check, /ship) are accessible
- Templates are ready for use

## Validation Criteria
- [ ] spec/README.md exists and describes the workflow
- [ ] spec/template.md exists and is ready for copying
- [ ] spec/stack.md contains working validation commands for {{STACK_NAME}}
- [ ] spec/active/ directory exists
- [ ] Slash commands installed in Claude Code
- [ ] At least one validation command executes successfully

## Success Metrics
- [ ] Directory structure matches spec/README.md documentation
- [ ] All validation commands in stack.md execute without errors
- [ ] Template can be copied to create new specs
- [ ] This bootstrap spec itself gets shipped to SHIPPED.md

## References
- CSW Source: https://github.com/trakrf/claude-spec-workflow
- Stack Preset: {{PRESET_NAME}}
- Installation Date: {{DATE}}
```

### 2. Update init-project.sh
After successful template copy, generate bootstrap spec:

**Add to init-project.sh (before final success message)**:
```bash
# Generate bootstrap validation spec
echo "Creating bootstrap validation spec..."
BOOTSTRAP_DIR="$PROJECT_ROOT/spec/active/csw-bootstrap"
mkdir -p "$BOOTSTRAP_DIR"

# Get current date
CURRENT_DATE=$(date +%Y-%m-%d)

# Determine stack name from preset
case "$PRESET" in
  "typescript-react-vite") STACK_NAME="TypeScript + React + Vite" ;;
  "nextjs-app-router") STACK_NAME="Next.js App Router + TypeScript" ;;
  "python-fastapi") STACK_NAME="Python + FastAPI" ;;
  "go-standard") STACK_NAME="Go" ;;
  "monorepo-go-react") STACK_NAME="Go + React Monorepo" ;;
  "shell-scripts") STACK_NAME="Shell Scripts (Bash)" ;;
  *) STACK_NAME="$PRESET" ;;
esac

# Copy and populate template
cp "$CSW_ROOT/templates/bootstrap-spec.md" "$BOOTSTRAP_DIR/spec.md"
sed -i "s/{{STACK_NAME}}/$STACK_NAME/g" "$BOOTSTRAP_DIR/spec.md"
sed -i "s/{{PRESET_NAME}}/$PRESET/g" "$BOOTSTRAP_DIR/spec.md"
sed -i "s/{{DATE}}/$CURRENT_DATE/g" "$BOOTSTRAP_DIR/spec.md"
```

### 3. Update Success Message
Replace final echo with:

```bash
echo ""
echo "✅ Claude Spec Workflow Setup Complete!"
echo ""
echo "📂 Directory structure:"
echo "   spec/"
echo "   ├── README.md          # Workflow documentation"
echo "   ├── template.md        # Spec template"
echo "   ├── stack.md           # $STACK_NAME validation commands"
echo "   └── active/"
echo "       └── csw-bootstrap/ # Bootstrap validation spec"
echo ""
echo "🚀 Next: Validate installation by shipping the bootstrap spec"
echo ""
echo "   1. Generate plan:"
echo "      /plan spec/active/csw-bootstrap/spec.md"
echo ""
echo "   2. Execute plan:"
echo "      /build spec/active/csw-bootstrap/"
echo ""
echo "   3. Validate quality:"
echo "      /check"
echo ""
echo "   4. Ship it:"
echo "      /ship spec/active/csw-bootstrap/"
echo ""
echo "This will:"
echo "  • Validate CSW installation works correctly"
echo "  • Commit CSW infrastructure using CSW itself (meta!)"
echo "  • Create your first SHIPPED.md entry"
echo "  • Give you hands-on experience with the workflow"
echo ""
echo "📖 Learn more: spec/README.md"
echo ""
```

### 4. Update init-project.ps1
Mirror the bash implementation in PowerShell (if we still had it... we don't! 😄)
**Note**: This is now moot since we just removed PowerShell support.

### 5. Update Documentation

**README.md additions** (in Quick Start section):
```markdown
## Quick Start

After installation, you'll find a bootstrap spec created at `spec/active/csw-bootstrap/`:

1. **Validate your setup** by shipping the bootstrap spec:
   ```
   /plan spec/active/csw-bootstrap/spec.md
   /build spec/active/csw-bootstrap/
   /check
   /ship spec/active/csw-bootstrap/
   ```

   This validates CSW works and commits the infrastructure cleanly.

2. **Create your first feature** using the template:
   ```bash
   mkdir -p spec/active/my-feature
   cp spec/template.md spec/active/my-feature/spec.md
   # Edit spec.md with your requirements
   ```

   Then run through the same workflow.
```

## Rationale

### Why This Is Valuable

**1. Immediate Validation**
- Proves installation worked before user invests time
- Catches setup issues early (missing dependencies, permission problems)
- Validates slash commands are accessible in Claude Code

**2. Learning by Doing**
- Users experience full workflow immediately
- Builds confidence before tackling real features
- Provides concrete example of spec → plan → build → ship
- Creates muscle memory for the process

**3. Clean Git History**
- CSW infrastructure gets committed properly via PR
- Not just dumped into repo with "add csw" commit message
- First SHIPPED.md entry documents the setup
- Demonstrates CSW in action to team

**4. Dogfooding (Meta!)**
- CSW installs itself using its own workflow
- Proves the system works by using itself
- Creates natural recursion (CSW validates CSW)

**5. Team Onboarding**
- New developers see complete example in git history
- First PR demonstrates workflow end-to-end
- SHIPPED.md shows successful execution
- Natural reference point for questions

**6. Reduced Friction**
- No "what now?" moment after installation
- Clear next steps printed immediately
- Guided first experience
- Quick win builds momentum

### Ecosystem Precedent
- **Rails**: `rails new` creates app skeleton, first action is running `rails server` to validate
- **Create React App**: Creates app, prints "run `npm start` to see it working"
- **Cargo**: `cargo new` creates project, first action is `cargo build` to validate
- **Git**: `git init` creates repo, natural first action is `git add` + `git commit`

Pattern: **Great tools guide you to first successful action immediately**

## Validation Criteria

### Functional
- [ ] `templates/bootstrap-spec.md` created and contains proper template
- [ ] `init-project.sh` generates bootstrap spec after setup
- [ ] Bootstrap spec is populated with detected stack info
- [ ] Bootstrap spec is populated with preset name
- [ ] Bootstrap spec is populated with current date
- [ ] Success message includes clear next steps
- [ ] Bootstrap spec can be planned successfully
- [ ] Bootstrap spec can be built successfully
- [ ] Bootstrap spec can be shipped successfully

### Documentation
- [ ] README.md Quick Start mentions bootstrap spec
- [ ] README.md shows example of shipping bootstrap
- [ ] Success message from init-project is clear and actionable
- [ ] Template placeholders ({{STACK_NAME}}, etc.) are documented

### User Experience
- [ ] Users immediately know what to do next
- [ ] First /plan → /ship cycle succeeds without issues
- [ ] Bootstrap PR is clean and professional
- [ ] SHIPPED.md first entry is meaningful

## Success Metrics

### Quantitative
- 100% of new CSW installations have bootstrap spec
- Bootstrap spec successfully shipped in >90% of installations
- First SHIPPED.md entry created automatically

### Qualitative
- Users report confidence after shipping bootstrap
- Team onboarding smoother (measurable via feedback)
- Git history shows clean CSW introduction
- No "what now?" confusion reported in issues

## Edge Cases & Considerations

### User Skips Bootstrap Spec
**Scenario**: User ignores bootstrap spec and creates their own feature first
**Response**: Bootstrap spec remains in `spec/active/` and will be prompted for archival when they run `/plan` for next feature. No harm done.

### Bootstrap Spec Fails to Build
**Scenario**: Validation commands in stack.md don't work
**Response**: This is actually **good** - catches setup issues before user invests time in real features. The bootstrap build failure guides them to fix stack configuration.

### User Already Committed CSW Files
**Scenario**: User committed CSW infrastructure before running bootstrap
**Response**: Bootstrap spec still valuable - validates setup and teaches workflow. They can still ship it as "validate CSW installation" PR.

### Monorepo Workspace Detection
**Scenario**: Monorepo preset used, no workspace in bootstrap spec
**Response**: Bootstrap spec is infrastructure-level, doesn't need workspace. Leave workspace field empty or set to "N/A".

## Implementation Notes

**Order of Operations**:
1. Create `templates/bootstrap-spec.md` template
2. Update `init-project.sh` to generate bootstrap spec
3. Test on fresh project initialization
4. Update README.md with Quick Start guidance
5. Test full workflow: init → plan → build → ship bootstrap

**Testing Checklist**:
- [ ] Fresh init with typescript-react-vite preset
- [ ] Fresh init with python-fastapi preset
- [ ] Fresh init with go-standard preset
- [ ] Fresh init with monorepo-go-react preset
- [ ] Fresh init with shell-scripts preset
- [ ] Verify placeholders replaced correctly
- [ ] Ship bootstrap spec successfully for each preset

**Upstream Contribution**:
This feature should be contributed back to https://github.com/trakrf/claude-spec-workflow as it benefits all users:
- Improves onboarding experience
- Reduces support burden (fewer "what now?" questions)
- Demonstrates workflow immediately
- Creates consistent first-use experience

## Open Questions

None - this is ready to implement!
