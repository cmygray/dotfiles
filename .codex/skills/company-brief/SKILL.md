---
name: company-brief
description: Create Korean startup/company analysis HTML reports. Use when Codex is asked to produce a company brief, company analysis report, startup investment/revenue analysis, or "기업 분석/기업 브리프/company brief" for a named Korean company, using DART, Innoforest, web research, and the user's reports workspace. Do not use for quick fact checks or general market research without a named company.
---

# Company Brief

Create a sourced Korean startup/company analysis report as a self-contained HTML file.

## Trigger Boundary

Use this skill only when both are true:

- The user names a specific company.
- The user asks for a report, company analysis, company brief, investment analysis, or similar deliverable.

Do not use this skill for quick facts such as "CEO가 누구야?", person tracking, or broad market research without a named company.

## Output

- `${REPORTS_DIR:-/Users/won/Workspace/research/reports}/<slug>.html`: standalone HTML report.
- `${REPORTS_DIR}/index.html`: add one report card when the report is published.
- Public URL in Won's environment: `https://home.two.kim/<slug>.html`.

If `REPORTS_DIR` is set, use it. Otherwise use `/Users/won/Workspace/research/reports`.

## Local Assumptions

- Reports directory: `/Users/won/Workspace/research/reports/`.
- Shared CSS: `reports/assets/report.css`; link it instead of writing one-off inline styles.
- HTML skeleton: `reports/_template/skeleton.html`.
- Data scripts: `reports/_scripts/restore-cookies.sh`, `reports/_scripts/fetch-company.sh`.
- DART API key: `/Users/won/Workspace/research/.env` as `DART_API_KEY`.
- Innoforest cookies: `~/.innoforest_cookies.txt` with mode `600`.

Mark uncertain facts with `TODO: verify` until sourced.

## Workflow

### 1. Collect Data

Run cookie restoration once per session when Innoforest access is needed:

```bash
bash "${REPORTS_DIR:-/Users/won/Workspace/research/reports}/_scripts/restore-cookies.sh"
```

For the named company, gather in parallel when practical:

- `dartcli search "<company>"`: check whether DART has the company.
- Innoforest URL from the user, if provided. If missing, search for it; Innoforest search often misses registered companies, so ask the user for the URL if search fails.
- Web research for funding, news, executives, customers, products, market, and risks. Cite source URLs and source dates in notes or report footnotes.

Use the existing fetch script when an Innoforest URL is available:

```bash
bash "${REPORTS_DIR:-/Users/won/Workspace/research/reports}/_scripts/fetch-company.sh" "<company>" "<innoforest_url>"
```

If DART has the company, also inspect:

- `dartcli company "<company>"`: company overview.
- `dartcli list "<company>" --limit 5`: latest filings.
- `dartcli view <receipt_no>` for the latest audit report: extract revenue, operating profit, capital, and notes.

### 2. Classify the Company Pattern

Pick the closest report pattern from the collected data:

| Pattern | Trigger | Sister report |
|---|---|---|
| Rich financials | Multi-year DART audit data with clear revenue/profit | `washswat.html`, `bosalpim_analysis.html` |
| Private revenue | Non-audited, young startup, or revenue unavailable | `aim_intelligence.html` |
| Dual company | Innoforest has both company and investor pages | `vntg.html` |
| Pure VC | Innoforest investor page only | First report becomes the sister |

Emphasis by pattern:

- Rich financials: 3-year P&L, capital movement, SG&A breakdown, and financial charts.
- Private revenue: funding velocity, lead VC quality, customer references, certifications, headcount, hiring, traffic, and category position.
- Dual company: clearly separate operating business and investment activity, then test claimed synergy.
- Pure VC: portfolio mix, co-investor network, follow-on/exit signals, and strategy.

### 3. Write the HTML

```bash
SLUG=<english_lowercase_slug>
cp "${REPORTS_DIR:-/Users/won/Workspace/research/reports}/_template/skeleton.html" \
  "${REPORTS_DIR:-/Users/won/Workspace/research/reports}/${SLUG}.html"
```

Replace skeleton placeholders with sourced data. Delete irrelevant sections completely. Reuse existing components from sister reports instead of inventing new CSS.

Common components:

| Component | CSS class | Use |
|---|---|---|
| Executive summary | `.tldr` | 3-5 sentence conclusion |
| KPI grid | `.kpis`, `.kpi` | 4 or 8 headline metrics |
| Card | `.card` | Tables and charts |
| Two-column | `.two-col` | Side-by-side table/chart |
| Signal list | `ol.signals` | 5-7 numbered signal cards |
| Verify grid | `.verify` | 3-column verification items |
| Timeline | `.timeline` | Funding or business timeline |
| Product cards | `.product-grid`, `.product` | 3-up products |
| Logo pills | `.logos`, `span` | Customers and partners |
| Duality | `.duality` | Dual-company headline |
| Badge | `.badge.pos`, `.badge.neg`, `.badge.warn` | Signal classification |

### 4. Publish and Verify

If using Won's static hosting setup, placing the file in `REPORTS_DIR` publishes it. Verify:

```bash
curl -sS -o /dev/null -w "HTTP %{http_code}\n" "https://home.two.kim/${SLUG}.html"
```

Update `index.html` with one `<a class="report-card" href="...">` card that matches existing cards.

## Design Rules

- Do not create one-off CSS. Use `assets/report.css`; if a new style is truly needed, add it there using existing variables.
- Use Chart.js 4.4.1 from CDN for charts; do not add another charting library.
- Do not use emoji in report body unless the user explicitly asks.
- Format numbers in Korean units, for example `10억원` rather than `1,000,000,000원`.
- Include traceable sources in the footer or notes, such as DART corp_code, Innoforest ID, source title, URL, and access date.
- Keep positive, caution, and risk signals mixed. Do not write a one-sided promotional report.

## Fallback Signals When Revenue Is Private

- Funding velocity: intervals between seed, Pre-A, Series A, and later rounds.
- Lead VC upgrade: whether larger or more specialized investors lead later rounds.
- Top-tier customers: finance, enterprise, government, education, or global logos.
- Global certification or awards: for example GITEX, Meta, OutSystems, ISO, SOC, or public procurement signals.
- Team signals: headcount, hiring volume, CTO/C-level pedigree, and job seniority.
- Usage signals: MUV, GMV, ARPU, conversion, retention, repeat purchase, or public traffic.
- External perspective: Innoforest viewed-together companies, rankings, and category position.

## Common Pitfalls

- Innoforest search misses companies that are registered; ask for the direct URL when needed.
- Try Korean and English DART names, for example legal name, brand name, and romanized variants.
- For private companies, `dartcli finance` may be unavailable; use `dartcli view <receipt_no>` on audit reports.
- If browser/cookie access expires, rerun `restore-cookies.sh`; if it still fails, tell the user what auth is needed.
- For dual companies, check whether the same slug has both company and investor pages.
- Innoforest cumulative funding can differ from press reports because private rounds may be omitted. Show both when sourced.

## Credential Safety

- Never print secrets, auth tokens, cookies, IDs, or passwords.
- Do not use shell expressions like `${VAR:+yes}${VAR:-no}` for credentials; if set, that can print values. Use `[ -n "$VAR" ] && echo yes`.
- If the user provides credentials, use them only to obtain cookies, then stop using them.
- At the end, remind the user to clean temporary `.env` values and rotate passwords if any were pasted into the session.
