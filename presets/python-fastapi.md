# Stack: Python + FastAPI

> **Package Manager**: pip
> **Test Runner**: pytest
> **Linter**: ruff

## Lint
```bash
ruff check --fix .
```

## Typecheck
```bash
mypy .
```

## Test
```bash
pytest
```

## Format
```bash
black . && isort .
```

## Test with Coverage (Optional)
```bash
pytest --cov=app --cov-report=term-missing
```
