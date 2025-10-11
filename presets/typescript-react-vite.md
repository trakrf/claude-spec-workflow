# Spec Workflow Configuration
# Stack: TypeScript + React + Vite

## Project Type
**Stack**: typescript-react-vite
**Package Manager**: pnpm
**Test Runner**: vitest
**Build Tool**: vite

## Validation Commands
```yaml
lint:
  command: pnpm lint
  autofix: pnpm lint --fix

typecheck:
  command: pnpm typecheck

test:
  command: pnpm test:run
  watch: pnpm test
  pattern: pnpm test {file}

build:
  command: pnpm build
  output: dist/

e2e:
  command: pnpm test:e2e
  exists_if: playwright.config.ts
```

## Code Quality Checks
```yaml
console_logs:
  pattern: 'console\.log'
  exclude: ['*.test.*', 'catch', 'error']

todos:
  pattern: 'TODO|FIXME|XXX'

skipped_tests:
  pattern: 'test\.skip|it\.skip|describe\.skip'
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional  # conventional|simple
pr_template: .github/pull_request_template.md
```

## File Patterns
```yaml
test_suffix: ['.test.ts', '.test.tsx', '.spec.ts']
source_dirs: ['src/', 'lib/']
ignore_dirs: ['node_modules', 'dist', 'coverage']
```
