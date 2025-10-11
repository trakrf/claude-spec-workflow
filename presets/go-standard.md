# Spec Workflow Configuration
# Stack: Go (Standard Library / Gin / Echo / Chi)

## Project Type
**Stack**: go-standard
**Package Manager**: go modules
**Test Runner**: go test
**Build Tool**: go build

## Validation Commands
```yaml
lint:
  command: golangci-lint run
  autofix: golangci-lint run --fix

typecheck:
  command: go vet ./...

test:
  command: go test ./...
  watch: gotestsum --watch
  pattern: go test {package}
  coverage: go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out

format:
  command: gofmt -w . && goimports -w .

build:
  command: go build -o bin/app ./cmd/app
  output: bin/
```

## Code Quality Checks
```yaml
console_logs:
  pattern: 'fmt\.Println|fmt\.Printf'
  exclude: ['*_test.go', 'main.go']

todos:
  pattern: 'TODO|FIXME|XXX|HACK|BUG'

skipped_tests:
  pattern: 't\.Skip\('
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional
pr_template: .github/pull_request_template.md
```

## File Patterns
```yaml
test_suffix: ['_test.go']
source_dirs: ['internal/', 'pkg/', 'cmd/']
ignore_dirs: ['vendor', 'bin', '.go']
```
