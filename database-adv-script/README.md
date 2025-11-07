## Advanced Querying with SQL
This project is a part of the ALX Airbnb Database Module focusing on implementation of advanced SQL querying and optimization techniques to work with a simulated Airbnb database.

###Prerequisites
- PostgreSQL database with the ALX Airbnb schema loaded.
- Access to tables: users, bookings, properties, reviews.

###Usage
- Connect to your PostgreSQL instance (e.g., via psql).
- Execute the script: \i joins_queries.sql or run queries individually.
- Review results for data relationships and NULL handling.

---

## Queries Overview

### 1. INNER JOIN — Bookings and Users
**Purpose:**
Retrieve all bookings and the respective users who made those bookings.

**Key Points:**
- Returns only matching rows between `bookings` and `users`.
- Excludes users without bookings and bookings without users.
- Ideal for reports showing **confirmed bookings** with **user details**.

**Example Output Columns:**
| booking_id | start_date | end_date | user_id | first_name | last_name |
|-------------|-------------|-----------|----------|-------------|------------|

---

### 2. LEFT JOIN — Properties and Reviews
**Purpose:**
Retrieve all properties and their reviews, including those **without any reviews**.

**Key Points:**
- Includes all properties (`LEFT` table).
- Displays `NULL` for `review_id`, `rating`, and `comment` when no review exists.
- Useful for **property dashboards** showing review coverage or completeness.

**Example Output Columns:**
| property_id | property_name | review_id | rating | comment |
|--------------|----------------|------------|---------|----------|

---

### 3. FULL OUTER JOIN — Users and Bookings (Audit View)
**Purpose:**
Retrieve all users and all bookings, even if:
- A user has **no bookings**, or
- A booking is **not linked** to a user.

**Key Points:**
- Combines both tables fully.
- Shows `NULL` values for unmatched records on either side.
- **PostgreSQL supports `FULL OUTER JOIN` natively** — no UNION workaround needed.
- Excellent for **data auditing** and identifying **orphan records**.

**Example Output Columns:**
| user_id | first_name | last_name | booking_id | start_date | end_date |
|----------|-------------|------------|-------------|-------------|-----------|

---
