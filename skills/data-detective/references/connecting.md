# Connecting to the database

The goal: a working connection without secrets ever entering the agent's context. Secret
files (`.env`, `.env.local`, credentials files) are never read; the hub's `deny-secret-files`
hook blocks them anyway. Verify the connection with one cheap query, then move on.

## Discovery procedure (in order)

1. **Database MCP connector.** If one is connected (e.g. a Neon Postgres connector), use it — it
   avoids handling raw credentials at all. Load its tools with `ToolSearch`, then use tools like
   `run_sql`, `get_database_tables`, `describe_table_schema`, `explain_sql_statement`,
   `list_slow_queries`.

2. **Variables the operator exported.** Check whether `DATABASE_URL`, `DB_URL`, `POSTGRES_URL`,
   `PG*` or `DB_*` are set in the shell (test for presence; never print values). The profiler
   script and `psql` read them directly.

3. **Non-secret config, to learn the shape.** `.env.example` shows variable *names*. Framework
   config shows the database name, host and port, which tell the operator what to export:
   - **Spring Boot (Java):** `src/main/resources/application*.properties` / `*.yml` →
     `spring.datasource.url` / `username` / `password`. The URL often interpolates an env var
     with a literal fallback, e.g. `${DB_URL:jdbc:postgresql://localhost:5432/appdb}` — that
     fallback is the local connection string.
   - **Django:** `settings.py` → `DATABASES['default']`.
   - **Rails:** `config/database.yml`.
   - **Node (Prisma / TypeORM / Knex / Sequelize):** `schema.prisma` (`datasource db`),
     `ormconfig.*`, `knexfile.js`.
   - **Laravel:** `config/database.php`.
   - **docker-compose:** `docker-compose*.yml` gives the db image, mapped port and database name.
     The host is usually `localhost` + the mapped port from outside the compose network.

4. **Ask.** If there is no connector and nothing exported, tell the operator what you found
   (database name, host, port, variable names) and ask them to export the connection, e.g.
   `export DATABASE_URL=...` in the shell that runs the agent, or to connect an MCP connector.

**Never print a password or connection string back to the user.** Redact them in any output.

## Running queries

Pick the lightest tool that works. Use one cheap query (`SELECT 1;`) to confirm the connection
before doing real work.

### Postgres via psql
```bash
# From a connection string:
psql "postgresql://user:pass@host:5432/dbname" -c "SELECT 1;"

# From PG* env vars (no inline secrets), pulling DB_PASS into PGPASSWORD:
PGPASSWORD="$DB_PASS" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "\dt"

# Useful psql meta-commands:
#   \dt            list tables        \d+ tablename   describe table + sizes
#   \dn            list schemas       \df             list functions
#   \timing on     show query timing
```
For multi-line analytical queries, write the SQL to a temp `.sql` file and run
`psql ... -f query.sql` — easier to iterate on and to show the user.

### Postgres / SQLite via Python
`scripts/profile_db.py` already does discovery + profiling. For ad-hoc queries, a tiny script
with `psycopg` (v3) or `psycopg2` for Postgres, or stdlib `sqlite3` for SQLite, is reliable and
lets you post-process results (e.g. into the dashboard's JSON). Prefer parameterized queries.

### MySQL
`mysql -h host -u user -p dbname -e "SELECT 1;"` (or `MYSQL_PWD` env to avoid the prompt).

### Via MCP connector
Load the connector's tools with `ToolSearch`, then call its SQL/inspection tools directly. Use
its `EXPLAIN`/slow-query tools when present — they're tuned for that database.

## Scratch-table hygiene

Scratch objects are writes: create them only after the operator says yes. Then keep them
contained and clean up:

```sql
-- Prefer a session-scoped temp table when the work is one-shot (auto-dropped on disconnect):
CREATE TEMP TABLE scratch_funnel AS SELECT ... ;

-- For work that spans queries/sessions, namespace clearly and drop when done:
CREATE TABLE scratch_activation_2026q2 AS SELECT ... ;
-- ... analysis ...
DROP TABLE scratch_activation_2026q2;

-- For repeated heavy aggregates, a materialized view (remember REFRESH, and to drop it):
CREATE MATERIALIZED VIEW scratch_daily_runs AS SELECT ... ;
```

Never create scratch objects that shadow or collide with application tables.
