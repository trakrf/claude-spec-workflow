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

cleanup_shipped_feature() {
    local feature="$1"
    local spec_dir
    local shipped_md

    info "Cleaning up shipped feature: $feature"

    cleanup_spec_directory "$feature"

    spec_dir=$(get_spec_dir)
    shipped_md="$spec_dir/SHIPPED.md"

    # Commit the deletion if SHIPPED.md exists
    if [[ -f "$shipped_md" ]]; then
        git add "$spec_dir"
        git commit -m "chore: cleanup $feature spec (shipped)"
        success "Feature $feature cleaned up"
    else
        warning "SHIPPED.md not found, skipping commit"
    fi

    # Auto-tag the release
    auto_tag_release
}
