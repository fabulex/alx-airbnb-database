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

### 4. Non-Correlated Subquery: Properties with Avg Rating >4.0
- Description: Independently computes average ratings via subquery, then matches property IDs.
- Use Case: Identify high-rated properties for recommendations.
- Key Fields: property_id, property_name, description.
- Sorted By: property_id.

### 5. Correlated Subquery: Users with >3 Bookings
- Description: Subquery runs per user row, counting bookings tied to each user_id.
- Use Case: Segment frequent users for loyalty programs.
- Key Fields: user_id, first_name, last_name, email.
- Sorted By: user_id.

**Key Points**
- Non-correlated: Subquery executes once; efficient for independent computations.
- Correlated: Subquery executes per outer row; use indexes on join fields (e.g., user_id) to optimize.
- For extensions, try EXISTS with correlated subqueries or scalar subqueries in SELECT.

### 6. Aggregation: Total Bookings per User
- Description: Uses COUNT and GROUP BY to tally bookings per user (includes users with 0 via LEFT JOIN).
- Use Case: Identify top users or detect inactive ones.
- Key Fields: user_id, first_name, last_name, total_bookings.
- Sorted By: total_bookings DESC.

### 7. Window Function: Rank Properties by Bookings
- Description: Aggregates bookings per property, then applies RANK() OVER for dense ranking.
- Use Case: Generate property popularity rankings (ties share ranks).
- Key Fields: property_id, property_name, total_bookings, booking_rank.
- Sorted By: booking_rank, then total_bookings DESC.

**Key Points**
- LEFT JOINs ensure completeness (e.g., users/properties with no bookings show 0/count).
- Window functions execute after GROUP BY; partition if needed for subgroups.
- Optimize with indexes on user_id and property_id.
- Alternatives: Use ROW_NUMBER() for unique ranks or DENSE_RANK() for no gaps.



* For schema details, refer to the ALX Airbnb repo. Contribute via pull requests!
