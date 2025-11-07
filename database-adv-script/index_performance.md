## Test query performance
- Run EXPLAIN ANALYZE before and after adding indexes on sample queries to measure improvement (e.g., reduced sequential scans, lower cost/time).

### STEP 1: Test Query Performance before adding Indexes
- Run EXPLAIN ANALYZE queries to baseline.
-- Example: INNER JOIN bookings and users, filtered by date_start > '2024-01-01', ORDER BY date_start
-- Run: EXPLAIN (ANALYZE TRUE, BUFFERS TRUE) <query>;
/*
EXPLAIN (ANALYZE TRUE)
SELECT
    b.id AS booking_id,
    b.date_start,
    u.first_name
FROM bookings b
INNER JOIN
    users u
    ON b.user_id = u.id
WHERE b.date_start > '2024-01-01'
ORDER BY b.date_start;
-- Placeholder Output (without indexes): Seq Scan on bookings (cost=..., actual time=..., rows=..., loops=1)
-- Total Cost: High (e.g., 10000), Execution Time: ~50ms (full table scan)
*/

### STEP 2: Execute CREATE INDEX sections
Execute the query: \i database_index.sql

### STEP 3: Test Performance
- Re-run the query in STEP 1.
- Monitor: SELECT * FROM pg_stat_user_indexes; for usage stats.
/*
EXPLAIN (ANALYZE TRUE)
SELECT
    b.id AS booking_id,
    b.date_start,
    u.first_name
FROM bookings b
INNER JOIN
    users u
    ON b.user_id = u.id
WHERE b.date_start > '2024-01-01'
ORDER BY b.date_start;
-- Placeholder Output (with indexes): Index Scan using idx_bookings_date_start (cost=..., actual time=..., rows=..., loops=1)
-- Index Scan using idx_bookings_user_id for JOIN (cost=low)
-- Total Cost: Low (e.g., 100), Execution Time: ~5ms (index usage, no full scan)
*/

## Performance Measurement Notes
- Before Indexes: Expect Sequential Scans (high cost, e.g., 10000+; time ~50ms+ on large data).
- After Indexes: Index Scans (low cost, e.g., 100; time ~5ms; 10x+ speedup).
- Use EXPLAIN (ANALYZE TRUE, BUFFERS TRUE) for detailed timing/buffers.
- Real results vary by data size; test with sample data from the repo.
- Indexes add overhead on INSERT/UPDATE; monitor for write-heavy workloads.
