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
    if [[ ! -f "spec/SHIPPED.md" ]]; then
        warning "⚠️  Warning: spec/SHIPPED.md not found"
        echo "   Spec cleanup will be skipped (no reference for what's shipped)"
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
    if [[ -f "spec/SHIPPED.md" ]]; then
        info "🧹 Cleaning up shipped specs..."
        echo ""

        cleaned_count=0
        kept_count=0

        # Find all spec.md files
        while IFS= read -r spec_file; do
            spec_dir=$(dirname "$spec_file")
            feature_name=$(basename "$spec_dir")

            # Skip if feature name matches patterns we should never delete
            if [[ "$feature_name" == "backlog" ]] || [[ "$spec_dir" =~ spec/backlog/ ]]; then
                continue
            fi

            # Check if feature is in SHIPPED.md
            if grep -q "$feature_name" spec/SHIPPED.md 2>/dev/null; then
                echo "  Cleaning up: $spec_dir (found '$feature_name' in SHIPPED.md)"
                rm -rf "$spec_dir"
                cleaned_count=$((cleaned_count + 1))
            else
                echo "  Keeping: $spec_dir (not in SHIPPED.md)"
                kept_count=$((kept_count + 1))
            fi
        done < <(find spec -name "spec.md" -type f 2>/dev/null || true)

        echo ""
        success "✅ Cleaned up $cleaned_count spec(s), kept $kept_count spec(s)"
    else
        info "ℹ️  No SHIPPED.md found - skipping spec cleanup"
    fi
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
