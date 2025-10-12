# Stack Configuration

> **Purpose**: This file defines validation commands for your project's tech stack.
>
> **Used by**: `/build`, `/check`, `/ship` commands
>
> **Customize**: Edit this file directly or run `init-project.sh [path] [preset]`

## Single-Stack Example

For projects with one tech stack (frontend OR backend):

```markdown
# Stack: TypeScript + React + Vite

## Lint
```bash
npm run lint --fix
```

## Typecheck
```bash
npm run typecheck
```

## Test
```bash
npm test
```

## Build
```bash
npm run build
```
```

## Monorepo Example

For projects with multiple workspaces (frontend AND backend):

```markdown
# Stack: Monorepo (Go Backend + React Frontend)

## Workspace: backend

### Lint
```bash
cd backend && golangci-lint run
```

### Test
```bash
cd backend && go test ./...
```

### Build
```bash
cd backend && go build -o bin/ ./...
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
```

## Available Presets

Run `init-project.sh [path] [preset]` with:
- `typescript-react-vite` - TypeScript + React + Vite (npm)
- `python-fastapi` - Python + FastAPI + pytest
- `go-standard` - Go + standard library
- `nextjs-app-router` - Next.js + TypeScript (npm)
- `monorepo-go-react` - Go backend + React frontend + TimescaleDB

## Customization Tips

**Package managers:**
Replace `npm` with `pnpm`, `yarn`, or `bun`

**Test runners:**
Replace `npm test` with `vitest`, `jest`, `pytest`, etc.

**Linters:**
Replace with `eslint`, `ruff`, `golangci-lint`, `clippy`, etc.

**Monorepo workspaces:**
Add sections for each workspace with appropriate commands
