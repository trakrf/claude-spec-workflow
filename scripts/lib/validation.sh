#!/bin/bash
# Test and validation runners

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect project type and run appropriate commands
detect_package_manager() {
    if [[ -f "package.json" ]]; then
        if [[ -f "package-lock.json" ]]; then
            echo "npm"
        elif [[ -f "yarn.lock" ]]; then
            echo "yarn"
        elif [[ -f "pnpm-lock.yaml" ]]; then
            echo "pnpm"
        else
            echo "npm"  # default
        fi
    fi
}

run_tests() {
    local pm
    pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        info "Running tests with $pm"
        $pm test
        return $?
    fi

    warning "No test runner detected"
    return 0
}

run_linter() {
    local pm
    pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        # Check if lint script exists
        if grep -q '"lint"' package.json 2>/dev/null; then
            info "Running linter with $pm"
            $pm run lint
            return $?
        fi
    fi

    warning "No linter configured"
    return 0
}

run_type_checker() {
    local pm
    pm=$(detect_package_manager)

    if [[ -f "tsconfig.json" ]]; then
        info "Running TypeScript type checker"
        if [[ -n "$pm" ]]; then
            $pm run tsc --noEmit 2>/dev/null || tsc --noEmit
            return $?
        fi
    fi

    return 0
}

run_build() {
    local pm
    pm=$(detect_package_manager)

    if [[ -n "$pm" ]]; then
        if grep -q '"build"' package.json 2>/dev/null; then
            info "Running build with $pm"
            $pm run build
            return $?
        fi
    fi

    warning "No build script configured"
    return 0
}

# Full validation suite
run_validation_suite() {
    local failed=0

    echo ""
    info "=== Running Validation Suite ==="
    echo ""

    if ! run_tests; then
        error "Tests failed"
        ((failed++))
    fi

    if ! run_linter; then
        error "Linter failed"
        ((failed++))
    fi

    if ! run_type_checker; then
        error "Type checking failed"
        ((failed++))
    fi

    if ! run_build; then
        error "Build failed"
        ((failed++))
    fi

    echo ""
    if [[ $failed -eq 0 ]]; then
        success "=== All Validation Checks Passed ==="
        return 0
    else
        error "=== $failed Validation Check(s) Failed ==="
        return 1
    fi
}
