# Spec Workflow Configuration

> **Note**: This is a template with placeholders shown in `[brackets]`. Replace them with your actual commands.
> The `/build`, `/check`, and `/ship` commands read this file to determine how to validate your project.

## Project Type
**Stack**: [your-stack-name]
**Package Manager**: [npm|pnpm|yarn|pip|cargo|go|etc]
**Test Runner**: [jest|vitest|pytest|go-test|etc]
**Build Tool**: [vite|webpack|next|go-build|cargo|etc]

## Validation Commands
```yaml
lint:
  command: [your lint command]
  autofix: [your lint fix command]

typecheck:
  command: [your type check command]

test:
  command: [your test command]
  watch: [optional: watch mode command]
  pattern: [optional: pattern for specific file]

build:
  command: [your build command]
  output: [build output directory]

# Optional: E2E tests
e2e:
  command: [your e2e command]
  exists_if: [file that indicates e2e exists]
```

## Code Quality Checks
```yaml
console_logs:
  pattern: '[regex for console/debug statements]'
  exclude: ['test files', 'error handlers']

todos:
  pattern: 'TODO|FIXME|XXX'

skipped_tests:
  pattern: '[regex for skipped tests]'
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional  # conventional|simple
pr_template: .github/pull_request_template.md
```

## File Patterns
```yaml
test_suffix: ['.test.ext', '.spec.ext']
source_dirs: ['src/', 'lib/']
ignore_dirs: ['node_modules', 'build', 'dist']
```
