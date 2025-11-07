-- INNER JOIN: Retrieve all bookings and the respective users who made those bookings.
SELECT
    b.id AS booking_id,
    b.start_date,
    b.end_date,
    u.id AS user_id,
    u.first_name,
    u.last_name
FROM
    bookings AS b
INNER JOIN
    users AS u ON b.user_id = u.id
ORDER BY
    b.start_date;

-- LEFT JOIN: Retrieve all properties and their reviews, including properties that have no reviews.
SELECT
    p.id AS property_id,
    p.name AS property_name,
    r.id AS review_id,
    r.rating,
    r.comment
FROM
    properties AS p
LEFT JOIN
    reviews AS r ON p.id = r.property_id
ORDER BY
    p.id;

-- FULL OUTER JOIN: Retrieve all users and all bookings, even if the user has no booking or a booking is not linked to a user.
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
    b.id AS booking_id,
    b.start_date,
    b.end_date
FROM
    users AS u
FULL OUTER JOIN
    bookings AS b ON u.id = b.user_id
ORDER BY
    COALESCE(u.id, b.user_id), b.start_date;
