# Zepto Festive Demand Plan — SQL, Python & Spreadsheet Stocking-Risk Review

A complete, end-to-end demand forecasting, risk quantification, and inventory stocking review for Zepto's upcoming four-week festive season (Weeks 89–92) across 20 SKUs in four core categories:
- **Sweets & Mithai**
- **Dry Fruits & Gifting**
- **Snacks & Beverages**
- **Pooja & Decor**

---

## Executive Summary

Raw historical sales during festive periods are systematically truncated by high stock-out incidence (**22.50%** in festive weeks vs **6.01%** in regular weeks). A planner who relies on unadjusted historical sales under-forecasts demand for the highest-velocity items.

By isolating **clean weeks** (`stockout_days = 0`) to compute true baseline sales (Weeks 77–88) and empirical category uplifts (Weeks 37–40 vs Weeks 25–36), this project establishes:
1. **Network Position:** Total supplier commitments of **33,170 units/week** fall short of planned demand of **33,656 units/week** by **-486 units** (-1.44% committed units vs planned units).
2. **Category Exposure:** Deficits are concentrated in **Sweets & Mithai** (-490 units, -4.76%) and **Pooja & Decor** (-326 units, -4.43%).
3. **Focus SKU Risk:** Among the eight highest-volume festive SKUs, **5 SKUs fall below the 80% coverage threshold**, requiring **2,117 additional top-up units** to achieve 80% stock-out protection (Ghee 1 L: +777; Kaju Katli 250 g: +535; Incense Sticks: +429; Cola 2 L: +249; Diya Set: +127).

---

## Repository Structure

```text
.
├── generate_data.py               # Deterministic SQLite database generator (seed 2026)
├── zepto_festive.db               # SQLite database with 88 weeks of sales history
├── verify.sql                     # Row count & season distribution verification queries
├── 01_foundations.sql             # SQL foundation queries (WHERE, DISTINCT, IN, BETWEEN, LIKE, IS NULL, ROUND)
├── 02_aggregation_joins.sql       # Aggregation, joins, and seasonal stock-out incidence CTEs
├── 03_ranking_windows.sql         # Focus list ranking (ROW_NUMBER) and running totals (SUM OVER)
├── 04_plan.sql                    # Demand plan generation, clean-week export queries, and bias analysis
├── 05_holdback.sql                # Out-of-sample hold-back validation query (Weeks 85-88)
├── 06_index.sql                   # EXPLAIN QUERY PLAN before and after B-Tree index creation
├── sku_plan.csv                   # Exported 20-SKU baseline & uplift plan table
├── focus_weeks.csv                # Exported 92 clean-week historical observations for 8 Focus SKUs
├── cross_check.py                 # Pure Python independent cross-check script
├── python_check_output.txt        # Output transcript of Python cross-check (ALL CHECKS PASSED)
├── zepto_festive_demand_plan.xlsx # Comprehensive Excel review model with live formulas & conditional formatting
├── docs/
│   └── decision_memo.md           # Executive decision memo (<=250 words across core sections)
├── ai_log.md                      # AI prompt engineering, error correction log, and validation note
└── README.md                      # Project documentation and reproduction guide
```

---

## Reproduction & Validation Guide

### 1. Database Generation & SQL Verification
Run the database generator:
```bash
python generate_data.py
```
Outputs `zepto_festive.db` containing:
- `skus`: 21 rows
- `calendar_weeks`: 92 rows (8 Festive, 84 Regular)
- `weekly_sales`: 1,760 rows
- `committed_orders`: 20 rows

Execute SQL scripts with SQLite:
```bash
sqlite3 zepto_festive.db < verify.sql
sqlite3 zepto_festive.db < 01_foundations.sql
sqlite3 zepto_festive.db < 02_aggregation_joins.sql
sqlite3 zepto_festive.db < 03_ranking_windows.sql
sqlite3 zepto_festive.db < 04_plan.sql
sqlite3 zepto_festive.db < 05_holdback.sql
sqlite3 zepto_festive.db < 06_index.sql
```

### 2. Independent Python Cross-Check
Re-derive all baselines, seasonal stock-out incidence, and category uplifts using pure Python:
```bash
python cross_check.py > python_check_output.txt
```
All 20 SKU baselines, both seasons (Festive 22.50%, Regular 6.01%), and all 4 category uplifts pass validation, concluding with `ALL CHECKS PASSED`.

### 3. Spreadsheet Model (`zepto_festive_demand_plan.xlsx`)
Contains four integrated worksheets:
- `Plan`: Exact 20-row import of `sku_plan.csv`.
- `Focus Weeks`: Exact 92-row import of `focus_weeks.csv`.
- `Category View`: Category-level aggregation with dynamic `=SUMIF()` formulas and net gap analysis.
- `Focus Stats`: Statistical evaluation for all 8 Focus SKUs using dynamic formulas:
  - `=AVERAGE()`, `=MEDIAN()`, `=STDEV()`, `=SQRT()`, `=VLOOKUP()`
  - Cover probability calculated via `=NORM.DIST(committed, planned, planned_sd, TRUE)`
  - Two-tone conditional formatting on cover probability (soft green for $\ge 80\%$, soft red for $< 80\%$)
  - Reconciliation column `Matches Part A?` reading `Yes` across all 8 SKUs.

---

## Key Results Summary Table

| SKU ID | SKU Name | Category | Planned Weekly Units | Committed Weekly Units | Planned SD | Cover Probability | Status | Top-up Units | Shape Flag | Matches Part A? |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Kaju Katli 250 g | Sweets & Mithai | 2,416 | 2,300 | 209.51 | 28.99% | Top-up needed | 535 | OK | Yes |
| 6 | Cashew Nuts 500 g | Dry Fruits & Gifting | 1,387 | 1,500 | 113.98 | 83.93% | Covered | 0 | OK | Yes |
| 10 | Potato Chips Family Pack | Snacks & Beverages | 3,404 | 3,700 | 320.38 | 82.22% | Covered | 0 | OK | Yes |
| 11 | Cola 2 L | Snacks & Beverages | 2,834 | 2,900 | 157.64 | 66.23% | Top-up needed | 249 | OK | Yes |
| 13 | Diya Set (12 pcs) | Pooja & Decor | 1,270 | 1,330 | 93.29 | 73.99% | Top-up needed | 127 | OK | Yes |
| 17 | Incense Sticks (6 packs) | Pooja & Decor | 3,215 | 3,200 | 206.75 | 47.11% | Top-up needed | 429 | OK | Yes |
| 19 | Ghee 1 L | Sweets & Mithai | 3,289 | 3,100 | 293.80 | 26.00% | Top-up needed | 777 | OK | Yes |
| 20 | Dates 500 g | Dry Fruits & Gifting | 1,703 | 1,900 | 126.78 | 93.99% | Covered | 0 | OK | Yes |
| **Total** | | | **19,518** | **19,930** | — | — | **3 Covered / 5 Top-up** | **2,117** | **All OK** | **8 / 8 Yes** |
