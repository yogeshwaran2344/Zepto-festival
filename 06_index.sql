-- Task 8: Indexing Optimization & Query Plan Analysis

-- 1. Explain Query Plan before creating the index
-- Query Plan Output Before Index:
-- SCAN weekly_sales
EXPLAIN QUERY PLAN 
SELECT * FROM weekly_sales WHERE sku_id = 13;

-- 2. Create index on sku_id
CREATE INDEX IF NOT EXISTS idx_ws_sku ON weekly_sales(sku_id);

-- 3. Explain Query Plan after creating the index
-- Query Plan Output After Index:
-- SEARCH weekly_sales USING INDEX idx_ws_sku (sku_id=?)
EXPLAIN QUERY PLAN 
SELECT * FROM weekly_sales WHERE sku_id = 13;

/*
Index Justification:
The column sku_id is ideally suited for an index because it serves as a foreign key with high selectivity and cardinality, and it is heavily utilized in filtering (WHERE sku_id = ...), table joins (weekly_sales to skus and committed_orders), and aggregation groups (GROUP BY / PARTITION BY sku_id), allowing SQLite to execute fast logarithmic B-Tree lookups rather than scanning all 1,760 rows.
*/
