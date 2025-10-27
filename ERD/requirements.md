# alx-airbnb-database

This project is part of the comprehensive ALX Airbnb Database Module, focusing on database design, normalization, schema creation, and seeding. The project simulates a production-level database system of a robust relational database for an Airbnb-like application, emphasizing high standards of design, development, and data handling.

## Database Specification - AirBnB

Entities and Attributes

## User
•	user_id: Primary Key, UUID, Indexed
•	first_name: VARCHAR, NOT NULL
•	last_name: VARCHAR, NOT NULL
•	email: VARCHAR, UNIQUE, NOT NULL
•	password_hash: VARCHAR, NOT NULL
•	phone_number: VARCHAR, NULL
•	role: ENUM (guest, host, admin), NOT NULL
•	created_at: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

## Property
•	property_id: Primary Key, UUID, Indexed
•	host_id: Foreign Key, references User(user_id)
•	name: VARCHAR, NOT NULL
•	description: TEXT, NOT NULL
•	location: VARCHAR, NOT NULL
•	pricepernight: DECIMAL, NOT NULL
•	created_at: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP
•	updated_at: TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP

## Booking
•	booking_id: Primary Key, UUID, Indexed
•	property_id: Foreign Key, references Property(property_id)
•	user_id: Foreign Key, references User(user_id)
•	start_date: DATE, NOT NULL
•	end_date: DATE, NOT NULL
•	total_price: DECIMAL, NOT NULL
•	status: ENUM (pending, confirmed, canceled), NOT NULL
•	created_at: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

## Payment
•	payment_id: Primary Key, UUID, Indexed
•	booking_id: Foreign Key, references Booking(booking_id)
•	amount: DECIMAL, NOT NULL
•	payment_date: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP
•	payment_method: ENUM (credit_card, paypal, stripe), NOT NULL

## Review
•	review_id: Primary Key, UUID, Indexed
•	property_id: Foreign Key, references Property(property_id)
•	user_id: Foreign Key, references User(user_id)
•	rating: INTEGER, CHECK: rating >= 1 AND rating <= 5, NOT NULL
•	comment: TEXT, NOT NULL
•	created_at: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

## Message
•	message_id: Primary Key, UUID, Indexed
•	sender_id: Foreign Key, references User(user_id)
•	recipient_id: Foreign Key, references User(user_id)
•	message_body: TEXT, NOT NULL
•	sent_at: TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

## Constraints

## User Table
•	Unique constraint on email.
•	Non-null constraints on required fields.

## Property Table
•	Foreign key constraint on host_id.
•	Non-null constraints on essential attributes.

## Booking Table
•	Foreign key constraints on property_id and user_id.
•	status must be one of pending, confirmed, or canceled.

## Payment Table
•	Foreign key constraint on booking_id, ensuring payment is linked to valid bookings.

## Review Table
•	Constraints on rating values (1-5).
•	Foreign key constraints on property_id and user_id.

## Message Table
•	Foreign key constraints on sender_id and recipient_id.

## Indexing
•	Primary Keys: Indexed automatically.
•	Additional Indexes:
o	email in the User table.
o	property_id in the Property and Booking tables.
o	booking_id in the Booking and Payment tables.

# Entities and Attributes

User
- user_id: UUID (Primary Key, Indexed)
- first_name: VARCHAR (NOT NULL)
- last_name: VARCHAR (NOT NULL)
- email: VARCHAR (UNIQUE, NOT NULL, Indexed)
- password_hash: VARCHAR (NOT NULL)
- phone_number: VARCHAR (NULL)
- role: ENUM('guest', 'host', 'admin') (NOT NULL)
- created_at: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)
Property
- property_id: UUID (Primary Key, Indexed)
- host_id: UUID (Foreign Key to User.user_id)
- name: VARCHAR (NOT NULL)
- description: TEXT (NOT NULL)
- location: VARCHAR (NOT NULL)
- pricepernight: DECIMAL (NOT NULL)
- created_at: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)
- updated_at: TIMESTAMP (ON UPDATE CURRENT_TIMESTAMP)
Booking
- booking_id: UUID (Primary Key, Indexed)
- property_id: UUID (Foreign Key to Property.property_id, Indexed)
- user_id: UUID (Foreign Key to User.user_id)
- start_date: DATE (NOT NULL)
- end_date: DATE (NOT NULL)
- total_price: DECIMAL (NOT NULL)
- status: ENUM('pending', 'confirmed', 'canceled') (NOT NULL)
- created_at: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)
Payment
- payment_id: UUID (Primary Key, Indexed)
- booking_id: UUID (Foreign Key to Booking.booking_id, Indexed)
- amount: DECIMAL (NOT NULL)
- payment_date: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)
- payment_method: ENUM('credit_card', 'paypal', 'stripe') (NOT NULL)
Review
- review_id: UUID (Primary Key, Indexed)
- property_id: UUID (Foreign Key to Property.property_id)
- user_id: UUID (Foreign Key to User.user_id)
- rating: INTEGER (NOT NULL, CHECK: >=1 AND <=5)
- comment: TEXT (NOT NULL)
- created_at: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)
Message
- message_id: UUID (Primary Key, Indexed)
- sender_id: UUID (Foreign Key to User.user_id)
- recipient_id: UUID (Foreign Key to User.user_id)
- message_body: TEXT (NOT NULL)
- sent_at: TIMESTAMP (DEFAULT CURRENT_TIMESTAMP)

## Relationships Between Entities

The relationships are derived from the foreign key constraints and the logical structure of the database.  These form the basis of the Entity-Relationship (ER) model.

- User to Property (One-to-Many): A single User (host) can own multiple Properties. Connected via Property.host_id → User.user_id.
- Property to Booking (One-to-Many): A single Property can have multiple Bookings. Connected via Booking.property_id → Property.property_id.
- User to Booking (One-to-Many): A single User (guest) can make multiple Bookings. Connected via Booking.user_id → User.user_id.
- Booking to Payment (One-to-One): Each Booking has exactly one Payment (assuming one payment per booking based on the spec). Connected via Payment.booking_id → Booking.booking_id.
- Property to Review (One-to-Many): A single Property can receive multiple Reviews. Connected via Review.property_id → Property.property_id.
- User to Review (One-to-Many): A single User can write multiple Reviews. Connected via Review.user_id → User.user_id.
- User to Message (Sender) (One-to-Many): A single User can send multiple Messages. Connected via Message.sender_id → User.user_id.
- User to Message (Recipient) (One-to-Many): A single User can receive multiple Messages. Connected via Message.recipient_id → User.user_id. (This creates a self-referential many-to-many communication between Users via the Message entity.)

These relationships ensure referential integrity through foreign keys, with ON DELETE CASCADE in the SQL schema to handle deletions appropriately (e.g., deleting a User cascades to their Properties, Bookings, etc.).

## Entity-Relationship (ER) diagram

To view this as an interactive image, copy the code below and paste it into mermaid.live. This will render the full ER diagram with entities, key attributes, relationships, and cardinalities (using crow's foot notation: || for one, o{ for many).

##```

```erDiagram
        direction TB
        USER {
            uuid user_id PK "Primary Key, Indexed"
            varchar first_name "NOT NULL"
            varchar last_name "NOT NULL"
            varchar email "UNIQUE, NOT NULL"
            varchar password_hash "NOT NULL"
            varchar phone_number "NULLABLE"
            enum role "ENUM('guest', 'host', 'admin'), NOT NULL"
            timestamp created_at "DEFAULT CURRENT_TIMESTAMP"
        }
        PROPERTY {
            uuid property_id PK "Primary Key, Indexed"
            uuid host_id FK "Foreign Key to USER.user_id, NOT NULL"
            varchar name "NOT NULL"
            text description "NOT NULL"
            varchar location "NOT NULL"
            decimal price_per_night "NOT NULL"
            timestamp created_at "DEFAULT CURRENT_TIMESTAMP"
            timestamp updated_at "ON UPDATE CURRENT_TIMESTAMP"
        }
        BOOKING {
            uuid booking_id PK "Primary Key, Indexed"
            uuid property_id FK "Foreign Key to PROPERTY.property_id, NOT NULL"
            uuid user_id FK "Foreign Key to USER.user_id, NOT NULL"
            date start_date "NOT NULL"
            date end_date "NOT NULL, CHECK(end_date > start_date)"
            decimal total_price "NOT NULL"
            enum status "ENUM('pending', 'confirmed', 'canceled'), NOT NULL"
            timestamp created_at "DEFAULT CURRENT_TIMESTAMP"
        }
        PAYMENT {
            uuid payment_id PK "Primary Key, Indexed"
            uuid booking_id FK "Foreign Key to BOOKING.booking_id, NOT NULL"
            decimal amount "NOT NULL"
            timestamp payment_date "DEFAULT CURRENT_TIMESTAMP"
            enum payment_method "ENUM('credit_card', 'paypal', 'stripe'), NOT NULL"
            enum payment_status "ENUM('success', 'failed', 'refunded'), DEFAULT 'success'"
        }
        REVIEW {
            uuid review_id PK "Primary Key, Indexed"
            uuid property_id FK "Foreign Key to PROPERTY.property_id, NOT NULL"
            uuid user_id FK "Foreign Key to USER.user_id, NOT NULL"
            integer rating "CHECK(rating >= 1 AND rating <= 5), NOT NULL"
            text comment "NOT NULL"
            timestamp created_at "DEFAULT CURRENT_TIMESTAMP"
            constraint unique_review "UNIQUE(property_id, user_id)"
        }
        MESSAGE {
            uuid message_id PK "Primary Key, Indexed"
            uuid sender_id FK "Foreign Key to USER.user_id, NOT NULL"
            uuid recipient_id FK "Foreign Key to USER.user_id, NOT NULL"
            text message_body "NOT NULL"
            boolean is_read "DEFAULT FALSE"
            timestamp sent_at "DEFAULT CURRENT_TIMESTAMP"
        }
        %% Relationships
        USER ||--o{ PROPERTY : "hosts"
        PROPERTY ||--o{ BOOKING : "is booked in"
        USER ||--o{ BOOKING : "makes"
        BOOKING ||--|| PAYMENT : "has"
        PROPERTY ||--o{ REVIEW : "receives"
        USER ||--o{ REVIEW : "submits"
        USER ||--o{ MESSAGE : "sends"
        USER ||--o{ MESSAGE : "receives"
