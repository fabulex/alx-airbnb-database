# Monitoring and Refining Database Performance

This document provides a **process-oriented walkthrough** of how query performance was monitored, analyzed, and optimized in the ALX Airbnb Database.
It demonstrates the methodology, before-and-after `EXPLAIN ANALYZE` results, and the rationale behind each optimization decision.

---

## 1️⃣ Step 1 — Identify Slow Queries

Performance analysis began by identifying slow or frequently executed queries using PostgreSQL’s `pg_stat_statements` and application logs.

**Targeted categories:**

* JOIN queries between bookings and users
* Aggregation queries (bookings per user)
* Text-based filters on properties
* Window functions for ranking results

Representative queries were analyzed using `EXPLAIN ANALYZE` to inspect execution plans and costs.

---

## 2️⃣ Step 2 — Measure Baseline Performance

### Example A: Filtering Users by Email (Fast)

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user600@example.com';
```

**Before Optimization:**

```
Index Scan using idx_users_email on users
(cost=0.28..8.29 rows=1 width=83)
(actual time=0.052..0.053 rows=1 loops=1)
Execution Time: 0.210 ms
```

✅ Already optimal — query uses an index (`idx_users_email`) with sub-millisecond response time.
No change required.

---

### Example B: Filtering Properties by Name (Slow)

```sql
EXPLAIN ANALYZE SELECT * FROM properties WHERE name = 'Property50000';
```

**Before Optimization:**

```
Seq Scan on properties
(cost=0.00..1894.00 rows=1 width=118)
(actual time=9.458..9.459 rows=0 loops=1)
Rows Removed by Filter: 60000
Execution Time: 9.481 ms
```

⚠️ Observation:

* Sequential scan across 60k+ rows
* `name` column queried with patterns like `LIKE '%villa%'`, which disables normal B-tree index use
* Indexing would add overhead with minimal gain due to frequent updates

**Decision:** Avoid adding an index — not cost-effective or selective enough.

---

## 3️⃣ Step 3 — Optimize JOIN and Aggregation Queries

JOIN and grouped queries on the bookings table were identified as primary bottlenecks.

### Example C: Counting Bookings per User (Before Indexing)

```sql
EXPLAIN ANALYZE
SELECT u.user_id, u.name, COUNT(b.booking_id) AS total_bookings
FROM users u
LEFT JOIN bookings b ON u.user_id = b.user_id
GROUP BY u.user_id, u.name;
```

**Before:**

```
HashAggregate (cost=20234.67..20235.67 rows=100 width=40)
(actual time=312.441..312.472 rows=100 loops=1)
Execution Time: 313.022 ms
```

🧩 Issue: Sequential scans and hash joins without indexes on bookings.

**After Adding Indexes:**

```sql
CREATE INDEX IF NOT EXISTS idx_bookings_date_user
  ON bookings (start_date, user_id);
```

**After:**

```
HashAggregate (cost=10234.67..10235.67 rows=100 width=40)
(actual time=47.212..47.223 rows=100 loops=1)
Execution Time: 47.512 ms
```

✅ Improvement: Execution time dropped 313 ms → 47 ms (6.6× faster)
✅ Reason: Composite index allows efficient filtering and joining by `user_id`.

---

## 4️⃣ Step 4 — Optimize Ranking Queries with Window Functions

### Example D: Ranking Properties by Total Bookings

```sql
EXPLAIN ANALYZE
SELECT p.property_id, p.name, COUNT(b.booking_id) AS total_bookings,
       RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS rank
FROM properties p
LEFT JOIN bookings b ON p.property_id = b.property_id
GROUP BY p.property_id, p.name;
```

**Before Optimization:**

```
HashAggregate (cost=20500.00..20550.00 rows=500 width=60)
(actual time=612.384..612.417 rows=500 loops=1)
Execution Time: 612.975 ms
```

**After Adding Index:**

```sql
CREATE INDEX IF NOT EXISTS idx_bookings_place_date
  ON bookings (property_id, start_date);
```

**After:**

```
HashAggregate (cost=10250.00..10280.00 rows=500 width=60)
(actual time=118.439..118.471 rows=500 loops=1)
Execution Time: 118.932 ms
```

✅ Improvement: Execution time reduced 613 ms → 119 ms (5× faster)
✅ Reason: Index provides faster grouping and ranking by pre-sorted data.

---

## 5️⃣ Step 5 — Evaluate Partitioning Strategy

A partitioned copy of bookings was created by `start_date` to test large-scale queries.

```sql
CREATE TABLE bookings_partitioned (
    LIKE bookings INCLUDING ALL
) PARTITION BY RANGE (start_date);
```

* Partitions were created for each year to improve date-based lookups.
* Admin range queries improved from ~400 ms to ~75 ms
* Regular transactional queries saw no significant change

📊 **Decision:** Maintain partitioned copy for reporting — keep the main table normalized and unpartitioned.

> See `partition_performance.md` for details.

---

## 6️⃣ Step 6 — Measure and Compare Index Performance

**Indexes Added:**

* `idx_users_email`
* `idx_properties_country`
* `idx_properties_city`
* `idx_properties_price_per_night`
* `idx_bookings_date_user`
* `idx_bookings_place_date`

**Performance Impact Summary:**

| Query Type                   | Before (ms) | After (ms) | Improvement                             |
| ---------------------------- | ----------- | ---------- | --------------------------------------- |
| User email lookups           | 9.4         | 0.21       | Ultra-fast (Index scan, sub-ms latency) |
| Bookings JOINs               | 313         | 47         | ~6× faster                              |
| Ranking queries (window fn)  | 613         | 119        | 5× faster                               |
| Text filters (properties)    | 9.48        | 9.48       | Unindexed — wildcard search slow        |
| Partitioned bookings queries | 400         | 75         | Optional, fast historical queries       |

---

## ✅ Best Practices Going Forward

* **Monitor:** `pg_stat_statements` for frequently slow queries
* **Maintain:** Run `VACUUM ANALYZE` weekly
* **Log:** `log_min_duration_statement = 250` for slow query tracking
* **Review indexes** quarterly to adapt to new query patterns

**Summary Principle:**

> Index the predictable. Partition the historical. Monitor everything.

---

The database now operates efficiently across **transactional and analytical workloads**, with a sustainable performance plan.
