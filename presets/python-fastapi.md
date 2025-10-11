# Spec Workflow Configuration
# Stack: Python + FastAPI

## Project Type
**Stack**: python-fastapi
**Package Manager**: pip
**Test Runner**: pytest
**Build Tool**: n/a

## Validation Commands
```yaml
lint:
  command: ruff check .
  autofix: ruff check --fix .

typecheck:
  command: mypy .

test:
  command: pytest
  watch: pytest-watch
  pattern: pytest {file}
  coverage: pytest --cov=app --cov-report=term-missing

format:
  command: black . && isort .
```

## Code Quality Checks
```yaml
console_logs:
  pattern: 'print\('
  exclude: ['test_*.py', '*_test.py', 'conftest.py']

todos:
  pattern: 'TODO|FIXME|XXX|HACK'

skipped_tests:
  pattern: '@pytest\.mark\.skip|@skip'
```

## Git Workflow
```yaml
branch_prefix: feature/
commit_style: conventional
pr_template: .github/pull_request_template.md
```

## File Patterns
```yaml
test_suffix: ['test_*.py', '*_test.py']
source_dirs: ['app/', 'src/', 'lib/']
ignore_dirs: ['__pycache__', 'venv', '.venv', '.pytest_cache', '.mypy_cache', '.ruff_cache']
```
