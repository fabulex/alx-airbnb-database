-- ============================================================
-- AIRBNB DATABASE SCHEMA (v3.0)
-- PostgreSQL | Normalized to 3NF | Optimized for Performance
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS airbnb AUTHORIZATION CURRENT_USER;
SET search_path TO airbnb;

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE airbnb.users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email CITEXT UNIQUE NOT NULL,  -- case-insensitive unique emails
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(10) CHECK (role IN ('guest', 'host', 'admin')) NOT NULL DEFAULT 'guest',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email_role ON airbnb.users (email, role);
CREATE INDEX idx_users_active ON airbnb.users (is_active);

-- ============================================================
-- 2. PROPERTIES
-- ============================================================
CREATE TABLE airbnb.properties (
    property_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES airbnb.users(user_id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    price_per_night NUMERIC(10,2) NOT NULL CHECK (price_per_night > 0),
    max_guests SMALLINT DEFAULT 1 CHECK (max_guests > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_location ON airbnb.properties (location);
CREATE INDEX idx_properties_geo ON airbnb.properties (latitude, longitude);
CREATE INDEX idx_properties_price_range ON airbnb.properties (price_per_night);
CREATE INDEX idx_properties_host ON airbnb.properties (host_id);

-- ============================================================
-- 3. BOOKINGS
-- ============================================================
CREATE TABLE airbnb.bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES airbnb.properties(property_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES airbnb.users(user_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_days INTEGER GENERATED ALWAYS AS (GREATEST(0, end_date - start_date)) STORED,
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    status VARCHAR(15) CHECK (status IN ('pending', 'confirmed', 'canceled', 'completed')) DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_booking_dates CHECK (start_date < end_date),
    CONSTRAINT uq_booking UNIQUE (property_id, user_id, start_date)
);

-- Partial & composite indexes for faster queries
CREATE INDEX idx_bookings_active
    ON airbnb.bookings (property_id, start_date, end_date)
    WHERE status IN ('confirmed', 'pending');

CREATE INDEX idx_bookings_user_status
    ON airbnb.bookings (user_id, status);

-- ============================================================
-- 4. PAYMENTS
-- ============================================================
CREATE TABLE airbnb.payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL UNIQUE REFERENCES airbnb.bookings(booking_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(20) CHECK (payment_method IN ('credit_card', 'paypal', 'stripe')) NOT NULL,
    payment_status VARCHAR(15) CHECK (payment_status IN ('success', 'failed', 'refunded')) DEFAULT 'success',
    transaction_ref VARCHAR(64) UNIQUE
);

CREATE INDEX idx_payments_status ON airbnb.payments (payment_status);
CREATE INDEX idx_payments_recent ON airbnb.payments (payment_date DESC);

-- ============================================================
-- 5. REVIEWS
-- ============================================================
CREATE TABLE airbnb.reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES airbnb.properties(property_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES airbnb.users(user_id) ON DELETE CASCADE,
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_review UNIQUE (property_id, user_id)
);

CREATE INDEX idx_reviews_property_rating ON airbnb.reviews (property_id, rating);
CREATE INDEX idx_reviews_recent ON airbnb.reviews (created_at DESC);

-- ============================================================
-- 6. MESSAGES
-- ============================================================
CREATE TABLE airbnb.messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES airbnb.users(user_id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES airbnb.users(user_id) ON DELETE CASCADE,
    message_body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_message_sender_recipient CHECK (sender_id <> recipient_id)
);

CREATE INDEX idx_messages_conversation ON airbnb.messages (sender_id, recipient_id, sent_at DESC);
CREATE INDEX idx_messages_unread ON airbnb.messages (recipient_id) WHERE is_read = FALSE;

-- ============================================================
-- 7. TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE OR REPLACE FUNCTION airbnb.fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON airbnb.users
FOR EACH ROW
EXECUTE FUNCTION airbnb.fn_update_timestamp();

CREATE TRIGGER trg_properties_updated_at
BEFORE UPDATE ON airbnb.properties
FOR EACH ROW
EXECUTE FUNCTION airbnb.fn_update_timestamp();

CREATE TRIGGER trg_bookings_updated_at
BEFORE UPDATE ON airbnb.bookings
FOR EACH ROW
EXECUTE FUNCTION airbnb.fn_update_timestamp();

-- ============================================================
-- END OF SCHEMA
-- ============================================================
