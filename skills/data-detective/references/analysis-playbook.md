# Analysis playbook

Patterns for turning a product database into insights that move a lever. Each pattern has the
*question it answers*, the *SQL shape* (Postgres flavor — adapt to your dialect and your actual
table/column names), and the *traps* that make the answer wrong. **Always substitute the real
schema** — these are skeletons, not copy-paste.

Before any of this: profile the data (`scripts/profile_db.py`) and read the schema's *meaning*
from migrations/README. Knowing a table is called `runs` with 4.2M rows tells you nothing until
you know one row = one execution attempt of one workflow.

---

## 1. Funnel / drop-off — *"where do we lose people?"*

The highest-leverage product question. Count how many entities reach each successive step.

```sql
WITH steps AS (
  SELECT
    u.id,
    TRUE                                   AS signed_up,
    bool_or(e.name = 'created_first_item') AS activated,
    bool_or(e.name = 'completed_action')   AS succeeded
  FROM users u
  LEFT JOIN events e ON e.user_id = u.id
  WHERE u.created_at >= now() - interval '90 days'   -- bound the cohort
  GROUP BY u.id
)
SELECT
  count(*)                                              AS signed_up,
  count(*) FILTER (WHERE activated)                     AS activated,
  count(*) FILTER (WHERE succeeded)                     AS succeeded,
  round(100.0 * count(*) FILTER (WHERE activated) / count(*), 1)  AS pct_activated,
  round(100.0 * count(*) FILTER (WHERE succeeded) / nullif(count(*) FILTER (WHERE activated),0), 1) AS pct_act_to_success
FROM steps;
```
**Traps:** counting events instead of distinct users; not bounding the cohort by time (so brand-new
users who haven't *had time* to convert drag the rate down — exclude users too recent to convert);
double-counting when a user can do a step twice; including test/seed accounts.

The biggest single drop in the funnel is usually your headline insight.

---

## 2. Cohort retention — *"do they come back?"*

Group users by signup week, then measure what fraction are active N weeks later.

```sql
WITH cohort AS (
  SELECT id, date_trunc('week', created_at) AS cohort_week FROM users
),
activity AS (
  SELECT DISTINCT user_id, date_trunc('week', occurred_at) AS active_week FROM events
)
SELECT
  c.cohort_week,
  count(DISTINCT c.id)                                                    AS cohort_size,
  extract(week FROM a.active_week - c.cohort_week)::int                   AS weeks_since,
  count(DISTINCT a.user_id)                                               AS retained
FROM cohort c
LEFT JOIN activity a ON a.user_id = c.id AND a.active_week >= c.cohort_week
GROUP BY c.cohort_week, weeks_since
ORDER BY c.cohort_week, weeks_since;
```
Pivot weeks_since into columns for the classic retention triangle. **Traps:** the most recent
cohorts have fewer observable weeks (don't compare week-8 retention of a cohort that's only 2
weeks old); timezone in `date_trunc`; counting passive pings as "active" when you mean meaningful
use.

A retention curve that flattens (vs. decays to zero) means you have a sticky core — find out what
those users did that the churned ones didn't.

---

## 3. Activation / aha-moment — *"what early action predicts they stick around?"*

Compare retained vs. churned users on what they did in their first session/week.

```sql
WITH first_week AS (
  SELECT e.user_id,
         count(*) FILTER (WHERE e.name = 'key_action') AS key_actions
  FROM events e JOIN users u ON u.id = e.user_id
  WHERE e.occurred_at < u.created_at + interval '7 days'
  GROUP BY e.user_id
),
retained AS (  -- active in week 4+
  SELECT DISTINCT user_id FROM events e JOIN users u ON u.id = e.user_id
  WHERE e.occurred_at >= u.created_at + interval '28 days'
)
SELECT (r.user_id IS NOT NULL) AS retained,
       avg(f.key_actions) AS avg_key_actions, count(*) AS n
FROM first_week f LEFT JOIN retained r ON r.user_id = f.user_id
GROUP BY retained;
```
If retained users did the key action far more in week 1, you've found a candidate aha-moment —
worth driving new users toward. **Trap:** correlation ≠ causation. Engaged people both do more
*and* retain; the action may be a symptom, not a cause. Frame it as a hypothesis to test, not a
proven lever.

---

## 4. Engagement & stickiness — *"how deeply and often is it used?"*

```sql
-- DAU/WAU stickiness ratio (closer to 1 = people use it most days)
SELECT
  count(DISTINCT user_id) FILTER (WHERE occurred_at >= now() - interval '1 day')  AS dau,
  count(DISTINCT user_id) FILTER (WHERE occurred_at >= now() - interval '7 days') AS wau
FROM events;

-- Usage concentration: are a few power users carrying everything?
SELECT ntile(10) OVER (ORDER BY cnt DESC) AS decile, sum(cnt) AS actions
FROM (SELECT user_id, count(*) cnt FROM events GROUP BY user_id) t
GROUP BY decile ORDER BY decile;
```
Heavy concentration (top decile = most of the volume) is common and important: it tells you
whether you're building for the few or the many, and which users to interview.

---

## 5. Feature usage — *"what's actually used vs. dead weight?"*

```sql
SELECT feature, count(DISTINCT user_id) AS users, count(*) AS uses,
       max(occurred_at) AS last_used
FROM events GROUP BY feature ORDER BY users DESC;
```
Features with near-zero distinct users, or a `last_used` long in the past, are candidates to cut,
fix, or surface better. A feature that's *built* but *unused* is either undiscoverable or
unwanted — worth knowing which.

---

## 6. Reliability & performance — *"what's failing or slow?"*

If the product records runs/jobs/requests with statuses and durations, this is often where the
fastest wins live.

```sql
-- Failure rate over time
SELECT date_trunc('day', created_at) AS day,
       count(*) AS total,
       count(*) FILTER (WHERE status = 'failed') AS failed,
       round(100.0 * count(*) FILTER (WHERE status='failed') / count(*), 2) AS pct_failed
FROM runs WHERE created_at >= now() - interval '30 days'
GROUP BY day ORDER BY day;

-- Failure breakdown by reason / type
SELECT error_type, count(*) FROM runs WHERE status='failed' GROUP BY error_type ORDER BY 2 DESC;

-- Latency percentiles (p50/p95/p99) — averages lie, percentiles don't
SELECT percentile_cont(0.50) WITHIN GROUP (ORDER BY duration_ms) AS p50,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY duration_ms) AS p95,
       percentile_cont(0.99) WITHIN GROUP (ORDER BY duration_ms) AS p99
FROM runs WHERE created_at >= now() - interval '7 days';
```
**Traps:** mean duration hides the tail (always use percentiles); a failure-rate spike may be one
bad deploy day, not a trend — look at the daily series, not just the aggregate.

---

## 7. Data quality — *both a finding and a caveat on everything else*

Run these early; quality problems silently corrupt every other metric.

```sql
-- Orphaned foreign keys (referential integrity gaps)
SELECT count(*) FROM child c LEFT JOIN parent p ON p.id = c.parent_id WHERE p.id IS NULL;

-- Duplicate grain (rows that should be unique but aren't)
SELECT natural_key, count(*) FROM t GROUP BY natural_key HAVING count(*) > 1;

-- NULL explosion in a column that should be populated
SELECT count(*) FILTER (WHERE important_col IS NULL) * 100.0 / count(*) AS pct_null FROM t;

-- Suspected test/seed pollution
SELECT count(*) FROM users WHERE email ILIKE '%test%' OR email ILIKE '%example.com';
```
If you find test accounts or duplicate grain, **re-examine earlier findings** — they may have been
inflated by exactly this.

---

## 8. Segmentation — *"is the average hiding two different stories?"*

Almost every aggregate gets more actionable when you split it by a meaningful dimension (plan,
acquisition channel, geography, account age, device). Watch for **Simpson's paradox**: a trend in
the whole can reverse within every segment. When a headline number is surprising, your next move
is almost always to segment it.

---

## Choosing what to chase

You can't run everything. Prioritize by where this specific product likely leaks value, informed
by the profile: if there's a rich events table, funnels/retention are in reach; if there's a runs
table with statuses, reliability is low-hanging fruit; if a core table is half-NULL, data quality
*is* the story. Pick 2–3 threads, go deep, and rank what you find.
