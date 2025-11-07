-- Query 1: Total number of bookings made by each user using COUNT and GROUP BY.
-- Aggregates booking counts per user, joining users and bookings tables.
-- Useful for user activity analysis or loyalty segmentation.
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
    COUNT(b.id) AS total_bookings  -- Count of bookings per user
FROM
    users AS u                    -- Users table
LEFT JOIN
    bookings AS b                 -- Bookings table (LEFT to include users with 0 bookings)
    ON u.id = b.user_id           -- Join condition
GROUP BY
    u.id, u.first_name, u.last_name  -- Group by user details
ORDER BY
    total_bookings DESC;         -- Sort by highest bookings first

-- Query 2: Rank properties based on total bookings using ROW_NUMBER() window function.
-- Computes total bookings per property via aggregation, then assigns unique row numbers.
-- ROW_NUMBER() provides sequential ranking without ties; useful for strict ordering in leaderboards.
SELECT
    p.id AS property_id,
    p.name AS property_name,
    COUNT(b.id) AS total_bookings,  -- Aggregated count per property
    ROW_NUMBER() OVER (            -- Window function to assign row numbers
        ORDER BY COUNT(b.id) DESC  -- Order by total bookings descending
    ) AS booking_rank
FROM
    properties AS p               -- Properties table
LEFT JOIN
    bookings AS b                 -- Bookings table (LEFT for properties with 0 bookings)
    ON p.id = b.property_id       -- Join condition (assuming bookings has property_id)
GROUP BY
    p.id, p.name                  -- Group by property details
ORDER BY
    booking_rank;                 -- Sort by row number (ascending for 1-based ranking)
