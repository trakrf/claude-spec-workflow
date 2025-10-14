#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

# Main cleanup workflow
# Called by /plan command to clean up shipped features

main() {
    local current_branch
    local main_branch
    local feature

    current_branch=$(get_current_branch)
    main_branch=$(get_main_branch)

    # Pre-flight: Check if current branch is shipped
    if [[ -f "spec/SHIPPED.md" ]] && grep -q "Branch: $current_branch" spec/SHIPPED.md; then
        info "🧹 Current branch $current_branch has been shipped"

        # Validate branch is merged
        if git branch --merged "$main_branch" | grep -q " $current_branch$"; then
            info "📥 Pulling latest $main_branch..."
            git checkout "$main_branch"
            git pull origin "$main_branch"

            info "🗑️  Deleting merged branch..."
            git branch -d "$current_branch"

            # Delete spec directory
            feature=$(echo "$current_branch" | sed 's/feature\///')
            if [[ -d "spec/$feature" ]]; then
                cleanup_spec_directory "$feature"
                git add "spec/$feature"
                git commit -m "chore: delete $feature spec (shipped)"
            fi
        else
            warning "Branch $current_branch not fully merged to $main_branch"
            error "Please merge branch before running /plan"
            exit 1
        fi
    fi

    # Scan for other shipped features
    for dir in spec/*/; do
        # Skip backlog and special directories
        [[ "$dir" =~ spec/(backlog|fix-plan-autoarchive)/ ]] && continue
        [[ ! -f "$dir/spec.md" ]] && continue

        feature=$(basename "$dir")

        # Check if in SHIPPED.md
        if [[ -f "spec/SHIPPED.md" ]] && grep -q "## .*$feature" spec/SHIPPED.md; then
            info "📦 Found shipped feature: $feature"
            read -p "Delete spec/$feature/? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cleanup_spec_directory "$feature"
                git add "spec/$feature"
                git commit -m "chore: delete $feature spec (shipped)"
            fi
        fi
    done

    success "✅ Workspace cleanup complete"
}

main "$@"
