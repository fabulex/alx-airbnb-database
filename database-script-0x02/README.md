# Optimization and Verification

This guide explains steps for updating statistics and verifying query results to ensure efficient database operations.

---

## Step 1: Update Statistics for the Query Planner

Rationale: Ensures that the query planner has up-to-date statistics after initial data inserts, which helps optimize query execution.

```sql
VACUUM ANALYZE "User", "Property", "Booking", "Payment", "Review", "Message";
```

---

## Step 2: Quick Verification

Run simple checks to verify data correctness and expected query outcomes.

**Example 1: Count confirmed bookings**

```sql
SELECT COUNT(*)
FROM "Booking"
WHERE status = 'confirmed';
-- Expect result: 2
```

**Example 2: Calculate total cost for confirmed bookings**

```sql
SELECT b.booking_id,
       (b.end_date - b.start_date) * p.pricepernight AS total_cost
FROM "Booking" b
JOIN "Property" p ON b.property_id = p.property_id
WHERE b.status = 'confirmed';
-- Expect results: 600 and 900
```

---

Notes:

* Regularly running `VACUUM ANALYZE` ensures the planner can choose optimal indexes and join strategies.
* Verification queries help confirm data integrity and calculation correctness.
