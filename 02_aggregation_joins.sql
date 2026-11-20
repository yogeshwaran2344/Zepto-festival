-- Task 4: Aggregation and Joins

-- (a) INNER JOIN of weekly_sales to skus, GROUP BY category, returning total_units and total_stockout_days, HAVING SUM(units_sold) > 300000, ordered by total_units descending
SELECT 
    s.category,
    SUM(w.units_sold) AS total_units,
    SUM(w.stockout_days) AS total_stockout_days
FROM weekly_sales w
INNER JOIN skus s ON w.sku_id = s.sku_id
GROUP BY s.category
HAVING SUM(w.units_sold) > 300000
ORDER BY total_units DESC;

-- (b) LEFT JOIN of skus to weekly_sales, GROUP BY SKU, returning COUNT(w.week_no) AS sku_weeks, ordered ascending
SELECT 
    s.sku_id,
    s.sku_name,
    COUNT(w.week_no) AS sku_weeks
FROM skus s
LEFT JOIN weekly_sales w ON s.sku_id = w.sku_id
GROUP BY s.sku_id, s.sku_name
ORDER BY sku_weeks ASC, s.sku_id ASC;

-- (c) Stock-out incidence by season using two CTEs and a JOIN to calendar_weeks
WITH season_weeks AS (
    SELECT 
        w.week_no,
        w.sku_id,
        w.stockout_days,
        c.season
    FROM weekly_sales w
    JOIN calendar_weeks c ON w.week_no = c.week_no
),
season_summary AS (
    SELECT 
        season,
        COUNT(*) AS total_sku_weeks,
        SUM(CASE WHEN stockout_days > 0 THEN 1 ELSE 0 END) AS affected_sku_weeks
    FROM season_weeks
    GROUP BY season
)
SELECT 
    season,
    total_sku_weeks,
    affected_sku_weeks,
    ROUND(affected_sku_weeks * 100.0 / total_sku_weeks, 2) AS incidence_pct
FROM season_summary
ORDER BY season;
