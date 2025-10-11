# Spec Workflow Configuration
# Stack: Next.js (App Router)

## Project Type
**Stack**: nextjs-app-router
**Package Manager**: pnpm
**Test Runner**: jest / vitest
**Build Tool**: next build

## Validation Commands
```yaml
lint:
  command: pnpm lint
  autofix: pnpm lint --fix

typecheck:
  command: pnpm typecheck

test:
  command: pnpm test
  watch: pnpm test:watch
  pattern: pnpm test {file}

build:
  command: pnpm build
  output: .next/

e2e:
  command: pnpm test:e2e
  exists_if: playwright.config.ts
```

## Code Quality Checks
```yaml
console_logs:
  pattern: 'console\.log'
  exclude: ['*.test.*', 'catch', 'error', 'middleware.ts']

todos:
  pattern: 'TODO|FIXME|XXX'

skipped_tests:
  pattern: 'test\.skip|it\.skip|describe\.skip'
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional
pr_template: .github/pull_request_template.md
```

## File Patterns
```yaml
test_suffix: ['.test.ts', '.test.tsx', '.spec.ts']
source_dirs: ['app/', 'src/', 'components/', 'lib/']
ignore_dirs: ['node_modules', '.next', 'out', 'coverage']
```
