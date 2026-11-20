-- Task 6: Plan Table and Exports

-- (a) Plan Table Query
-- CTEs: pre-festive baseline (weeks 25-36), festive weeks (weeks 37-40),
-- SKU-level uplift, category uplift, and current baseline (weeks 77-88).
-- Exported to sku_plan.csv (ordered by sku_id).
WITH pre_festive AS (
    SELECT 
        sku_id, 
        AVG(units_sold) AS pre_avg
    FROM weekly_sales
    WHERE week_no BETWEEN 25 AND 36
      AND stockout_days = 0
    GROUP BY sku_id
),
festive AS (
    SELECT 
        sku_id, 
        AVG(units_sold) AS fest_avg
    FROM weekly_sales
    WHERE week_no BETWEEN 37 AND 40
      AND stockout_days = 0
    GROUP BY sku_id
),
sku_uplift AS (
    SELECT 
        s.sku_id,
        s.category,
        (f.fest_avg * 1.0 / p.pre_avg) AS uplift
    FROM skus s
    JOIN pre_festive p ON s.sku_id = p.sku_id
    JOIN festive f ON s.sku_id = f.sku_id
),
category_uplift_cte AS (
    SELECT 
        category,
        ROUND(AVG(uplift), 4) AS category_uplift
    FROM sku_uplift
    GROUP BY category
),
current_baseline AS (
    SELECT 
        sku_id,
        COUNT(*) AS clean_weeks,
        ROUND(AVG(units_sold), 2) AS baseline_units
    FROM weekly_sales
    WHERE week_no BETWEEN 77 AND 88
      AND stockout_days = 0
    GROUP BY sku_id
)
SELECT 
    s.sku_id,
    s.sku_name,
    s.category,
    cb.clean_weeks,
    cb.baseline_units,
    cu.category_uplift,
    ROUND(cb.baseline_units * cu.category_uplift, 0) AS planned_weekly_units,
    co.committed_weekly_units
FROM skus s
JOIN current_baseline cb ON s.sku_id = cb.sku_id
JOIN category_uplift_cte cu ON s.category = cu.category
JOIN committed_orders co ON s.sku_id = co.sku_id
ORDER BY s.sku_id;

-- (b) Clean rows of the 8 Focus-List SKUs for weeks 77–88
-- Exported to focus_weeks.csv (ordered by sku_id, then week_no).
WITH focus_list AS (
    SELECT sku_id
    FROM (
        SELECT 
            s.sku_id,
            ROW_NUMBER() OVER (
                PARTITION BY s.category 
                ORDER BY SUM(w.units_sold) DESC
            ) AS rnk
        FROM weekly_sales w
        JOIN skus s ON w.sku_id = s.sku_id
        WHERE w.week_no BETWEEN 37 AND 40
        GROUP BY s.sku_id, s.category
    )
    WHERE rnk <= 2
)
SELECT 
    w.week_no,
    w.sku_id,
    s.sku_name,
    s.category,
    w.units_sold
FROM weekly_sales w
JOIN skus s ON w.sku_id = s.sku_id
WHERE w.sku_id IN (SELECT sku_id FROM focus_list)
  AND w.week_no BETWEEN 77 AND 88
  AND w.stockout_days = 0
ORDER BY w.sku_id, w.week_no;

-- (c) Category Uplift recomputed without filtering for clean weeks (all weeks count)
WITH pre_festive_all AS (
    SELECT 
        sku_id, 
        AVG(units_sold) AS pre_avg
    FROM weekly_sales
    WHERE week_no BETWEEN 25 AND 36
    GROUP BY sku_id
),
festive_all AS (
    SELECT 
        sku_id, 
        AVG(units_sold) AS fest_avg
    FROM weekly_sales
    WHERE week_no BETWEEN 37 AND 40
    GROUP BY sku_id
),
sku_uplift_all AS (
    SELECT 
        s.sku_id,
        s.category,
        (f.fest_avg * 1.0 / p.pre_avg) AS uplift
    FROM skus s
    JOIN pre_festive_all p ON s.sku_id = p.sku_id
    JOIN festive_all f ON s.sku_id = f.sku_id
)
SELECT 
    category,
    ROUND(AVG(uplift), 4) AS category_uplift_all_weeks
FROM sku_uplift_all
GROUP BY category
ORDER BY category;

/*
Comparison of Category Uplifts:
---------------------------------------------------------------------------------------------------------
Category                Clean-Week Uplift (Task 6a)     All-Weeks Uplift (Task 6c)     Difference (Bias)
---------------------------------------------------------------------------------------------------------
Dry Fruits & Gifting    2.0771                          2.0073                         -0.0698
Pooja & Decor           3.0651                          2.8552                         -0.2099
Snacks & Beverages      1.4270                          1.3723                         -0.0547
Sweets & Mithai         2.4028                          2.2939                         -0.1089
---------------------------------------------------------------------------------------------------------

Explanation:
The all-weeks uplifts are consistently lower across every single category compared to clean-week uplifts.
This occurs because festive weeks experience a significantly higher stock-out incidence (22.50%) than regular 
pre-festive weeks (6.01%). When a SKU stocks out for 1 to 3 days in a festive week, recorded sales truncate 
true consumer demand. Averaging all rows without filtering out stock-out days depresses festive average sales 
far more than pre-festive sales, artificially attenuating the computed ratio (festive / pre-festive). 
Filtering to clean weeks (stockout_days = 0) corrects for unfulfilled demand during stock-out periods and reveals 
the true underlying demand uplift.
*/
