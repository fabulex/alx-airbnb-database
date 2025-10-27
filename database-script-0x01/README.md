

````markdown
# Airbnb Database Schema Design

## 📘 Overview
This document describes the SQL schema for the **Airbnb Database**, including entity definitions, relationships, and normalization principles applied to ensure **Third Normal Form (3NF)**.
The schema is optimized for performance, integrity, and scalability.

---

## 🧱 Entities and Relationships

### 1. USER
Stores all users in the system (guests, hosts, and admins).

**Key Points:**
- `email` is unique to avoid duplicate registrations.
- `role` differentiates user responsibilities.
- `created_at` automatically records the registration timestamp.

**Table Definition:**
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(10) CHECK (role IN ('guest', 'host', 'admin')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email);
````

---

### 2. PROPERTY

Represents listings created by hosts.

**Key Points:**

* `host_id` is a foreign key referencing `users(user_id)`.
* Includes automatic timestamps for creation and updates.

**Table Definition:**

```sql
CREATE TABLE properties (
    property_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_properties_host_id ON properties(host_id);
CREATE INDEX idx_properties_location ON properties(location);
```

---

### 3. BOOKING

Represents a reservation made by a guest.

**Key Points:**

* Connects guests (`users`) and properties.
* Includes booking status and total price.

**Table Definition:**

```sql
CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('pending', 'confirmed', 'canceled')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_date_range CHECK (end_date > start_date)
);
CREATE INDEX idx_bookings_property_id ON bookings(property_id);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
```

---

### 4. PAYMENT

Stores payment information related to bookings.

**Key Points:**

* Ensures each payment is tied to a valid booking.
* Records payment method and timestamp.

**Table Definition:**

```sql
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(20) CHECK (payment_method IN ('credit_card', 'paypal', 'stripe')) NOT NULL
);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
```

---

### 5. REVIEW

Captures guest feedback on properties.

**Key Points:**

* Ratings range from 1 to 5.
* Each review is associated with a property and user.

**Table Definition:**

```sql
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_reviews_property_id ON reviews(property_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
```

---

### 6. MESSAGE

Handles private communication between users.

**Key Points:**

* `sender_id` and `recipient_id` both reference `users(user_id)`.
* Includes message body and timestamp.

**Table Definition:**

```sql
CREATE TABLE messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    message_body TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_recipient_id ON messages(recipient_id);
```

---

## 🧩 Normalization Process

**1. First Normal Form (1NF)**

* All tables have atomic columns (no repeating groups or multi-valued attributes).

**2. Second Normal Form (2NF)**

* All non-key attributes depend entirely on the primary key.
* No partial dependencies (since all PKs are single-column UUIDs).

**3. Third Normal Form (3NF)**

* No transitive dependencies.
* Each attribute depends only on the primary key.

**Result:**
✅ The database structure is fully normalized up to 3NF.

---

## ⚡ Performance Enhancements

* **Indexes**: Added on foreign keys and high-query columns (`email`, `property_id`, `user_id`).
* **Foreign Key Cascades**: Ensure referential integrity and automatic cleanup.
* **CHECK constraints**: Validate business logic at the database level.
* **UUIDs**: Prevent ID collisions in distributed environments.

---

## 🧠 Future Improvements

* Add support for property images and amenities.
* Implement soft deletes using an `is_active` flag.
* Introduce auditing tables for user and property changes.
* Add geolocation indexing for location-based searches.

---

## 🏁 Conclusion

This schema ensures:

* **Data integrity** through constraints and relationships.
* **Performance optimization** through indexing and normalization.
* **Scalability** for future feature expansion in an Airbnb-like system.

```
