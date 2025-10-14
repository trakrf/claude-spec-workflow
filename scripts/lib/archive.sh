#!/bin/bash
# Archive operations for completed features

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git.sh"

create_shipped_entry_template() {
    local feature="$1"
    local pr_number="$2"
    local pr_url="$3"
    local spec_dir
    spec_dir="$(get_spec_dir)/$feature"

    ensure_directory "$spec_dir"

    cat > "$spec_dir/.shipped-entry" << EOF
## $feature
- **Date**: $(date +%Y-%m-%d)
- **PR**: [#$pr_number]($pr_url)
- **Commit**: MERGE_COMMIT_PLACEHOLDER
- **Branch**: feature/$feature
EOF

    echo "$pr_url" > "$spec_dir/.pr-url"

    success "Created shipping metadata for $feature"
}

update_shipped_md() {
    local feature="$1"
    local spec_dir
    local shipped_entry
    local shipped_md
    local merge_commit
    local entry

    spec_dir="$(get_spec_dir)/$feature"
    shipped_entry="$spec_dir/.shipped-entry"
    shipped_md="$(get_spec_dir)/SHIPPED.md"

    if [[ ! -f "$shipped_entry" ]]; then
        error "No .shipped-entry found for $feature"
        error "Run /ship first to create PR and metadata"
        return 1
    fi

    # Get the actual merge commit hash
    merge_commit=$(get_merge_commit_hash)

    # Replace placeholder with actual commit
    entry=$(sed "s/MERGE_COMMIT_PLACEHOLDER/$merge_commit/" "$shipped_entry")

    # Prepend to SHIPPED.md (reverse chronological)
    if [[ -f "$shipped_md" ]]; then
        # Insert after header (line 3)
        {
            head -n 2 "$shipped_md"
            echo ""
            echo "$entry"
            echo ""
            tail -n +3 "$shipped_md"
        } > "$shipped_md.tmp"
        mv "$shipped_md.tmp" "$shipped_md"
    else
        # Create new SHIPPED.md
        cat > "$shipped_md" << EOF
# Shipped Features

$entry
EOF
    fi

    success "Updated SHIPPED.md with $feature"
}

delete_spec_directory() {
    local feature="$1"
    local spec_dir
    spec_dir="$(get_spec_dir)/$feature"

    if [[ -d "$spec_dir" ]]; then
        info "Archiving spec directory: $spec_dir"
        safe_delete "$spec_dir"
        success "Archived $feature"
    else
        warning "Spec directory not found: $spec_dir"
    fi
}

archive_feature() {
    local feature="$1"
    local spec_dir

    info "Archiving feature: $feature"

    update_shipped_md "$feature"
    delete_spec_directory "$feature"

    spec_dir=$(get_spec_dir)
    git add "$spec_dir/SHIPPED.md"
    git commit -m "chore: archive $feature specs"

    success "Feature $feature archived"
}
