
# Normalization Analysis and Adjustments for AirBnB Database Schema

## Introduction

This document outlines the process of reviewing the current AirBnB database schema for normalization violations, particularly focusing on achieving **Third Normal Form (3NF)**. Normalization is a database design technique that minimizes redundancy and dependency by organizing fields and tables to reduce anomalies during data operations (insert, update, delete).

### Normalization Forms Recap
- **1NF (First Normal Form)**: Ensures atomic values (no repeating groups or arrays in columns) and unique rows (via primary keys).
- **2NF (Second Normal Form)**: Builds on 1NF; eliminates partial dependencies (non-key attributes must depend on the entire primary key, not part of it). This is relevant for composite keys.
- **3NF (Third Normal Form)**: Builds on 2NF; eliminates transitive dependencies (non-key attributes must depend only on the primary key, not on other non-key attributes). Derived or calculated fields often violate 3NF if stored redundantly.

The current schema (post-error resolution) uses single-column primary keys (UUIDs as CHAR(36)), ensuring most tables are in 1NF and 2NF. We will identify 3NF violations and propose adjustments.

## Step 1: Review of Current Schema for Normalization Violations

The schema entities and key attributes are:

| Entity    | Primary Key | Key Attributes and Potential Issues |
|-----------|-------------|-------------------------------------|
| **User** | `user_id` | `first_name`, `last_name`, `email` (unique), `password_hash`, `phone_number`, `role`, `created_at`. **No issues**: All attributes directly depend on `user_id`. |
| **Property** | `property_id` | `host_id` (FK), `name`, `description`, `location`, `pricepernight`, `created_at`, `updated_at`. **No issues**: All depend on `property_id`. |
| **Booking** | `booking_id` | `property_id` (FK), `user_id` (FK), `start_date`, `end_date`, `total_price`, `status`, `created_at`. **Potential 3NF Violation**: `total_price` appears to be derived (transitive dependency) from `pricepernight` (in Property) × `(end_date - start_date + 1)` (nights). Storing it creates redundancy—if `pricepernight` changes or dates are updated, `total_price` must be manually synced, risking inconsistencies. |
| **Payment** | `payment_id` | `booking_id` (FK), `amount`, `payment_date`, `payment_method`. **Minor Concern**: `amount` should logically match Booking's `total_price`, introducing indirect redundancy. However, if payments can include fees/taxes, it may be justified; assuming 1:1 match here. |
| **Review** | `review_id` | `property_id` (FK), `user_id` (FK), `rating`, `comment`, `created_at`. **No issues**: All depend on `review_id`. |
| **Message** | `message_id` | `sender_id` (FK), `recipient_id` (FK), `message_body`, `sent_at`. **No issues**: All depend on `message_id`. |

### Identified Violations
- **Primary 3NF Violation in Booking**: `total_price` is a **derived attribute** (transitive dependency). It depends on attributes from other tables/rows (`pricepernight` and dates), not solely on `booking_id`. This leads to:
  - **Update Anomaly**: Changing a property's `pricepernight` requires updating all related bookings' `total_price`.
  - **Redundancy**: Storage waste for computable data.
  - **Insertion Anomaly**: Can't insert a booking without knowing/calculating total upfront.
- **Secondary Issue in Payment**: `amount` redundantly stores what could be derived from Booking. If we resolve Booking's issue, this becomes moot—`amount` can reference the computed total.

No violations in 1NF (all atomic) or 2NF (single PKs, no partial deps).

## Step 2: Normalization Adjustments to Achieve 3NF

To reach 3NF:
- **Eliminate Derived Attributes**: Remove `total_price` from Booking. Compute it dynamically in queries (e.g., via JOINs).
- **Handle Payment**: Retain `amount` as the authoritative total (post-computation), assuming it captures the final billed amount (e.g., including taxes). This avoids transitive dependency.
- **No New Tables Needed**: No decomposition required (e.g., no multi-valued dependencies).
- **Application-Level Changes**: Enforce calculation in app code (e.g., on booking creation/update: `total_price = property.pricepernight * DATEDIFF(end_date, start_date) + 1`).
- **Query Example for Computed Total**:
  ```sql
  SELECT b.booking_id, b.start_date, b.end_date, p.pricepernight,
         (DATEDIFF(b.end_date, b.start_date) + 1) * p.pricepernight AS total_price
  FROM Booking b
  JOIN Property p ON b.property_id = p.property_id;
  ```

### Updated Schema Snippet (Key Changes Only)
Only Booking and Payment are affected:

```sql
-- Updated Booking table (remove total_price)
CREATE TABLE `Booking` (
    booking_id CHAR(36) PRIMARY KEY,
    property_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('pending', 'confirmed', 'canceled') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date > start_date),
    FOREIGN KEY (property_id) REFERENCES `Property`(property_id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES `User`(user_id) ON DELETE RESTRICT
);

-- Payment remains unchanged (amount now serves as the stored total)
CREATE TABLE `Payment` (
    payment_id CHAR(36) PRIMARY KEY,
    booking_id CHAR(36) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,  -- Computed/stored final total at payment time
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('credit_card', 'paypal', 'stripe') NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES `Booking`(booking_id) ON DELETE CASCADE
);
```

- **Migration Script Suggestion** (for existing DB):
  ```sql
  -- Compute and update payments before dropping
  UPDATE Payment p
  JOIN Booking b ON p.booking_id = b.booking_id
  JOIN Property prop ON b.property_id = prop.property_id
  SET p.amount = (DATEDIFF(b.end_date, b.start_date) + 1) * prop.pricepernight
  WHERE p.amount = 0 OR p.amount IS NULL;  -- Assuming placeholders

  -- Drop column
  ALTER TABLE Booking DROP COLUMN total_price;
  ```

## Step 3: Benefits and Trade-offs

### Benefits of 3NF Compliance
- **Reduced Redundancy**: Saves storage; no duplicate price data across bookings.
- **Data Integrity**: Automatic consistency—price changes propagate via queries without manual updates.
- **Anomaly Prevention**: Easier inserts/updates (e.g., change property price once, affects all future computations).
- **Scalability**: Queries remain efficient with indexes on FKs/dates.

### Trade-offs
- **Performance Overhead**: Computing totals in every query (mitigate with views or cached queries).
- **Complexity**: App must handle calculations; reporting tools need JOINs.
- **Assumptions**: Ignores dynamic pricing (e.g., seasonal rates)—if needed, add a `PriceHistory` table for full denormalization trade-off.

## Conclusion

The schema was already close to 3NF, with the only violation being the derived `total_price` in Booking. By removing it and relying on computed values, we achieve full 3NF without introducing new entities. This design prioritizes integrity over storage convenience. For production, consider database views for common computed queries:

```sql
CREATE VIEW BookingWithTotal AS
SELECT b.*, p.pricepernight,
       (DATEDIFF(b.end_date, b.start_date) + 1) * p.pricepernight AS total_price
FROM Booking b
JOIN Property p ON b.property_id = p.property_id;
```
