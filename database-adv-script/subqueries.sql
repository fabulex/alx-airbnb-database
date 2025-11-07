-- Non-correlated subquery: Find all properties where the average rating is greater than 4.0.
-- This uses a subquery to compute average ratings per property independently, then filters properties based on that.
SELECT
    p.id AS property_id,
    p.name AS property_name,
    p.description
FROM
    properties AS p
WHERE
    p.id IN (
        -- Subquery: Calculate avg rating per property, group by property_id, filter > 4.0
        SELECT
            r.property_id
        FROM
            reviews AS r
        GROUP BY
            r.property_id
        HAVING
            AVG(r.rating) > 4.0
    )
ORDER BY
    p.id;

-- Correlated subquery: Find users who have made more than 3 bookings.
-- The subquery references the outer query's u.id, making it correlated; it executes once per user row.
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
    u.email
FROM
    users AS u
WHERE
    (
        -- Correlated subquery: Count bookings for the current user (u.id)
        SELECT
            COUNT(*)
        FROM
            bookings AS b
        WHERE
            b.user_id = u.id  -- References outer u.id
    ) > 3
ORDER BY
    u.id;
