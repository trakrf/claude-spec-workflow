# Spec Workflow Configuration
# Stack: Monorepo - Go Backend + React/Vite Frontend + TimescaleDB

## Project Type
**Stack**: monorepo-go-react
**Structure**: Multi-workspace monorepo
**Workspaces**: backend (Go), frontend (React/Vite), database (migrations)

## Workspaces

### Backend (Go)
```yaml
path: backend/
package_manager: go modules
test_runner: go test
build_tool: go build

validation:
  lint:
    command: cd backend && golangci-lint run
    autofix: cd backend && golangci-lint run --fix

  typecheck:
    command: cd backend && go vet ./...

  test:
    command: cd backend && go test ./...
    watch: cd backend && gotestsum --watch
    pattern: cd backend && go test {package}
    coverage: cd backend && go test -coverprofile=coverage.out ./...

  build:
    command: cd backend && go build -o bin/app ./cmd/app
    output: backend/bin/

quality_checks:
  console_logs:
    pattern: 'fmt\.Println|fmt\.Printf'
    exclude: ['*_test.go', 'main.go']
    search_paths: ['backend/internal/', 'backend/pkg/', 'backend/cmd/']

  todos:
    pattern: 'TODO|FIXME|XXX'
    search_paths: ['backend/']

  skipped_tests:
    pattern: 't\.Skip\('
    search_paths: ['backend/']
```

### Frontend (React + Vite)
```yaml
path: frontend/
package_manager: pnpm
test_runner: vitest
build_tool: vite

validation:
  lint:
    command: cd frontend && pnpm lint
    autofix: cd frontend && pnpm lint --fix

  typecheck:
    command: cd frontend && pnpm typecheck

  test:
    command: cd frontend && pnpm test:run
    watch: cd frontend && pnpm test
    pattern: cd frontend && pnpm test {file}

  build:
    command: cd frontend && pnpm build
    output: frontend/dist/

  e2e:
    command: cd frontend && pnpm test:e2e
    exists_if: frontend/playwright.config.ts

quality_checks:
  console_logs:
    pattern: 'console\.log'
    exclude: ['*.test.*', 'catch', 'error']
    search_paths: ['frontend/src/']

  todos:
    pattern: 'TODO|FIXME|XXX'
    search_paths: ['frontend/src/']

  skipped_tests:
    pattern: 'test\.skip|it\.skip|describe\.skip'
    search_paths: ['frontend/src/']
```

### Database (TimescaleDB)
```yaml
path: database/
package_manager: none
migration_tool: golang-migrate | custom

validation:
  lint:
    command: cd database && sqlfluff lint migrations/
    autofix: cd database && sqlfluff fix migrations/

  test:
    command: cd database && ./test-migrations.sh

  migrations:
    up: cd database && migrate -path migrations -database "$DATABASE_URL" up
    down: cd database && migrate -path migrations -database "$DATABASE_URL" down 1
    create: cd database && migrate create -ext sql -dir migrations -seq {name}

quality_checks:
  todos:
    pattern: 'TODO|FIXME|XXX'
    search_paths: ['database/migrations/']
```

## Global Validation Strategy

When running `/check` at root level, validate ALL workspaces:

```yaml
check_order:
  - database  # Validate migrations first
  - backend   # Then backend
  - frontend  # Then frontend

fail_fast: false  # Continue checking all workspaces even if one fails
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional

# Workspace-aware commit scopes
scopes:
  - backend
  - frontend
  - database
  - monorepo  # for changes affecting multiple workspaces
```

## File Patterns
```yaml
backend:
  test_suffix: ['_test.go']
  source_dirs: ['backend/internal/', 'backend/pkg/', 'backend/cmd/']
  ignore_dirs: ['backend/vendor', 'backend/bin']

frontend:
  test_suffix: ['.test.ts', '.test.tsx', '.spec.ts']
  source_dirs: ['frontend/src/']
  ignore_dirs: ['frontend/node_modules', 'frontend/dist', 'frontend/coverage']

database:
  source_dirs: ['database/migrations/']
  ignore_dirs: []
```

## Usage Examples

```bash
# Full monorepo validation
/check

# Workspace-specific build
/build spec/active/auth-feature/ --workspace=backend

# Auto-detect workspace from spec
# If spec.md mentions backend/internal/auth, uses backend workspace
/build spec/active/auth-feature/
```
