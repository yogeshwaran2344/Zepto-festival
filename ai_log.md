# AI-Assisted Workflow Log

This document records the prompt engineering, iterative validation, and error correction process used to generate the executive decision memo (`docs/decision_memo.md`) for the Zepto Festive Demand Plan.

---

## 1. Exact Prompt

```text
TASK:
Draft an executive decision memo for Zepto category leads reviewing the festive demand plan and supplier purchase commitments for weeks 89–92 across 20 SKUs.

CONTEXT:
We have analyzed 88 weeks of sales history from zepto_festive.db. Because festive weeks experience elevated stock-out rates (historical festive stock-out incidence was 22.50% vs 6.01% in regular weeks), all demand baselines and category uplifts were computed exclusively from clean weeks (stockout_days = 0).
The analysis has been independently cross-checked in SQL and Python, and evaluated in a spreadsheet workbook (zepto_festive_demand_plan.xlsx).
Below is the verified data summary:

1. Overall Category Totals (Planned Demand vs Committed Orders):
- Dry Fruits & Gifting: Planned 5,894 units | Committed 6,090 units | Gap +196 (+3.33%)
- Pooja & Decor: Planned 7,356 units | Committed 7,030 units | Gap -326 (-4.43%)
- Snacks & Beverages: Planned 10,116 units | Committed 10,250 units | Gap +134 (+1.32%)
- Sweets & Mithai: Planned 10,290 units | Committed 9,800 units | Gap -490 (-4.76%)
- Total Network: Planned 33,656 units | Committed 33,170 units | Net Gap -486 (-1.44%)

2. Focus SKUs (8 Top Festive Volume SKUs):
- SKU 1 (Kaju Katli 250 g, Sweets): Planned 2,416 | Committed 2,300 | Planned SD 209.51 | Cover Prob 28.99% | Status: Top-up needed | Top-up: 535 units | Shape Flag: OK (mean 1005.58, med 1006.0, gap -0.42)
- SKU 6 (Cashew Nuts 500 g, Dry Fruits): Planned 1,387 | Committed 1,500 | Planned SD 113.98 | Cover Prob 83.93% | Status: Covered | Top-up: 0 units | Shape Flag: OK
- SKU 10 (Potato Chips, Snacks): Planned 3,404 | Committed 3,700 | Planned SD 320.38 | Cover Prob 82.22% | Status: Covered | Top-up: 0 units | Shape Flag: OK
- SKU 11 (Cola 2 L, Snacks): Planned 2,834 | Committed 2,900 | Planned SD 157.64 | Cover Prob 66.23% | Status: Top-up needed | Top-up: 249 units | Shape Flag: OK
- SKU 13 (Diya Set, Pooja): Planned 1,270 | Committed 1,330 | Planned SD 93.29 | Cover Prob 73.99% | Status: Top-up needed | Top-up: 127 units | Shape Flag: OK
- SKU 17 (Incense Sticks, Pooja): Planned 3,215 | Committed 3,200 | Planned SD 206.75 | Cover Prob 47.11% | Status: Top-up needed | Top-up: 429 units | Shape Flag: OK
- SKU 19 (Ghee 1 L, Sweets): Planned 3,289 | Committed 3,100 | Planned SD 293.80 | Cover Prob 26.00% | Status: Top-up needed | Top-up: 777 units | Shape Flag: OK (mean 1368.67, med 1316.0, gap 52.67 vs 0.5*sd 61.14)
- SKU 20 (Dates 500 g, Dry Fruits): Planned 1,703 | Committed 1,900 | Planned SD 126.78 | Cover Prob 93.99% | Status: Covered | Top-up: 0 units | Shape Flag: OK
- Total Top-up required across the 5 exposed SKUs: 2,117 units.

3. Methodology Validation:
- Hold-back test on weeks 85–88 showed baseline projection error within -3.37% to +2.12% across categories.
- Normality test: Zero SKUs flagged as "Review" under shape_flag (|mean - median| <= 0.5 * sd).

CONSTRAINTS:
- Word Limit: Strictly no longer than 250 words across Headline, Context, Insight, and Recommendation combined.
- Grounding: Use ONLY the provided numbers. Do not calculate new numbers or alter any values.
- Benchmarks: Every comparison must name its explicit benchmark (e.g., "committed units vs planned units").
- Professional Tone: No hype words (do not use "skyrocketing", "massive", "disaster", "critical failure").
- Missing Causes: If a cause is not present in the data, write "cause unknown" rather than hypothesizing or inventing operational narratives.
- Shape Flag: State plainly that no SKU is marked Review under the shape_flag rule.
- Recommendations: Every action item must start with an imperative verb, name an owner role, and specify a deadline.

FORMAT:
Markdown format with five specific section headers:
## Headline
## Context
## Insight
## Recommendation
## Limitations
(Limitations is a separate section containing at least three specific analytical limits).
```

---

## 2. First-Draft Problems & Prompt Changes

### Concrete Problem 1: Hype Words & Invented Supply Chain Causes
- **First Draft Behavior:** The initial draft output contained emotive hype words ("massive supply shortfall", "skyrocketing demand spikes") and invented an external operational explanation ("due to Tier-1 fulfillment vendor delivery delays and driver shortages"). None of these operational causes were present in the simulated database.
- **Root Cause in Prompt:** The initial prompt asked the model to "explain why commitments fell short" without restricting external hallucinations.
- **Prompt Change / Fix:** Implemented a negative constraint:
  `"Do not use hype words ('skyrocketing', 'massive', etc.). Where a cause is not directly observed in the data, write 'cause unknown' rather than inventing operational or supply-chain narratives."`

### Concrete Problem 2: Ambiguous Benchmark Comparisons
- **First Draft Behavior:** The initial draft stated: *"Supplier orders trail demand by 486 units (-1.44%) and Sweets & Mithai is down -4.76%."* This phrasing did not state whether the comparison was against last year's sales, last week's sales, or this year's planned units.
- **Root Cause in Prompt:** The prompt lacked an instruction mandating explicit comparison syntax.
- **Prompt Change / Fix:** Added an explicit naming rule in Constraints:
  `"Every comparison must explicitly state what it is measured against (e.g., 'committed units vs planned units')."`

### Concrete Problem 3: Invented Skewness Narrative Contradicting `shape_flag`
- **First Draft Behavior:** The assistant attempted to explain distribution asymmetry, writing: *"Although Ghee 1 L shows positive skew indicating peak demand tail risk..."* In reality, all 8 Focus SKUs passed the `shape_flag` test (`|mean - median| <= 0.5 * sd`), meaning the normality assumption behind `NORM.DIST` was statistically sound.
- **Root Cause in Prompt:** The prompt listed the raw mean and median values without explicitly enforcing that an "OK" flag means no skew issue exists.
- **Prompt Change / Fix:** Added explicit directive:
  `"Check the shape_flag column: since all 8 SKUs have shape_flag OK (maximum mean-minus-median is Ghee at 52.67 units, which is 0.43 × sd < 0.5 × sd), state plainly that no SKU is marked Review and that the normality assumption holds."`

---

## 3. Validation Note

- **Title:** Zepto Festive Demand Plan Decision Memo & Statistical Review Validation
- **Sources:**
  - `zepto_festive.db` (SQLite deterministic database generated with seed 2026)
  - `sku_plan.csv` (Part A plan table export)
  - `focus_weeks.csv` (Part A 92 clean-week focus SKU observations)
  - `python_check_output.txt` (Part B independent verification output)
  - `zepto_festive_demand_plan.xlsx` (Part C Excel model with dynamic formulas and conditional formatting)
- **AI Usage:** AI was utilized exclusively for drafting and refining executive communication prose within strict word and structural constraints. Zero calculations or statistical metrics were generated by AI; all numbers were computed deterministically in SQL, Python, and Excel.
- **Manual Checks Actually Performed:**
  1. *Word Count Verification:* Verified via script that Headline (31 words), Context (58 words), Insight (103 words), and Recommendation (45 words) total exactly 237 words, strictly below the 250-word ceiling.
  2. *Cross-Part Numerical Reconciliation:* Confirmed that all 20 baseline averages, 4 category uplifts, and 8 focus SKU cover probabilities agree across SQL queries (`04_plan.sql`), Python (`cross_check.py`), and Excel (`zepto_festive_demand_plan.xlsx`).
  3. *Excel COM Model Validation:* Programmatically opened the `.xlsx` workbook via Microsoft Excel COM automation, verifying that all `=SUMIF()`, `=AVERAGE()`, `=STDEV()`, `=VLOOKUP()`, and `=NORM.DIST()` formulas compute dynamically without hardcoding, and confirmed conditional formatting rules on column Q (`cover_probability`).
  4. *Hold-back & Stock-out Incidence Check:* Confirmed festive stock-out incidence of 22.50% (18/80) vs regular 6.01% (101/1680), and hold-back errors (-3.37% Dry Fruits, -2.77% Pooja, -1.15% Snacks, +2.12% Sweets).
- **Changes Made:**
  - Condensed four core sections from 276 words to 237 words.
  - Replaced qualitative expressions with precise metrics and explicit benchmarks ("committed units vs planned units").
  - Aligned action recommendations to specific owner roles (Procurement Lead, Fulfillment Ops Lead, Inventory Planning Lead) with concrete pre-season deadlines.
- **Analysis Limits:**
  - Unobserved supplier surge fulfillment capacity and lead-time elasticity under rush reorders (cause unknown).
  - Uniform category uplift applied across all four festive weeks without intra-festive week-on-week temporal modeling.
  - Absence of marketing calendar, promotional discounting, and cross-SKU product substitution data.
