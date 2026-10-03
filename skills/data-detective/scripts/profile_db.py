#!/usr/bin/env python3
"""
Fast, scan-free database profiler for the data-detective skill.

Builds a structural picture of a database WITHOUT expensive full-table scans, so it's safe
to run against large or production databases. For Postgres it reads the planner's own
statistics (pg_class.reltuples for row estimates, pg_stats for per-column null fraction,
distinct count, and most-common values) — these are effectively free. SQLite has no such
statistics, so it falls back to exact counts, which scan every table: fine for small files only.

Connection is auto-discovered (no need to pass secrets on the command line):
  1. --url / first positional arg, if given
  2. DATABASE_URL / DB_URL / POSTGRES_URL env var
  3. PG* env vars (PGHOST/PGUSER/PGDATABASE/PGPASSWORD/PGPORT)
  4. DB_HOST/DB_USER/DB_PASS/DB_NAME/DB_PORT env vars
  5. a *.sqlite / *.db file passed as the URL

Usage:
  python profile_db.py                          # discover connection from env
  python profile_db.py "postgresql://u:p@host/db"
  python profile_db.py --schema public --top 8  # rows of most-common values per column
  python profile_db.py ./app.sqlite

Output is Markdown to stdout: a table summary, then per-table column profiles.
Drivers: Postgres needs psycopg (v3) or psycopg2; SQLite uses the stdlib. The script tells
you what to install if neither Postgres driver is present.
"""
import os
import sys
import argparse


def discover_url(explicit):
    if explicit:
        return explicit
    for var in ("DATABASE_URL", "DB_URL", "POSTGRES_URL"):
        if os.environ.get(var):
            return os.environ[var]
    # Assemble from discrete vars (PG* first, then DB_*).
    host = os.environ.get("PGHOST") or os.environ.get("DB_HOST")
    user = os.environ.get("PGUSER") or os.environ.get("DB_USER")
    db = os.environ.get("PGDATABASE") or os.environ.get("DB_NAME")
    pw = os.environ.get("PGPASSWORD") or os.environ.get("DB_PASS")
    port = os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432"
    if host and user and db:
        auth = f"{user}:{pw}@" if pw else f"{user}@"
        return f"postgresql://{auth}{host}:{port}/{db}"
    return None


def is_sqlite(url):
    return url and (url.endswith(".sqlite") or url.endswith(".db")
                    or url.startswith("sqlite:"))


# ---------------------------------------------------------------- Postgres ----
def connect_pg(url):
    try:
        import psycopg  # v3
        return psycopg.connect(url), "psycopg"
    except ImportError:
        pass
    try:
        import psycopg2
        return psycopg2.connect(url), "psycopg2"
    except ImportError:
        sys.exit("No Postgres driver found. Install one:\n"
                 "  pip install 'psycopg[binary]'   # or: pip install psycopg2-binary")


def q(cur, sql, params=None):
    cur.execute(sql, params or ())
    return cur.fetchall()


def profile_postgres(url, schema, top):
    conn, driver = connect_pg(url)
    cur = conn.cursor()
    out = [f"# Database profile (Postgres via {driver})", ""]

    tables = q(cur, """
        SELECT c.relname,
               c.reltuples::bigint                         AS est_rows,
               pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = %s AND c.relkind = 'r'
        ORDER BY pg_total_relation_size(c.oid) DESC
    """, (schema,))

    if not tables:
        print(f"No tables found in schema '{schema}'.")
        conn.close()
        return

    out += [f"## Tables in `{schema}` ({len(tables)})", "",
            "| table | est. rows | size |", "|---|---:|---:|"]
    for name, rows, size in tables:
        shown = f"{rows:,}" if rows >= 0 else "n/a (run ANALYZE)"
        out.append(f"| {name} | {shown} | {size} |")
    out.append("")
    out.append("> Row counts are planner estimates (instant, may be stale — run "
               "`ANALYZE` for fresh stats). Tables ordered by on-disk size.")
    out.append("")

    for name, est_rows, _ in tables:
        est_rows = max(est_rows, 0)  # -1 means never ANALYZEd; treat as unknown
        hdr_rows = f"~{est_rows:,} rows" if est_rows else "row count unknown"
        out += [f"## `{name}` — {hdr_rows}", "",
                "| column | type | null % | distinct | most common |",
                "|---|---|---:|---:|---|"]
        cols = q(cur, """
            SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                   s.null_frac, s.n_distinct, s.most_common_vals
            FROM pg_attribute a
            JOIN pg_class c ON c.oid = a.attrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            LEFT JOIN pg_stats s
                   ON s.schemaname = n.nspname AND s.tablename = c.relname
                  AND s.attname = a.attname
            WHERE n.nspname = %s AND c.relname = %s
              AND a.attnum > 0 AND NOT a.attisdropped
            ORDER BY a.attnum
        """, (schema, name))
        for attname, typ, null_frac, n_distinct, mcv in cols:
            null_pct = f"{null_frac*100:.1f}%" if null_frac is not None else "—"
            # n_distinct: positive = absolute count; negative = fraction of rows.
            if n_distinct is None:
                dist = "—"
            elif n_distinct < 0:
                dist = f"~{abs(n_distinct)*est_rows:,.0f}"
            else:
                dist = f"{n_distinct:,.0f}"
            common = ""
            if mcv:
                # psycopg returns anyarray as its text form "{a,b,c}"; split it to honour --top.
                vals = mcv if isinstance(mcv, list) else str(mcv).strip("{}").split(",")
                common = ", ".join(str(v) for v in vals[:top])
                if len(vals) > top:
                    common += ", …"
            out.append(f"| {attname} | {typ} | {null_pct} | {dist} | {common} |")
        out.append("")

    print("\n".join(out))
    conn.close()


# ------------------------------------------------------------------ SQLite ----
def profile_sqlite(url, top):
    import sqlite3
    path = url.replace("sqlite:///", "").replace("sqlite:", "")
    conn = sqlite3.connect(path)
    cur = conn.cursor()
    out = [f"# Database profile (SQLite: {path})", ""]

    tables = [r[0] for r in cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name").fetchall()]
    if not tables:
        print("No tables found.")
        conn.close()
        return

    out += [f"## Tables ({len(tables)})", "", "| table | rows |", "|---|---:|"]
    counts = {}
    for t in tables:
        n = cur.execute(f'SELECT count(*) FROM "{t}"').fetchone()[0]
        counts[t] = n
        out.append(f"| {t} | {n:,} |")
    out.append("")

    for t in tables:
        n = counts[t] or 1
        out += [f"## `{t}` — {counts[t]:,} rows", "",
                "| column | type | null % | distinct |", "|---|---|---:|---:|"]
        for cid, cname, ctype, *_ in cur.execute(f'PRAGMA table_info("{t}")').fetchall():
            nulls = cur.execute(
                f'SELECT count(*) FROM "{t}" WHERE "{cname}" IS NULL').fetchone()[0]
            distinct = cur.execute(
                f'SELECT count(DISTINCT "{cname}") FROM "{t}"').fetchone()[0]
            out.append(f"| {cname} | {ctype or '—'} | {nulls*100.0/n:.1f}% | {distinct:,} |")
        out.append("")

    print("\n".join(out))
    conn.close()


def main():
    ap = argparse.ArgumentParser(description="Scan-free database profiler.")
    ap.add_argument("url", nargs="?", help="connection string or sqlite file path")
    ap.add_argument("--url", dest="url_flag", help="connection string (alternative)")
    ap.add_argument("--schema", default="public", help="Postgres schema (default: public)")
    ap.add_argument("--top", type=int, default=5, help="most-common values to show")
    args = ap.parse_args()

    url = discover_url(args.url or args.url_flag)
    if not url:
        sys.exit("Could not discover a connection. Pass one as an argument, or set "
                 "DATABASE_URL / DB_URL / PG* / DB_* env vars. See references/connecting.md.")

    if is_sqlite(url):
        profile_sqlite(url, args.top)
    else:
        profile_postgres(url, args.schema, args.top)


if __name__ == "__main__":
    main()
