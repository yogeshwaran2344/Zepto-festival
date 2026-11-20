-- Data Verification Results:
-- skus: 21
-- calendar_weeks: 92
-- weekly_sales: 1760
-- committed_orders: 20
-- calendar_weeks by season:
--   Festive: 8
--   Regular: 84

-- 1. Table row counts
SELECT COUNT(*) AS count_skus FROM skus;
SELECT COUNT(*) AS count_calendar_weeks FROM calendar_weeks;
SELECT COUNT(*) AS count_weekly_sales FROM weekly_sales;
SELECT COUNT(*) AS count_committed_orders FROM committed_orders;

-- 2. Calendar weeks breakdown by season
SELECT season, COUNT(*) AS week_count
FROM calendar_weeks
GROUP BY season;
