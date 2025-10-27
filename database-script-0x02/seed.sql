-- PostgreSQL Sample Data Script for AirBnB Database
-- Overview: Populates the schema with balanced test data (5 users, 3 properties, 4 bookings, etc.).
-- Run: After airbnb_schema.sql. psql -f airbnb_sample_data.sql -d airbnb_db
-- Dates relative to Oct 27, 2025; auto-IDs used.

-- STEP 1: Populate sample data in transaction.
-- Rationale: Uses auto-generated IDs (no manual PK inserts); dates relative to Oct 27, 2025.
BEGIN;

-- Users (IDs auto: 1=Alice, 2=Bob, 3=Carol, 4=David, 5=Eve)
INSERT INTO "User" (first_name, last_name, email, password_hash, phone_number, role) VALUES
('Alice', 'Admin', 'admin@airbnb.com', 'hashed_admin_pass', '+1-555-0100', 'admin'),
('Bob', 'Host', 'host1@example.com', 'hashed_host1_pass', '+1-555-0200', 'host'),
('Carol', 'Host', 'host2@example.com', 'hashed_host2_pass', '+1-555-0300', 'host'),
('David', 'Guest', 'guest1@example.com', 'hashed_guest1_pass', '+1-555-0400', 'guest'),
('Eve', 'Guest', 'guest2@example.com', 'hashed_guest2_pass', '+1-555-0500', 'guest');

-- Properties (IDs auto: 1=NYC/Bob, 2=LA/Bob, 3=Aspen/Carol)
INSERT INTO "Property" (host_id, name, description, location, pricepernight, created_at) VALUES
(2, 'Cozy Apartment in NYC', 'Comfortable 2-bedroom in Manhattan.', 'New York, NY', 150.00, '2025-01-15'),
(2, 'Beach House in LA', 'Beachfront with pool.', 'Los Angeles, CA', 250.00, '2025-02-10'),
(3, 'Mountain Cabin in Aspen', 'Rustic for skiing.', 'Aspen, CO', 300.00, '2025-03-05');

-- Bookings (IDs auto: 1=NYC confirmed, 2=LA pending, 3=NYC canceled, 4=Aspen confirmed)
INSERT INTO "Booking" (property_id, user_id, start_date, end_date, status, created_at) VALUES
(1, 4, '2025-10-01', '2025-10-05', 'confirmed', '2025-09-20'),  -- NYC, David (past)
(2, 5, '2025-11-10', '2025-11-12', 'pending', '2025-10-25'),  -- LA, Eve (future)
(1, 5, '2025-09-15', '2025-09-18', 'canceled', '2025-09-10'),  -- NYC canceled, Eve (past)
(3, 4, '2025-10-10', '2025-10-13', 'confirmed', '2025-09-25');  -- Aspen, David (past)

-- Payments (IDs auto; for confirmed: NYC=600 (150*4), Aspen=900 (300*3))
INSERT INTO "Payment" (booking_id, amount, payment_method, payment_date) VALUES
(1, 600.00, 'credit_card', '2025-09-21'),
(4, 900.00, 'paypal', '2025-09-26');

-- Reviews (IDs auto; for confirmed past stays)
INSERT INTO "Review" (property_id, user_id, rating, comment, created_at) VALUES
(1, 4, 5, 'Amazing stay!', '2025-10-06'),  -- NYC
(3, 4, 4, 'Great cabin!', '2025-10-14');  -- Aspen

-- Messages (IDs auto; host-guest interactions)
INSERT INTO "Message" (sender_id, recipient_id, message_body, sent_at) VALUES
(2, 4, 'Welcome! Check-in tomorrow.', '2025-09-20'),  -- Bob to David
(5, 2, 'Extra night available?', '2025-10-25');  -- Eve to Bob

COMMIT;

-- STEP 2: Optimization and Verification (updates stats for query planner).
-- Rationale: Ensures efficient queries after initial inserts.
VACUUM ANALYZE "User", "Property", "Booking", "Payment", "Review", "Message";

-- Quick verification:
-- SELECT COUNT(*) FROM "Booking" WHERE status = 'confirmed'; -- Expect 2
-- SELECT b.booking_id, (b.end_date - b.start_date) * p.pricepernight AS total_cost
-- FROM "Booking" b JOIN "Property" p ON b.property_id = p.property_id
-- WHERE b.status = 'confirmed'; -- Expect 600 and 900
