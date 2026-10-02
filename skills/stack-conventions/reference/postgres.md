# PostgreSQL

## Defaults
- Schema changes only through the project's migration tool. Never edit a migration that has
  already run anywhere.
- `timestamptz`, never `timestamp`. `numeric` for money. `text` unless a length limit is a real
  rule.
- `bigint generated always as identity` for ids, or `uuid` if the project uses it.
- Put integrity in the database: `NOT NULL`, `CHECK`, `UNIQUE`, foreign keys.
- Index every foreign key column. Postgres does not do it for you.
- Parameterised queries always. Never build SQL by string concatenation.
- Name columns in `SELECT`. No `SELECT *` in application code.

## Pitfalls
- `NOT IN (subquery)` returns no rows if the subquery yields a `NULL`. Use `NOT EXISTS`.
- `CREATE INDEX` locks writes on a live table. Use `CREATE INDEX CONCURRENTLY`, which cannot run
  inside a transaction.
- `OFFSET` pagination gets slower with every page. Use keyset pagination on large tables.
- Long transactions hold locks and block vacuum. Keep them short.
- Do not claim a query is fast or slow without `EXPLAIN (ANALYZE, BUFFERS)` on realistic data.
