# Stack: Shell Scripts (Bash/POSIX)

> **Linter**: shellcheck
> **Formatter**: shfmt
> **Test Runner**: bats-core (optional)

## Lint
```bash
# Check all shell scripts for issues
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# PowerShell scripts (if applicable)
if command -v pwsh &> /dev/null; then
  find . -name "*.ps1" -not -path "*/\.*" -exec pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path {} -Recurse" \;
fi
```

## Test
```bash
# If using bats (Bash Automated Testing System)
if command -v bats &> /dev/null && [ -d "test" ]; then
  bats test/
else
  echo "ℹ️  No tests configured. Install bats: https://github.com/bats-core/bats-core"
fi
```

## Format
```bash
# Format shell scripts with shfmt
if command -v shfmt &> /dev/null; then
  find . -name "*.sh" -not -path "*/\.*" -exec shfmt -w -i 2 -ci {} +
else
  echo "ℹ️  shfmt not installed. Install: https://github.com/mvdan/sh"
fi
```

## Validate
```bash
# Syntax check all bash scripts
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
echo "✅ All bash scripts: syntax valid"
```
