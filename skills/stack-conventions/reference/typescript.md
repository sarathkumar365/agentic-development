# TypeScript

## Defaults
- `strict` on. Follow the project's `tsconfig`, module system and test runner.
- No `any`. Use `unknown` and narrow it.
- Validate data at the boundary (API responses, env, user input) with the project's validator,
  such as zod. Trust types only after validation.
- String-literal unions or `as const` objects over `enum`.
- Discriminated unions for states that are mutually exclusive.
- Named exports. `===` always.

## Pitfalls
- The non-null assertion `!` silences a real `undefined`. Narrow instead.
- A floating promise, one neither awaited nor caught, loses its error. Await it or handle it.
- `as` casts skip checking. A cast on external data is a bug waiting.
- `Array.prototype.sort` sorts as strings by default: `[10, 9].sort()` gives `[10, 9]`. Pass a
  comparator.
- Optional property `x?: T` is not the same as `x: T | undefined` under
  `exactOptionalPropertyTypes`.
