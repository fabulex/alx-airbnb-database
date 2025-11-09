# ALX Airbnb Database: Query Performance Testing

This guide walks through measuring and improving query performance by testing before and after adding indexes.

---

## Overview

* Use `EXPLAIN ANALYZE` to measure query performance.
* Compare baseline (without indexes) versus optimized (with indexes) results.
* Goal: Reduce sequential scans, lower cost and execution time.

---

## STEP 1: Test Query Performance Before Adding Indexes

Run `EXPLAIN ANALYZE` queries to establish a baseline.

**Example Query:** INNER JOIN bookings and users, filtered by `date_start > '2024-01-01'`, ordered by `date_start`.

```sql
EXPLAIN (ANALYZE TRUE, BUFFERS TRUE)
SELECT
    b.id AS booking_id,
    b.date_start,
    u.first_name
FROM bookings b
INNER JOIN users u
    ON b.user_id = u.id
WHERE b.date_start > '2024-01-01'
ORDER BY b.date_start;
```

**Expected Baseline Output (without indexes):**

```
Seq Scan on bookings (cost=..., actual time=..., rows=..., loops=1)
Total Cost: High (e.g., 10000)
Execution Time: ~50ms (full table scan)
```

---

## STEP 2: Apply Indexes

Execute the index creation script:

```sql
\i database_index.sql
```

**Example Indexes:**

```sql
CREATE INDEX idx_bookings_date_start ON bookings(date_start);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
```

---

## STEP 3: Test Performance After Indexing

Re-run the query from STEP 1.

```sql
EXPLAIN (ANALYZE TRUE, BUFFERS TRUE)
SELECT
    b.id AS booking_id,
    b.date_start,
    u.first_name
FROM bookings b
INNER JOIN users u
    ON b.user_id = u.id
WHERE b.date_start > '2024-01-01'
ORDER BY b.date_start;
```

**Expected Optimized Output:**

```
Index Scan using idx_bookings_date_start (cost=..., actual time=..., rows=..., loops=1)
Index Scan using idx_bookings_user_id for JOIN (cost=low)
Total Cost: Low (e.g., 100)
Execution Time: ~5ms (index usage, no full scan)
```

* Monitor index usage:

```sql
SELECT * FROM pg_stat_user_indexes;
```

---

## Performance Measurement Notes

* **Before Indexes:** Sequential scans, high cost (~10000+), execution time ~50ms+.
* **After Indexes:** Index scans, low cost (~100), execution time ~5ms; ~10x speedup.
* Use `EXPLAIN (ANALYZE TRUE, BUFFERS TRUE)` for detailed timing and buffer stats.
* Results depend on dataset size; test with sample data from the repository.
* Indexes add slight overhead on INSERT/UPDATE; monitor for write-heavy workloads.

---
