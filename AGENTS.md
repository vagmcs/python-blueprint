# AGENTS.md

## File Structure

```text
project/       # Production source code
tests/         # Pytest suite
docs/          # MkDocs docs (source in docs/docs/, templates in docs/templates/)
notebooks/     # Jupyter notebooks (exploratory only)
sql/           # SQL files (sqlfluff-linted)
pyproject.toml # Single source of truth for all tool config
```

## Commands

```sh
uv sync                            # Install all dependencies (incl. dev)
uv run poe format                  # ruff format + sqlfluff fix
uv run poe lint                    # ruff check --fix + basedpyright
uv run poe test                    # pytest with coverage → coverage/
uv run poe build-docs              # Build MkDocs site → docs/site/
uv run poe local-docs              # Serve docs at localhost:8000
uv run poe package                 # Build wheel + sdist
uv run poe build-all               # test → package → build-docs
uv run poe bump                    # Bump version + generate changelog
uv run pre-commit run --all-files  # Run all pre-commit hooks manually
```

## Code Style

- **Line length:** 120 | **Formatter:** `ruff format` | **Type checker:** `basedpyright` (recommended mode)
- **Linter rules:** `D` (Google docstrings), `I` (isort), `UP` (pyupgrade) — `D1` ignored
- **Naming:** `snake_case` functions/variables, `PascalCase` classes, `UPPER_SNAKE_CASE` constants, `_leading_underscore` private
- **Docstrings:** Google-style with doctests where applicable (`--doctest-modules` is always on).

## Testing

`pytest` + `pytest-cov`, `pytest-mock`, `pytest-sugar`, `hypothesis`. Coverage targets `project/`; exit code 5 (no tests collected) is treated as success.

```sh
uv run poe test                     # Full suite
uv run pytest tests/test_foo.py -v  # Single file
```

## Git Workflow

Commits and PR titles **must** follow [Conventional Commits](https://www.conventionalcommits.org/), enforced by `commitizen` on `commit-msg` and `pr-title-checker` in CI.

```
<type>[scope][!]: <Capital-case description>
```

Types: `build` `chore` `ci` `docs` `feat` `fix` `perf` `refactor` `release` `test` `security` — append `!` for breaking changes.

```
feat: Add retry logic to HTTP client
fix(parser): Handle empty input gracefully
feat!: Drop Python 3.9 support
```

PRs target `main`. Labels are auto-assigned from the title. Use `skip changelog` to omit a PR from release notes.

## Boundaries

- ✅ **Always:** lint and test before committing; Google-style docstrings with doctests; tests for all changes; config stays in `pyproject.toml`
- ⚠️ **Ask first:** adding dependencies; changing tool config; modifying CI workflows; bumping the version (`uv run poe bump`); editing `docs/templates/`
- 🚫 **Never:** commit secrets (gitleaks enforces this); edit `uv.lock` manually; touch `.venv/` or `__pycache__/`; remove failing tests; disable linting/type-checking rules without a comment; force-push to `main`
