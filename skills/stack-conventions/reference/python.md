# Python

## Defaults
- Use the project's tooling: the package manager (uv, poetry, pip), formatter and linter (ruff,
  black) and type checker. Read `pyproject.toml` first.
- Type hints on every public function.
- `pathlib` over `os.path`. f-strings. `logging` over `print` outside scripts.
- `dataclasses` for plain data, Pydantic only if the project uses it.
- Timezone-aware datetimes: `datetime.now(timezone.utc)`, never naive `datetime.now()`.
- `Decimal` for money.
- Tests: pytest with fixtures and `parametrize`.

## Pitfalls
- Mutable default arguments (`def f(x=[])`) are shared across calls. Default to `None`.
- A bare `except:` or `except Exception:` hides bugs. Catch what you expect.
- A blocking call (`requests`, `time.sleep`, sync DB drivers) inside `async def` stalls the event
  loop.
- Late-binding closures in loops capture the variable, not its value.
- `is` compares identity. Use `==` for values, `is` only for `None`.
