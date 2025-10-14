#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"

# Parse arguments
FEATURE="$1"

if [[ -z "$FEATURE" ]]; then
    error "Usage: spec.sh <feature-name>"
    exit 1
fi

# Create directory under spec/ (not spec/active/)
SPEC_DIR="$(get_spec_dir)/$FEATURE"
ensure_directory "$SPEC_DIR"

# Copy template
TEMPLATE="$(get_project_root)/spec/template.md"
check_file_exists "$TEMPLATE" "Template not found"
cp "$TEMPLATE" "$SPEC_DIR/spec.md"

success "Created spec at $SPEC_DIR/spec.md"
