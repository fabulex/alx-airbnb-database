-- PostgreSQL Schema Script for AirBnB Database (Fixed & Explained)
-- Overview: Creates normalized (3NF) tables, ENUMs, triggers, and indexes.
-- Key Fixes: BIGSERIAL PKs (perf), overlap prevention, security revokes.
-- Compatibility: PostgreSQL 12+. Run: psql -f airbnb_schema.sql -d airbnb_db
-- Prerequisites: Superuser access for REVOKE and EXTENSION.

-- STEP 1: Secure the schema by revoking default public privileges (prevents unauthorized access).
-- Rationale: Default 'public' schema grants broad rights; revoke to lock down.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- STEP 2: Enable UUID extension (optional; used only if needed for future UUIDs, but we use BIGSERIAL here).
-- Rationale: Prepares for UUID if migrating back, but skipped for perf.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- STEP 3: Define custom ENUM types for roles, statuses, and methods.
-- Rationale: Enforces valid values at DB level (better than VARCHAR checks).
CREATE TYPE user_role AS ENUM ('guest', 'host', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'canceled');
CREATE TYPE payment_method AS ENUM ('credit_card', 'paypal', 'stripe');

-- STEP 4: Create User table with BIGSERIAL PK.
-- Rationale: Auto-incrementing IDs for sequential inserts (faster than random UUIDs; reduces index fragmentation).
CREATE TABLE "User" (
    user_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role user_role NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STEP 5: Create Property table with BIGSERIAL PK and FK to User.
-- Rationale: host_id as BIGINT for consistency with User.user_id.
CREATE TABLE "Property" (
    property_id BIGSERIAL PRIMARY KEY,
    host_id BIGINT NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    pricepernight DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STEP 6: Define trigger function and attach to Property for auto-updating 'updated_at'.
-- Rationale: Simulates MySQL's ON UPDATE CURRENT_TIMESTAMP; ensures audit trail.
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER update_property_updated_at BEFORE UPDATE ON "Property" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- STEP 7: Create Booking table with BIGSERIAL PK, FKs, and date CHECK.
-- Rationale: CHECK ensures logical dates; RESTRICT prevents cascading deletes.
CREATE TABLE "Booking" (
    booking_id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES "Property"(property_id) ON DELETE RESTRICT,
    user_id BIGINT NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status booking_status NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- STEP 8: Add overlap prevention index (unique on confirmed bookings).
-- Rationale: Blocks exact date overlaps per property; for partial overlaps, upgrade to GIST exclusion (commented).
CREATE UNIQUE INDEX idx_no_overlap ON "Booking" (property_id, start_date, end_date) WHERE status = 'confirmed';
-- For advanced partial overlap: CREATE EXTENSION btree_gist; CREATE INDEX idx_overlap_gist ON "Booking" USING GIST (tsrange(start_date, end_date));

-- STEP 9: Create remaining tables (Payment, Review, Message) with BIGSERIAL PKs.
-- Rationale: CASCADE on Payment for dependent deletes; RESTRICT elsewhere for safety.
CREATE TABLE "Payment" (
    payment_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES "Booking"(booking_id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method payment_method NOT NULL
);

CREATE TABLE "Review" (
    review_id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES "Property"(property_id) ON DELETE RESTRICT,
    user_id BIGINT NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Message" (
    message_id BIGSERIAL PRIMARY KEY,
    sender_id BIGINT NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    recipient_id BIGINT NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    message_body TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STEP 10: Create performance indexes.
-- Rationale: Target common queries (e.g., user history, property availability).
CREATE INDEX idx_user_email ON "User"(email);
CREATE INDEX idx_booking_property_id_status ON "Booking"(property_id, status);
CREATE INDEX idx_booking_user_id_dates ON "Booking"(user_id, start_date, end_date);
CREATE INDEX idx_booking_dates_status ON "Booking"(start_date, end_date) WHERE status = 'confirmed';
CREATE INDEX idx_payment_booking_id ON "Payment"(booking_id);
CREATE INDEX idx_review_property_id ON "Review"(property_id);
CREATE INDEX idx_message_sent_at ON "Message"(sent_at DESC);

-- STEP 12: Optimize post-schema (optional; run after data load for stats).
-- Rationale: Ensures efficient queries after initial setup.
-- VACUUM ANALYZE "User", "Property", "Booking", "Payment", "Review", "Message";

-- STEP 13: Sample verification queries (uncomment to run post-data).
-- Rationale: Quick integrity checks; totals computed dynamically (no stored total_price per 3NF).
-- SELECT COUNT(*) FROM "Booking" WHERE status = 'confirmed';  -- Expected: 2
-- SELECT b.booking_id, (b.end_date - b.start_date) * p.pricepernight AS total FROM "Booking" b JOIN "Property" p ON b.property_id = p.property_id WHERE b.status = 'confirmed';  -- Expected: 600, 900
