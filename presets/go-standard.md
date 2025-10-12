# Stack: Go (Standard Library / Gin / Echo)

> **Package Manager**: Go modules
> **Test Runner**: go test
> **Linter**: golangci-lint

## Lint
```bash
golangci-lint run --fix
```

## Typecheck
```bash
go vet ./...
```

## Test
```bash
go test ./...
```

## Format
```bash
gofmt -w . && goimports -w .
```

## Build
```bash
go build -o bin/app ./cmd/app
```

## Test with Coverage (Optional)
```bash
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out
```
