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
}
