#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"

# Find all spec.md files - no filtering, Claude does matching
SPEC_DIR="$(get_spec_dir)"
mapfile -t ALL_SPECS < <(find "$SPEC_DIR" -name "spec.md" 2>/dev/null || true)

# Output each spec path
for spec in "${ALL_SPECS[@]}"; do
    echo "$spec"
done

# Exit with count for easy detection
exit "${#ALL_SPECS[@]}"
