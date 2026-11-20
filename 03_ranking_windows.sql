-- Task 5: Ranking and Window Functions

-- (a) The Focus List — top 2 SKUs in each category by total units_sold across weeks 37–40
WITH sku_festive_totals AS (
    SELECT 
        s.sku_id,
        s.sku_name,
        s.category,
        SUM(w.units_sold) AS total_festive_units,
        ROW_NUMBER() OVER (
            PARTITION BY s.category 
            ORDER BY SUM(w.units_sold) DESC
        ) AS rnk
    FROM weekly_sales w
    JOIN skus s ON w.sku_id = s.sku_id
    WHERE w.week_no BETWEEN 37 AND 40
    GROUP BY s.sku_id, s.sku_name, s.category
)
SELECT 
    sku_id,
    sku_name,
    category,
    total_festive_units,
    rnk
FROM sku_festive_totals
WHERE rnk <= 2
ORDER BY category, rnk;

-- (b) Running total: for category Sweets & Mithai only, network units_sold per week for weeks 33–40
WITH weekly_sweets AS (
    SELECT 
        w.week_no,
        SUM(w.units_sold) AS units
    FROM weekly_sales w
    JOIN skus s ON w.sku_id = s.sku_id
    WHERE s.category = 'Sweets & Mithai'
      AND w.week_no BETWEEN 33 AND 40
    GROUP BY w.week_no
)
SELECT 
    week_no,
    units,
    SUM(units) OVER (ORDER BY week_no) AS running_units
FROM weekly_sweets
ORDER BY week_no;
