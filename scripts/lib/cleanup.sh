#!/bin/bash
# Cleanup operations for shipped features

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git.sh"

cleanup_spec_directory() {
    local feature="$1"
    local spec_dir
    spec_dir="$(get_spec_dir)/$feature"

    if [[ -d "$spec_dir" ]]; then
        info "Cleaning up spec directory: $spec_dir"
        safe_delete "$spec_dir"
        success "Cleaned up $feature"
    else
        warning "Spec directory not found: $spec_dir"
    fi
}

auto_tag_release() {
    # Try VERSION file first
    if [[ -f "VERSION" ]]; then
        local version
        version=$(tr -d '[:space:]' < VERSION)
        local tag="v$version"

        if ! git tag | grep -q "^$tag$"; then
            info "Auto-tagging release: $tag"
            git tag "$tag"
            git push --tags
            success "Tagged $tag"
        else
            warning "Tag $tag already exists, skipping"
        fi
        return 0
    fi

    # Try package.json as fallback
    if [[ -f "package.json" ]] && command -v jq &>/dev/null; then
        local version
        version=$(jq -r '.version' package.json)
        if [[ "$version" != "null" ]]; then
            local tag="v$version"

            if ! git tag | grep -q "^$tag$"; then
                info "Auto-tagging release: $tag"
                git tag "$tag"
                git push --tags
                success "Tagged $tag"
            else
                warning "Tag $tag already exists, skipping"
            fi
            return 0
        fi
    fi

    warning "No VERSION or package.json found, skipping auto-tag"
    return 0
}

cleanup_merged_branches() {
    local main_branch="$1"
    local deleted_count=0

    info "🗑️  Deleting branches merged to $main_branch..."
    echo ""

    # Method 1: Delete branches merged via traditional merge commit
    local merged_branches
    merged_branches=$(git branch --merged "$main_branch" | grep -v -E '^\*|main|master|cleanup/merged' || true)

    if [[ -n "$merged_branches" ]]; then
        while IFS= read -r branch; do
            branch=$(echo "$branch" | xargs)  # trim whitespace
            if [[ -n "$branch" ]]; then
                echo "  Deleting: $branch (merged to $main_branch)"
                git branch -d "$branch" 2>/dev/null || true
                deleted_count=$((deleted_count + 1))
            fi
        done <<< "$merged_branches"
    fi

    # Method 2: Delete branches whose remote was deleted (handles squash/rebase)
    for branch in $(git branch --format='%(refname:short)'); do
        # Skip special branches
        if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "cleanup/merged" ]]; then
            continue
        fi

        # Skip if already deleted by Method 1
        if ! git show-ref --verify --quiet "refs/heads/$branch"; then
            continue
        fi

        # Get remote tracking information
        local remote_branch
        local remote_name
        remote_branch=$(git config --get "branch.$branch.merge" 2>/dev/null | sed 's|refs/heads/||')
        remote_name=$(git config --get "branch.$branch.remote" 2>/dev/null)

        if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
            # Check if remote branch still exists
            # Capture exit code BEFORE any conditional to avoid bash $? timing issue
            git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null
            ls_exit=$?

            # Handle exit codes: 0 = exists, 2 = deleted, other = error
            if [[ $ls_exit -eq 0 ]]; then
                # Remote exists, keep branch
                continue
            elif [[ $ls_exit -eq 2 ]]; then
                # Remote doesn't exist (squash/rebase merged), delete branch
                echo "  Deleting: $branch (remote deleted)"
                git branch -D "$branch" 2>/dev/null || true
                deleted_count=$((deleted_count + 1))
            else
                # Network error or auth failure (exit code 1, 128, etc.)
                warning "  Skipping: $branch (could not verify remote status)"
            fi
        fi
    done

    if [[ $deleted_count -eq 0 ]]; then
        success "✅ No merged branches to clean up"
    else
        success "✅ Deleted $deleted_count branch(es)"
    fi
    echo ""
}
