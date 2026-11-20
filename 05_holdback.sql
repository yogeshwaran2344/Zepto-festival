-- Task 7: Hold-Back Validation Check
-- Tests baseline prediction methodology on weeks 85-88 using clean baseline from weeks 73-84.
-- Target output:
-- Dry Fruits & Gifting: 5 SKUs, -3.37%
-- Pooja & Decor: 6 SKUs, -2.77%
-- Snacks & Beverages: 4 SKUs, -1.15%
-- Sweets & Mithai: 5 SKUs, 2.12%

WITH baseline_73_84 AS (
    SELECT 
        sku_id,
        AVG(units_sold) AS baseline
    FROM weekly_sales
    WHERE week_no BETWEEN 73 AND 84
      AND stockout_days = 0
    GROUP BY sku_id
),
actual_85_88 AS (
    SELECT 
        sku_id,
        AVG(units_sold) AS actual
    FROM weekly_sales
    WHERE week_no BETWEEN 85 AND 88
    GROUP BY sku_id
),
sku_gaps AS (
    SELECT 
        s.sku_id,
        s.category,
        b.baseline,
        a.actual,
        (a.actual - b.baseline) * 100.0 / b.baseline AS gap_pct
    FROM skus s
    JOIN baseline_73_84 b ON s.sku_id = b.sku_id
    JOIN actual_85_88 a ON s.sku_id = a.sku_id
)
SELECT 
    category,
    COUNT(*) AS num_skus,
    ROUND(AVG(gap_pct), 2) AS avg_gap_pct
FROM sku_gaps
GROUP BY category
ORDER BY category;
