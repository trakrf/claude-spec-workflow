#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validation.sh"

info "Running pre-release validation suite"

# Run comprehensive validation
if run_validation_suite; then
    success "All validation gates passed"
    exit 0
else
    error "Validation gates failed"
    exit 1
fi
