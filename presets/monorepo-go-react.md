# Stack: Monorepo (Go Backend + React Frontend + TimescaleDB)

> **Structure**: Multi-workspace monorepo
> **Workspaces**: database, backend, frontend

## Workspace: database

### Lint Migrations
```bash
cd database && sqlfluff lint migrations/
```

### Validate Migrations
```bash
cd database && ./test-migrations.sh
```

### Migration Commands
```bash
# Up
cd database && migrate -path migrations -database "$DATABASE_URL" up

# Down
cd database && migrate -path migrations -database "$DATABASE_URL" down 1
```

## Workspace: backend

### Lint
```bash
cd backend && golangci-lint run --fix
```

### Typecheck
```bash
cd backend && go vet ./...
```

### Test
```bash
cd backend && go test ./...
```

### Build
```bash
cd backend && go build -o bin/app ./cmd/app
```

## Workspace: frontend

### Lint
```bash
cd frontend && npm run lint --fix
```

### Typecheck
```bash
cd frontend && npm run typecheck
```

### Test
```bash
cd frontend && npm test
```

### Build
```bash
cd frontend && npm run build
```

### E2E Tests (Optional)
```bash
# If playwright.config.ts exists
cd frontend && npm run test:e2e
```

## Validation Order

When running `/check` at root, validate in order:
1. database (migrations first)
2. backend (then backend)
3. frontend (then frontend)
