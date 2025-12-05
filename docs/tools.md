# Tools

Ruff: fast linter and formatter. Replaces isort, black, most of flake8, parts of pylint.

## In VSCode

Extensions / tools:

- ✅ Pylance: enabled (primary language server + type checker)
- ✅ Ruff: enabled, configured as:
  - Default formatter for Python.
  - Only linter for style/quality.
    🚫 Pylint: disabled
    🚫 Pyright extension: disabled (since Pylance already uses Pyright)

## For CI / project-level checks

- Use Ruff and Pyright CLI for fast, modern checks:
  - ruff check . (and/or ruff format .)
  - pyright (installed via npm) for type checking.
- That way you get consistent type checking in editor and CI.

## Disable / Do Not Use

- Pylint: Slower than ruff
- flake8
- isort
- black
