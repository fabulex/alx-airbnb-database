-- ============================================================
-- File: partitioning.sql
-- Project: ALX Airbnb Database - Advanced SQL Optimization
-- Objective: Implement table partitioning on the bookings table
--            to improve query performance on large datasets.
-- ============================================================

-- ============================================================
-- OVERVIEW
-- The 'bookings' table can grow large as user activity increases.
-- Partitioning by 'start_date' allows PostgreSQL to prune irrelevant
-- partitions during date-range queries, reducing I/O and execution time.
--
-- This script includes:
--   1️⃣ Default: YEARLY partitioning (simple, ALX-friendly)
--   2️⃣ Optional: MONTHLY partitioning (advanced, production-ready)
-- ============================================================

-- Backup existing data before running in production!
-- Example:
CREATE TABLE bookings_backup AS SELECT * FROM bookings;

DROP TABLE IF EXISTS bookings CASCADE;

-- ============================================================
-- STEP 1: Create Parent Partitioned Table
-- ============================================================
CREATE TABLE bookings (
    id SERIAL,
    user_id INTEGER NOT NULL,
    place_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50),
    total_price NUMERIC(10,2),
    PRIMARY KEY (id, start_date)
) PARTITION BY RANGE (start_date);

-- ============================================================
-- STEP 2A: YEARLY PARTITIONING (Default for ALX Project)
-- ============================================================

-- Each partition stores one year’s worth of bookings.
-- Simple, easy to maintain, and ideal for demonstration purposes.

CREATE TABLE bookings_2023 PARTITION OF bookings
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE bookings_2024 PARTITION OF bookings
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE bookings_2025 PARTITION OF bookings
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- ============================================================
-- STEP 2B (Optional): MONTHLY PARTITIONING (Advanced)
-- ============================================================
-- Uncomment this section if you want finer-grained partitions
-- for large datasets or high-frequency date queries.

-- CREATE TABLE bookings_2025_01 PARTITION OF bookings
--     FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
-- CREATE TABLE bookings_2025_02 PARTITION OF bookings
--     FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- CREATE TABLE bookings_2025_03 PARTITION OF bookings
--     FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
-- CREATE TABLE bookings_2025_04 PARTITION OF bookings
--     FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
-- CREATE TABLE bookings_2025_05 PARTITION OF bookings
--     FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
-- CREATE TABLE bookings_2025_06 PARTITION OF bookings
--     FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
-- CREATE TABLE bookings_2025_07 PARTITION OF bookings
--     FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
-- CREATE TABLE bookings_2025_08 PARTITION OF bookings
--     FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
-- CREATE TABLE bookings_2025_09 PARTITION OF bookings
--     FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
-- CREATE TABLE bookings_2025_10 PARTITION OF bookings
--     FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
-- CREATE TABLE bookings_2025_11 PARTITION OF bookings
--     FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
-- CREATE TABLE bookings_2025_12 PARTITION OF bookings
--     FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- ============================================================
-- STEP 3: Indexing for Performance
-- ============================================================
-- Create indexes on frequently queried columns.
-- Note: PostgreSQL 15+ supports global indexes; otherwise, define per-partition.

CREATE INDEX idx_bookings_user_id ON bookings (user_id);
CREATE INDEX idx_bookings_place_id ON bookings (place_id);
CREATE INDEX idx_bookings_end_date ON bookings (end_date);

-- ============================================================
-- STEP 4: Data Migration (if applicable)
-- ============================================================
-- INSERT INTO bookings SELECT * FROM bookings_backup;
-- DROP TABLE bookings_backup;

-- ============================================================
-- STEP 5: Performance Testing
-- ============================================================
-- Use EXPLAIN or ANALYZE to compare before and after partitioning.

-- Example test:
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM bookings
-- WHERE start_date BETWEEN '2025-01-01' AND '2025-03-31';

-- Expected result (example comparison):
-- BEFORE (unpartitioned):
--   Seq Scan on bookings (cost=0..100000) rows=250k time=5500 ms
--
-- AFTER (partitioned, pruned to 3 partitions):
--   Append (cost=0..5000) rows=250k time≈250 ms (≈22x faster)
--
-- Notes:
--  - PostgreSQL automatically prunes irrelevant partitions.
--  - Insert/update cost remains low.
--  - You can detach old partitions for archiving (ALTER TABLE DETACH PARTITION).
-- - Run VACUUM ANALYZE bookings; after setup.
-- ============================================================

-- End of partitioning.sql
