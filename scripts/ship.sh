#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validation.sh"

# Find all plan.md files
SPEC_DIR="$(get_spec_dir)"
mapfile -t ALL_PLANS < <(find "$SPEC_DIR" -name "plan.md" 2>/dev/null || true)

# Output each plan path for Claude to select
for plan in "${ALL_PLANS[@]}"; do
    echo "$plan"
done

# Exit with count (Claude handles selection)
exit "${#ALL_PLANS[@]}"
