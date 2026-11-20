-- Task 3: Foundational Queries

-- (a) WHERE — SKUs in the Pooja & Decor category
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
WHERE category = 'Pooja & Decor';

-- (b) DISTINCT — the list of categories
SELECT DISTINCT category
FROM skus;

-- (c) ORDER BY + LIMIT — the 3 highest-priced SKUs
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
ORDER BY unit_price_inr DESC
LIMIT 3;

-- (d) IN — SKUs whose category is either Sweets & Mithai or Pooja & Decor
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
WHERE category IN ('Sweets & Mithai', 'Pooja & Decor');

-- (e) BETWEEN — SKUs priced from 100 to 300 INR inclusive
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
WHERE unit_price_inr BETWEEN 100 AND 300;

-- (f) LIKE with % — SKUs whose name contains Box
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
WHERE sku_name LIKE '%Box%';

-- (g) IS NULL — SKUs with no confirmed lead_time_days
SELECT sku_id, sku_name, category, unit_price_inr, lead_time_days
FROM skus
WHERE lead_time_days IS NULL;

-- (h) A temporary column with an alias and ROUND — each SKU's name, price and ROUND(unit_price_inr * 0.18, 2) AS tax_amount
SELECT sku_name, unit_price_inr, ROUND(unit_price_inr * 0.18, 2) AS tax_amount
FROM skus;
