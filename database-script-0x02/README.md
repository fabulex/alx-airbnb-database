## Optimization and Verification (updates stats for query planner).

-- Rationale: Ensures efficient queries after initial inserts.
VACUUM ANALYZE "User", "Property", "Booking", "Payment", "Review", "Message";

-- Quick verification:
-- SELECT COUNT(*) FROM "Booking" WHERE status = 'confirmed'; -- Expect 2
-- SELECT b.booking_id, (b.end_date - b.start_date) * p.pricepernight AS total_cost
-- FROM "Booking" b JOIN "Property" p ON b.property_id = p.property_id
-- WHERE b.status = 'confirmed'; -- Expect 600 and 900
