-- ================================================================
-- File: database_index.sql
-- Project: ALX Airbnb Database - Advanced SQL Scripts
-- Objective: Identify and create indexes to improve query performance.
-- ================================================================

-- ================================================================
-- Step 1: Identify high-usage columns
-- Common columns used in WHERE, JOIN, and ORDER BY clauses:
-- - users: id (PK/JOIN), email (WHERE for login/search)
-- - bookings: user_id (FK/JOIN/WHERE), place_id (FK/JOIN/WHERE), date_start/date_end (WHERE range/ORDER BY)
-- - places: id (PK/JOIN), user_id (FK host JOIN), city (WHERE search)
---- Run EXPLAIN ANALYZE before/after on sample queries to measure improvement (e.g., reduced sequential scans, lower cost/time).

-- ========================================
-- BEFORE: Sample Query Performance (No Indexes)
-- ========================================
-- Example: INNER JOIN bookings and users, filtered by date_start > '2024-01-01', ORDER BY date_start
-- Run: EXPLAIN (ANALYZE TRUE, BUFFERS TRUE) <query>;
/*
EXPLAIN (ANALYZE TRUE) SELECT b.id AS booking_id, b.date_start, u.first_name
FROM bookings b
INNER JOIN users u ON b.user_id = u.id
WHERE b.date_start > '2024-01-01'
ORDER BY b.date_start;
-- Placeholder Output (without indexes): Seq Scan on bookings (cost=..., actual time=..., rows=..., loops=1)
-- Total Cost: High (e.g., 10000), Execution Time: ~50ms (full table scan)
*/

-- ========================================
-- CREATE INDEX STATEMENTS
-- ========================================
-- Index on users.email (for quick user lookups/searches)
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- Index on bookings.user_id (FK for JOINs/WHERE on user bookings)
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings (user_id);

-- Index on bookings.place_id (FK for JOINs/WHERE on property bookings)
CREATE INDEX IF NOT EXISTS idx_bookings_place_id ON bookings (place_id);

-- Index on bookings.date_start (for WHERE >/< and ORDER BY)
CREATE INDEX IF NOT EXISTS idx_bookings_date_start ON bookings (date_start);

-- Index on bookings.date_end (for WHERE range queries)
CREATE INDEX IF NOT EXISTS idx_bookings_date_end ON bookings (date_end);

-- Composite index for common availability check: place_id + date_start (for overlapping date queries)
CREATE INDEX IF NOT EXISTS idx_bookings_place_date ON bookings (place_id, date_start);

-- Index on places.user_id (FK for host-property JOINs)
CREATE INDEX IF NOT EXISTS idx_places_user_id ON places (user_id);

-- Index on places.city (for WHERE city searches)
CREATE INDEX IF NOT EXISTS idx_places_city ON places (city);

-- ========================================
-- AFTER: Sample Query Performance (With Indexes)
-- ========================================
-- Re-run the same query:
-- EXPLAIN (ANALYZE TRUE) SELECT b.id AS booking_id, b.date_start, u.first_name
-- FROM bookings b
-- INNER JOIN users u ON b.user_id = u.id
-- WHERE b.date_start > '2024-01-01'
-- ORDER BY b.date_start;
-- Placeholder Output (with indexes): Index Scan using idx_bookings_date_start (cost=..., actual time=..., rows=..., loops=1)
-- Index Scan using idx_bookings_user_id for JOIN (cost=low)
-- Total Cost: Low (e.g., 100), Execution Time: ~5ms (index usage, no full scan)

-- Additional Test Query: Property bookings by city
/*
EXPLAIN (ANALYZE TRUE) SELECT p.name, COUNT(b.id)
FROM places p
LEFT JOIN bookings b ON p.id = b.place_id
WHERE p.city = 'Paris'
GROUP BY p.id, p.name;
-- Before: Seq Scan (high cost/time)
-- After: Index Scan on idx_places_city + idx_bookings_place_id (low cost/time)
*/

-- Notes:
-- - Use pg_stat_user_indexes to monitor index usage post-deployment.
-- - Vacuum/analyze tables after indexing: VACUUM ANALYZE bookings; VACUUM ANALYZE places; VACUUM ANALYZE users;
-- - Drop unused indexes later if bloat occurs: DROP INDEX IF EXISTS idx_name;
