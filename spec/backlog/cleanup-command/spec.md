# Spec: `/cleanup` Command

## Problem

After shipping and merging a feature, developers need to:
1. Delete the merged feature branch
2. Clean up the completed spec directory
3. Get latest main
4. Be ready to start the next feature

Currently this requires manual git commands. For solo devs in a fast-paced workflow, this friction slows the cycle.

## Solution

Create `/cleanup` command that:
- Does ALL cleanup in one shot (branches + specs + main sync)
- Creates magic `cleanup/merged` branch as staging area
- Enables seamless handoff to `/plan` for next feature

## Design: Two Personas, One Tool

### Solo Dev (Fast, Opinionated)
**Wants:** Zero-friction, automatic, streamlined
**Flow:** `/ship` → `<merge>` → `/cleanup` → `/plan`

### Team Dev (Flexible, Cautious)
**Wants:** Control, team conventions, no surprises
**Flow:** `/ship` → `<merge>` → (manual cleanup) → `/plan`

## Implementation

### `/cleanup` Command

**What it does:**
```bash
# 1. Sync with main
git checkout main
git pull

# 2. Delete merged feature branches (aggressive!)
git branch --merged | grep 'feature/' | xargs git branch -d

# 3. Create cleanup staging branch
git checkout -b cleanup/merged

# 4. Delete shipped spec directories
find spec -name "spec.md" -type f | while read spec_file; do
  spec_dir=$(dirname "$spec_file")
  feature_name=$(basename "$spec_dir")

  # Simple grep match against SHIPPED.md
  if grep -q "$feature_name" SHIPPED.md; then
    rm -rf "$spec_dir"
    echo "Cleaned up $spec_dir"
  fi
done

# 5. Commit cleanup
git add spec/
git commit -m "chore: cleanup shipped features"

echo "✅ Cleanup complete. On cleanup/merged branch."
echo "Run /plan when ready for next feature."
```

**Characteristics:**
- **Aggressive** - Deletes without confirmation (power tool)
- **Opt-in** - Never run automatically
- **Idempotent** - Safe to run multiple times
- **Local-only** - Doesn't push cleanup/merged

### `/plan` Integration

**Honors magic branch:**
```bash
current=$(git branch --show-current)

if [[ $current == "cleanup/merged" ]]; then
  # Solo dev fast path - specs already cleaned
  git branch -m "feature/$new_feature"
  # Generate plan...

else
  # Standard path - just branch from main
  git checkout main
  git pull
  git checkout -b "feature/$new_feature"
  # NO spec cleanup - /plan doesn't clean
  # Generate plan...
fi
```

## Key Decisions

### Separation of Concerns
- **`/cleanup`** = cleanup (branches + specs + sync)
- **`/plan`** = planning (branch creation + plan generation)

No overlap. Clean boundaries.

### Magic Branch Convention
- `cleanup/merged` signals "I shipped, cleaned up, ready for next"
- `/plan` detects and renames to `feature/new`
- Not required - just opt-in convenience

### Spec Matching Logic
**Simple for v1:**
```bash
grep -q "$feature_name" SHIPPED.md
```

**Known edge cases (acceptable for now):**
- Same feature name reused later (false positive deletion)
- Partial string matches (unlikely with feature names)
- No commit hash validation (simpler, good enough)

**Philosophy:** Ship simple, iterate on real problems from dogfooding.

### No Auto-Cleanup in `/plan`
`/plan` does NOT clean up shipped specs automatically.

**Rationale:**
1. Team devs may want specs to linger
2. Cleanup timing is a preference, not requirement
3. Specs are scaffolding - harmless to leave
4. SHIPPED.md + git history = source of truth

Solo devs who want aggressive cleanup: use `/cleanup`.

## Lifecycle Integration

### Fast Cycle (Solo Dev)
```
/plan → /build → /ship → <merge> → /cleanup → /plan → ...
                                    ^^^^^^^^
                              One-shot transition
```

### Deliberate Cycle (Team)
```
/plan → /build → /ship → <merge> → (manual cleanup) → /plan → ...
                                    ^^^^^^^^^^^^^^^^
                              Team's own conventions
```

## Success Metrics

- ✅ Solo dev can ship → cleanup → plan in < 30 seconds
- ✅ Team dev can skip `/cleanup` entirely (no forced behavior)
- ✅ Zero breaking changes to existing workflow
- ✅ `cleanup/merged` branch is obvious in `git branch` output
- ✅ Dogfooding reveals real edge cases (not imagined ones)

## Out of Scope

**Not doing (for now):**
- Commit hash matching for specs
- Configuration modes (solo vs team)
- Confirmation prompts
- Push cleanup/merged branch
- Auto-run from `/ship`
- Partial cleanup (select which specs)

**Why:** Ship simple, iterate on real feedback.

## Validation

**Manual test:**
```bash
# Setup: Feature shipped and merged
git checkout feature/auth
# ... already merged to main via PR

# Test /cleanup
/cleanup

# Verify:
# - On cleanup/merged branch
# - feature/auth deleted (was merged)
# - spec/auth/ deleted (in SHIPPED.md)
# - main is latest

# Test /plan
/plan spec/dashboard/spec.md

# Verify:
# - On feature/dashboard branch
# - cleanup/merged renamed
# - plan.md generated
```

## Questions to Answer During Build

1. What if SHIPPED.md doesn't exist? (Skip spec cleanup)
2. What if no branches merged? (Skip branch deletion, continue)
3. What if already on cleanup/merged? (Error or re-run cleanup?)
4. What if spec matching is too aggressive? (Add safeguards in iteration)

## Related Work

- Complements existing `scripts/cleanup.sh` (pre-flight for `/plan`)
- Different scope: `/cleanup` is user-facing command, `scripts/cleanup.sh` is automation
- May eventually consolidate or deprecate `scripts/cleanup.sh`

## Implementation Notes

**Create:**
- `commands/cleanup.md` - Slash command definition
- Update `README.md` - Replace "archive" → "cleanup" terminology
- Update `commands/plan.md` - Document cleanup/merged detection

**Update:**
- Feature lifecycle diagram (replace `/archive` with `/cleanup`)
- Commands table (add `/cleanup`)

**Future:**
- Consider config: `CSW_CLEANUP_MODE=solo|team`
- Consider commit hash matching for robustness
- Consider interactive mode for teams
