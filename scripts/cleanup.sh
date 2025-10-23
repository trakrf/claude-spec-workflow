#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

# /cleanup command - Post-ship workflow automation
# Clean up after shipping and merging a feature

main() {
    info "🧹 Starting cleanup workflow..."
    echo ""

    # 1. Pre-flight Checks
    # Check if retired SHIPPED.md exists and offer to delete
    if [[ -f "spec/SHIPPED.md" ]]; then
        echo ""
        info "📋 SHIPPED.md Retirement Notice"
        echo "   SHIPPED.md has been retired from the workflow."
        echo "   Use GitHub PRs as the source of truth: gh pr list --state merged"
        echo ""
        read -p "   Delete spec/SHIPPED.md? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm spec/SHIPPED.md
            info "   ✓ Deleted spec/SHIPPED.md"
        else
            info "   ✓ Kept spec/SHIPPED.md (can delete manually anytime)"
        fi
        echo ""
    fi

    current_branch=$(get_current_branch)
    if [[ $current_branch == "cleanup/merged" ]]; then
        warning "⚠️  Warning: Already on cleanup/merged branch"
        echo "   This will re-run cleanup (idempotent)"
        echo ""
    fi

    # 2. Sync Remote State
    # Fetch all remote refs and prune deleted branches (fixes timing issues)
    info "📡 Syncing remote refs..."
    git fetch --prune origin
    echo ""

    # Sync local main branch
    main_branch=$(get_main_branch)
    info "📥 Syncing with $main_branch..."
    git checkout "$main_branch"
    git pull

    # 3. Delete Merged Branches
    cleanup_merged_branches "$main_branch"

    # 4. Create Cleanup Staging Branch
    info "🌿 Creating cleanup/merged branch..."
    git checkout -b cleanup/merged
    success "✅ Branch created"
    echo ""

    # 5. Delete Shipped Spec Directories
    info "🧹 Cleaning up shipped specs..."
    echo ""
    # Note: Uses log.md as proof of completion
    # log.md on main proves: /build ran → committed → PR merged → complete

    cleaned_count=0
    kept_count=0

    # Find all spec directories (both with and without log.md)
    all_specs=$(find spec -name "spec.md" -type f 2>/dev/null || true)
    # Find spec directories with log.md (definitive proof of completion)
    completed_specs=$(find spec -name "log.md" -type f 2>/dev/null || true)

    # Process all specs
    while IFS= read -r spec_file; do
        [[ -z "$spec_file" ]] && continue
        spec_dir=$(dirname "$spec_file")

        # Skip backlog
        if [[ "$spec_dir" =~ spec/backlog/ ]]; then
            continue
        fi

        # Check if this spec has log.md (definitive proof of completion)
        if echo "$completed_specs" | grep -q "^${spec_dir}/log.md$"; then
            echo "  ✓ Removing completed spec: $spec_dir (has log.md)"
            rm -rf "$spec_dir"
            cleaned_count=$((cleaned_count + 1))
        else
            echo "  → Preserving: $spec_dir (no log.md)"
            kept_count=$((kept_count + 1))
        fi
    done <<< "$all_specs"

    echo ""
    success "✅ Cleaned up $cleaned_count spec(s), kept $kept_count spec(s)"
    echo ""

    # 6. Commit Cleanup
    # Only commit if there are changes
    if ! git diff --quiet HEAD || ! git diff --cached --quiet; then
        info "💾 Committing cleanup..."
        git add spec/ 2>/dev/null || true
        git commit -m "chore: cleanup shipped features"
        success "✅ Cleanup committed"
    else
        info "ℹ️  No changes to commit"
    fi
    echo ""

    # 7. Success Message
    success "✅ Cleanup complete!"
    echo ""
    echo "📍 Current status:"
    echo "   - Branch: cleanup/merged"
    echo "   - Main synced: $(git log -1 --format='%h - %s' "$main_branch")"
    echo "   - Ready for next feature"
    echo ""
    info "💡 Next step: Run /plan when ready for next feature"
    echo "   The cleanup/merged branch will be renamed to feature/name"
}

main "$@"
