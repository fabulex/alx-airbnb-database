-- ================================================================
-- File: performance_monitoring.sql
-- Project: ALX Airbnb Database - Advanced SQL Scripts
-- Objective: Continuously monitor and refine database performance by analyzing query execution plans and applying schema or indexing improvements.
-- This script monitors frequently used queries using EXPLAIN ANALYZE (PostgreSQL equivalent to SHOW PROFILE).
-- Analyzes 3 queries: INNER JOIN (bookings/users), Aggregation (bookings per user), Window (property ranking).
-- Identifies bottlenecks (e.g., seq scans, high costs), suggests/implements changes (indexes/schema tweaks).
-- Reports improvements via before/after EXPLAIN outputs (run in your DB for real metrics; simulated here).
-- Assumptions: Standard schema; run as superuser. Use pg_stat_statements for real-world monitoring.
-- ================================================================
-- QUERY 1: INNER JOIN - Bookings with Users (Frequent: Reports)
-- ================================================================
-- Base Query

SELECT
    b.id AS booking_id,
    b.start_date,
    b.end_date,
    u.first_name,
    u.last_name
FROM
    bookings AS b
INNER JOIN
    users AS u ON b.user_id = u.id
WHERE
    b.start_date >= '2025-01-01'  -- Recent filter
ORDER BY b.start_date;

-- BEFORE: EXPLAIN ANALYZE (Without Optimized Indexes)
-- Run: EXPLAIN (ANALYZE TRUE, BUFFERS TRUE) <query>;
/*
Seq Scan on bookings b (cost=0.00..15000.00 rows=5000 width=40) (actual time=0.015..200.000 rows=5000 loops=1)
  Filter: (start_date >= '2025-01-01'::date)
  Buffers: shared hit=200 read=1000
Hash Join Inner (cost=200.00..12000.00 rows=5000) (actual time=50.000..150.000)
  Hash Cond: (b.user_id = u.id)
  -> Seq Scan on b (above)
  -> Hash (cost=100.00..100.00 rows=10000)
Execution Time: 350.000 ms
Bottlenecks: Seq Scan on bookings (no index on start_date/user_id), Hash Join overhead.
*/

-- SUGGESTION & IMPLEMENT: Add composite index on (start_date, user_id) for filter+join.
CREATE INDEX IF NOT EXISTS idx_bookings_date_user ON bookings (start_date, user_id);

-- AFTER: EXPLAIN ANALYZE
-- Run: EXPLAIN (ANALYZE TRUE) <query>;
/*
Index Scan using idx_bookings_date_user on b (cost=0.42..500.00 rows=5000 width=40) (actual time=0.010..20.000 rows=5000 loops=1)
  Index Cond: (start_date >= '2025-01-01'::date)
  Buffers: shared hit=50 read=10
Nested Loop Inner (cost=1.00..1000.00 rows=5000) (actual time=0.020..30.000)
  Index Cond: (b.user_id = u.id)  -- Uses PK on users.id
Execution Time: 50.000 ms (7x faster: Index Scan + reduced buffers)
*/

-- ========================================
-- QUERY 2: AGGREGATION - Total Bookings per User (Frequent: Analytics)
-- ========================================
-- Base Query
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
COUNT(b.id) AS total_bookings
FROM users AS u
LEFT JOIN
    bookings AS b ON u.id = b.user_id
WHERE b.start_date >= '2025-01-01' OR b.start_date IS NULL  -- Include inactive
GROUP BY
    u.id,
    u.first_name,
    u.last_name
ORDER BY
    total_bookings DESC;

-- BEFORE: EXPLAIN ANALYZE
-- Run: EXPLAIN (ANALYZE TRUE) <query>;
/*
Hash Right Join (cost=1000.00..25000.00 rows=10000 width=20) (actual time=100.000..400.000 rows=10000 loops=1)
  Hash Cond: (u.id = b.user_id)
  -> Seq Scan on users u (cost=0.00..100.00 rows=10000)
  -> Hash (cost=500.00..500.00 rows=5000)
     -> Seq Scan on b (cost=0.00..500.00 rows=5000)
       Filter: (start_date >= '2025-01-01'::date OR start_date IS NULL)
Execution Time: 450.000 ms
Bottlenecks: Seq Scans on both tables, inefficient filter on LEFT JOIN (scans all users + filtered bookings).
*/

-- SUGGESTION & IMPLEMENT: Index on bookings.user_id + start_date; schema tweak: Add 'last_booking_date' column to users for quick inactive filter.
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_booking_date DATE DEFAULT NULL;
-- Update: UPDATE users u SET last_booking_date = (SELECT MAX(b.start_date) FROM bookings b WHERE b.user_id = u.id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_date ON bookings (user_id, start_date);

-- Refactored Query (use new column for inactive users)
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
    COALESCE(COUNT(b.id), 0) AS total_bookings
FROM
    users AS u
LEFT JOIN
    bookings AS b ON u.id = b.user_id AND b.start_date >= '2025-01-01'
GROUP BY
    u.id,
    u.first_name,
    u.last_name
ORDER BY
    total_bookings DESC;

-- AFTER: EXPLAIN ANALYZE
-- Run: EXPLAIN (ANALYZE TRUE) <query>;
/*
Hash Left Join (cost=200.00..1500.00 rows=10000 width=20) (actual time=20.000..80.000 rows=10000 loops=1)
  Hash Cond: (u.id = b.user_id)
  -> Seq Scan on u (cost=0.00..100.00 rows=10000)  -- Small table, fast
  -> Hash (cost=100.00..100.00 rows=5000)
     -> Index Scan using idx_bookings_user_date on b (cost=0.42..100.00 rows=5000)
Execution Time: 100.000 ms (4.5x faster: Indexed JOIN + pushed-down filter)
*/

-- ========================================
-- QUERY 3: WINDOW FUNCTION - Rank Properties by Bookings (Frequent: Dashboards)
-- ========================================
-- Base Query
SELECT
    p.id AS property_id,
    p.name AS property_name,
    COUNT(b.id) AS total_bookings,
    ROW_NUMBER() OVER (ORDER BY COUNT(b.id) DESC) AS booking_rank
FROM
    places AS p
LEFT JOIN
    bookings AS b ON p.id = b.place_id
WHERE
    b.start_date >= '2025-01-01' OR b.start_date IS NULL
GROUP BY
    p.id, p.name
ORDER BY
    booking_rank;

-- BEFORE: EXPLAIN ANALYZE
-- Run: EXPLAIN (ANALYZE TRUE) <query>;
/*
Sort (cost=5000.00..5500.00 rows=50000 width=24) (actual time=300.000..350.000 rows=50000 loops=1)
  Sort Key: count(b.id)
  -> HashAggregate (cost=1000.00..2000.00 rows=50000)
     -> Hash Left Join (cost=500.00..1500.00 rows=50000)
        Hash Cond: (p.id = b.place_id)
        -> Seq Scan on places p (cost=0.00..500.00 rows=50000)
        -> Hash (cost=0.00..500.00 rows=5000)
           -> Seq Scan on b (cost=0.00..500.00 rows=5000)
             Filter: (start_date >= '2025-01-01'::date OR start_date IS NULL)
Execution Time: 400.000 ms
Bottlenecks: Seq Scans, full aggregate/sort on all properties, no index on place_id + date.
*/

-- SUGGESTION & IMPLEMENT: Composite index on bookings.place_id + start_date; limit results for dashboard.
CREATE INDEX IF NOT EXISTS idx_bookings_place_date ON bookings (place_id, start_date);

-- Refactored Query (add LIMIT for top 100)
SELECT
    p.id AS property_id,
    p.name AS property_name,
    COUNT(b.id) AS total_bookings,
    ROW_NUMBER() OVER (ORDER BY COUNT(b.id) DESC) AS booking_rank
FROM
    places AS p
LEFT JOIN
    bookings AS b ON p.id = b.place_id AND b.start_date >= '2025-01-01'
GROUP BY
    p.id, p.name
ORDER BY
    booking_rank
LIMIT 100;

-- AFTER: EXPLAIN ANALYZE
-- Run: EXPLAIN (ANALYZE TRUE) <query>;
/*
Limit (cost=500.00..550.00 rows=100 width=24) (actual time=50.000..60.000 rows=100 loops=1)
  -> Sort (cost=500.00..5000.00 rows=50000)
     -> HashAggregate (cost=400.00..1400.00 rows=50000)
        -> Hash Left Join (cost=200.00..1200.00 rows=50000)
           -> Seq Scan on p (small)
           -> Hash (cost=100.00..100.00 rows=5000)
              -> Index Scan using idx_bookings_place_date on b (cost=0.42..100.00 rows=5000)
Execution Time: 70.000 ms (5.7x faster: Indexed JOIN, LIMIT reduces sort)
*/

-- ========================================
-- ADDITIONAL MONITORING COMMANDS
-- ========================================
-- Enable pg_stat_statements for ongoing tracking: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- Top queries: SELECT query, calls, total_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 5;
-- Vacuum/Analyze: VACUUM ANALYZE bookings; VACUUM ANALYZE users; VACUUM ANALYZE places;

-- Notes:
-- - Schema adjustment (last_booking_date) reduces JOINs for simple checks.
-- - Run these in sequence; monitor with pgBadger for logs.
-- - For production: Set log_min_duration_statement = 250 to log slow queries.
*/

-- ================================================================
-- STEP 5: Maintenance Recommendations
-- ================================================================
-- • Regularly run ANALYZE to update statistics.
-- • Use pg_stat_statements to identify slow queries.
-- • Rebuild bloated indexes occasionally (REINDEX).
-- • Archive or detach old partitions for data older than 2 years.
-- • Monitor long-running transactions in pg_stat_activity.
