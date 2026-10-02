# React

## Defaults
- Function components and hooks. Follow the project's state, data-fetching and styling
  libraries; do not introduce a second one.
- Derive values during render. Do not copy props or other state into state.
- `useEffect` only to synchronise with something outside React: subscriptions, timers, the
  DOM, network when no data library is in use.
- Server data through the project's data library (React Query, SWR, a framework loader), not
  hand-rolled effects.
- Semantic elements first: `button` for actions, `a` for navigation, a `label` for every input.
- Tests with Testing Library, querying by role and accessible name.

## Pitfalls
- An effect that sets state from props causes an extra render and stale bugs. Compute it
  instead, or key the component.
- Dependency arrays must list everything the effect reads. Do not silence the lint rule.
- Array index as `key` breaks state when the list reorders or filters.
- `useMemo` and `useCallback` cost something. Add them when a measurement or a memoised child
  needs them, not by default.
- Objects and functions created inline are new on every render and defeat memoisation.
