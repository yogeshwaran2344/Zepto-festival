import sqlite3

def fetch_rows(sql):
    conn = sqlite3.connect("zepto_festive.db")
    conn.row_factory = sqlite3.Row
    rows = [dict(r) for r in conn.execute(sql).fetchall()]
    conn.close()
    return rows

# ---- write your code below this line ----

# 1. Load rows using the specified query
rows = fetch_rows("""
SELECT w.week_no, w.sku_id, s.category, w.units_sold, w.stockout_days, c.season
FROM weekly_sales w
JOIN skus s ON w.sku_id = s.sku_id
JOIN calendar_weeks c ON w.week_no = c.week_no
""")

# 2. Define helper functions
def clean_values(rows, sku_id, first_week, last_week):
    """Returns a list of units_sold for that SKU's clean weeks (stockout_days == 0) between the two week numbers inclusive."""
    vals = []
    for r in rows:
        if r["sku_id"] == sku_id and first_week <= r["week_no"] <= last_week and r["stockout_days"] == 0:
            vals.append(r["units_sold"])
    return vals

def mean_of(values):
    """Returns the average of a list using sum and len."""
    if not values:
        return 0.0
    return sum(values) / len(values)

failures = 0
lines = []

# 3. Extract distinct SKU IDs and mapping to category
sku_ids = []
sku_to_cat = {}
for r in rows:
    sid = r["sku_id"]
    if sid not in sku_to_cat:
        sku_to_cat[sid] = r["category"]
        sku_ids.append(sid)
sku_ids.sort()

# 4. Cross-check every baseline
sql_baselines = fetch_rows("""
SELECT sku_id, ROUND(AVG(units_sold), 2) AS b FROM weekly_sales
WHERE week_no BETWEEN 77 AND 88 AND stockout_days = 0 GROUP BY sku_id
""")
sql_baseline_map = {r["sku_id"]: r["b"] for r in sql_baselines}

for sid in sku_ids:
    vals = clean_values(rows, sid, 77, 88)
    n_clean = len(vals)
    py_baseline = round(mean_of(vals), 2)
    sql_b = sql_baseline_map.get(sid)
    
    if py_baseline == sql_b:
        status = "OK"
    else:
        status = "MISMATCH"
        failures += 1
    lines.append(f"SKU {sid} | clean weeks {n_clean} | baseline {py_baseline} | SQL {sql_b} | {status}")

# 5. Cross-check stock-out incidence
# Target: Festive 22.5%, Regular 6.01%
season_total = {}
season_stockout = {}
for r in rows:
    s = r["season"]
    season_total[s] = season_total.get(s, 0) + 1
    if r["stockout_days"] > 0:
        season_stockout[s] = season_stockout.get(s, 0) + 1

target_incidence = {
    "Festive": 22.5,
    "Regular": 6.01
}

for s in sorted(season_total.keys()):
    tot = season_total[s]
    aff = season_stockout.get(s, 0)
    inc_pct = round(aff * 100.0 / tot, 2)
    
    # Check against Task 4(c) result
    tgt = target_incidence.get(s)
    if inc_pct != tgt:
        failures += 1
    lines.append(f"{s} | stock-out incidence {inc_pct}%")

# 6. Cross-check category uplift
cat_uplifts_py = {}
for sid in sku_ids:
    pre_vals = clean_values(rows, sid, 25, 36)
    fest_vals = clean_values(rows, sid, 37, 40)
    if len(pre_vals) > 0 and len(fest_vals) > 0:
        pre_mean = mean_of(pre_vals)
        fest_mean = mean_of(fest_vals)
        sku_uplift = fest_mean / pre_mean
        cat = sku_to_cat[sid]
        if cat not in cat_uplifts_py:
            cat_uplifts_py[cat] = []
        cat_uplifts_py[cat].append(sku_uplift)

sql_uplifts = fetch_rows("""
WITH bp AS (SELECT sku_id, AVG(units_sold) AS a FROM weekly_sales WHERE week_no BETWEEN 25 AND 36 AND stockout_days = 0 GROUP BY sku_id),
fp AS (SELECT sku_id, AVG(units_sold) AS a FROM weekly_sales WHERE week_no BETWEEN 37 AND 40 AND stockout_days = 0 GROUP BY sku_id)
SELECT s.category, AVG(fp.a / bp.a) AS u FROM skus s JOIN bp ON s.sku_id = bp.sku_id JOIN fp ON s.sku_id = fp.sku_id GROUP BY s.category
""")
sql_uplift_map = {r["category"]: r["u"] for r in sql_uplifts}

for cat in sorted(cat_uplifts_py.keys()):
    py_u_raw = mean_of(cat_uplifts_py[cat])
    py_u = round(py_u_raw, 4)
    sql_u_raw = sql_uplift_map[cat]
    sql_u = round(sql_u_raw, 4)
    
    diff = abs(py_u_raw - sql_u_raw)
    if diff < 0.0001:
        status = "OK"
    else:
        status = "MISMATCH"
        failures += 1
    lines.append(f"{cat} | uplift {py_u} | SQL {sql_u} | {status}")

# 7. Final status
if failures == 0:
    lines.append("ALL CHECKS PASSED")
else:
    lines.append(f"CHECKS FAILED: {failures}")

print("\n".join(lines))
