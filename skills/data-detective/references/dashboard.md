# Building the insight dashboard

When the analysis is rich enough to deserve a visual — multiple metrics worth watching over time,
something the user will revisit, or when they ask — produce a **single self-contained HTML file**
they can open in a browser with no server, no build step, and no network dependency on their data.

## Principles

- **One file, opens offline.** Inline the data, inline the rendering. The user double-clicks it
  and it works on a plane. Put the data in a `<script>` block as a JSON object — *do not* fetch it
  at runtime.
- **Insights first, charts second.** The top of the page is a short, ranked list of the actual
  findings in plain language (the same insights from your conversational answer). Charts exist to
  *support* the findings, not to replace them. A dashboard that's all charts and no conclusions
  makes the reader do the analyst's job.
- **KPI cards up top** — the 3–6 numbers that matter, each with context (a comparison, a trend
  arrow, or a target) so a number means something. "1,240 runs" is trivia; "1,240 runs, 8.3%
  failed (↑ from 5% last week)" is a signal.
- **Show the magnitude and the trend**, not just the snapshot. Time series beat single numbers for
  anything that moves.
- **Honest charts.** Axis labels, a baseline at zero for bar charts, percentiles not averages for
  latency, and a note on the time window and sample size. No chartjunk.
- **Drill-down where it helps** — category → detail (e.g. failures → failure reasons → example
  rows) so the reader can interrogate a finding.
- **Mask PII** in any row-level detail unless the user explicitly needs it.

## How to build it

1. Run your analytical queries and **serialize the results to JSON** — either write a small Python
   script that queries and dumps JSON, or run SQL and transform the output. Keep each chart's data
   as a named array.
2. Embed that JSON in the HTML. A charting library via CDN (Chart.js, etc.) is fine *if* the user
   has internet when they open it; if offline-guaranteed matters, inline the library or hand-roll
   SVG/CSS bars (simple bar/line charts in plain SVG are robust and dependency-free).
3. Structure: title + analysis window → ranked insights → KPI cards → charts (with captions stating
   what each shows and the caveat) → optional drill-down tables.
4. Save it somewhere obvious (e.g. `./data-insights-dashboard.html` in the project, or a path the
   user names) and tell the user the exact path to open.

## Skeleton

```html
<!doctype html><html><head><meta charset="utf-8"><title>Data Insights</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 15px/1.5 system-ui, sans-serif; margin: 0; padding: 24px; max-width: 1100px; }
  .kpis { display: grid; grid-template-columns: repeat(auto-fit,minmax(180px,1fr)); gap: 12px; }
  .card { border: 1px solid #8883; border-radius: 10px; padding: 16px; }
  .card .num { font-size: 28px; font-weight: 700; }
  .card .ctx { opacity: .7; font-size: 13px; }
  .insight { border-left: 3px solid #4a9; padding: 8px 14px; margin: 10px 0; }
  svg { width: 100%; height: auto; }
</style></head>
<body>
  <h1>Data Insights — <span id="window"></span></h1>
  <section id="insights"></section>
  <section class="kpis" id="kpis"></section>
  <section id="charts"></section>
  <script>
    const DATA = { /* embed your query results here */ };
    // render KPI cards, insight list, and charts (SVG or a CDN lib) from DATA
  </script>
</body></html>
```

Adapt freely — the skeleton is a starting point, not a straitjacket. The non-negotiables are:
self-contained, insights-first, honest charts, PII masked.
