#!/bin/bash
# Shared utilities used by all scripts

# Color output functions
info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
warning() { echo -e "\033[0;33m[WARNING]\033[0m $*"; }

# Path helpers
get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

get_spec_dir() {
    echo "$(get_project_root)/spec"
}

extract_feature_from_path() {
    local path="$1"
    # Extract feature name from spec/active/feature-name/spec.md
    basename "$(dirname "$path")"
}

# File operations
ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
}

safe_delete() {
    local path="$1"
    if [[ -e "$path" ]]; then
        rm -rf "$path"
    fi
}

# Validation helpers
check_file_exists() {
    local file="$1"
    local message="${2:-File not found: $file}"
    if [[ ! -f "$file" ]]; then
        error "$message"
        return 1
    fi
}

check_command_exists() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        error "Required command not found: $cmd"
        return 1
    fi
}
