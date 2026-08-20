# Backend Data Model Design

## Overview

This document describes the PostgreSQL schema for the Sitaara partner-linking app. The design prioritizes data integrity, idempotent operations, and clear authorization boundaries.

---

## Database Entities

### Families
Represents a couple/household — the shared anchor that both parent accounts and their child(ren) hang off of.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `created_at` (TIMESTAMP, NOT NULL) — Family creation timestamp

**Notes:**
- Both `users` and `children` reference `family_id` directly, so any "shared between partners" query is a single `WHERE family_id = ?` — no join table required
- Created either when the first parent signs up without an invite code, or resolved from the invite code when a second parent joins

---

### Users
Represents a parent account with authentication and role information.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `email` (VARCHAR, UNIQUE, NOT NULL) — Email address used for login and identification
- `password_hash` (VARCHAR, NOT NULL) — Securely hashed password (bcrypt or similar)
- `role` (ENUM/VARCHAR, NOT NULL) — Either "Mom" or "Dad"
- `family_id` (FK to Families, NOT NULL) — Reference to the shared family
- `created_at` (TIMESTAMP, NOT NULL) — Account creation timestamp

**Constraints:**
- Email must be unique across the system
- Each user belongs to exactly one family
- `UNIQUE(family_id, role)` — a family can have at most one `mom`, one `dad`, and one `guardian` (in practice, at most two users total for the current scope)

**Notes:**
- Password should be hashed using bcrypt, argon2, or similar before storage
- Role is immutable after signup

---

### Children
Represents a shared child profile owned by a family.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `family_id` (FK to Families, NOT NULL) — Reference to the owning family
- `name` (VARCHAR, NOT NULL) — Child's name
- `date_of_birth` (DATE, NOT NULL) — Child's date of birth
- `created_at` (TIMESTAMP, NOT NULL) — Profile creation timestamp

**Constraints:**
- Name should not be empty

**Notes:**
- A family may eventually contain multiple children; for the current scope each family has exactly one
- The demo only requires one child instance, but the schema is designed to be extensible for future features

---

### Masterclasses
Represents a module or mini-course containing multiple videos.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `title` (VARCHAR, NOT NULL) — Title of the masterclass
- `description` (TEXT, NULLABLE) — Detailed description
- `created_at` (TIMESTAMP, NOT NULL) — Creation timestamp

**Constraints:**
- Title should not be empty

**Notes:**
- Seeded with 2 masterclasses at initialization

---

### Videos
Represents a single playable video within a masterclass.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `title` (VARCHAR, NOT NULL) — Video title
- `duration_seconds` (INTEGER, NOT NULL) — Real video duration in seconds (required for watch progress to be meaningful)
- `masterclass_id` (FK to Masterclasses, NOT NULL) — Reference to parent masterclass
- `video_url` (TEXT, NOT NULL) — URL to the playable video (must be publicly accessible)
- `created_at` (TIMESTAMP, NOT NULL) — Creation timestamp

**Constraints:**
- Duration must be > 0
- Video URL must be valid and accessible
- Each video belongs to exactly one masterclass

**Notes:**
- Seeded with 4–5 videos per masterclass
- Video URLs can be hosted on YouTube, Vimeo, public CDN, or self-hosted (requirement is only that they have real durations)

---

### Video Likes
Tracks which users have liked which videos (many-to-many with metadata).

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `user_id` (FK to Users, NOT NULL) — User who liked the video
- `video_id` (FK to Videos, NOT NULL) — Video that was liked
- `created_at` (TIMESTAMP, NOT NULL) — Like timestamp

**Constraints:**
- `UNIQUE(user_id, video_id)` — Ensures each user can only like a video once; prevents duplicates

**Notes:**
- Idempotent operation: attempting to like the same video twice should be a no-op or soft-delete the prior like (toggle behavior)
- To check if a user likes a video: `SELECT * FROM video_likes WHERE user_id = ? AND video_id = ?`

---

### Watch Progress
Tracks how far each user has watched in each video (one record per user per video).

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `user_id` (FK to Users, NOT NULL) — User watching the video
- `video_id` (FK to Videos, NOT NULL) — Video being watched
- `watched_seconds` (INTEGER, NOT NULL) — Current position in the video (in seconds)
- `last_updated_at` (TIMESTAMP, NOT NULL) — When this progress was last updated

**Constraints:**
- `UNIQUE(user_id, video_id)` — Ensures one progress record per user per video
- `watched_seconds >= 0`
- `watched_seconds <= duration_seconds` (enforced at application logic level if not at DB level)

**Notes:**
- Idempotent updates: if a client reports watched_seconds = 100s but the current record is 150s, keep 150s (furthest-watched wins)
- On update: only update if `new_watched_seconds > old_watched_seconds`
- To get a user's progress on a video: `SELECT watched_seconds, last_updated_at FROM watch_progress WHERE user_id = ? AND video_id = ?`

---

### Invite Codes
Tracks invite codes for partner linking, including generation and redemption state.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `code` (VARCHAR, UNIQUE, NOT NULL) — The human-readable invite code (e.g., "ABC123XYZ")
- `generated_by_user_id` (FK to Users, NOT NULL) — User who generated the code
- `redeemed_by_user_id` (FK to Users, NULLABLE) — User who redeemed the code (NULL until redeemed)
- `family_id` (FK to Families, NOT NULL) — The family being joined (always the family of the generating user)
- `created_at` (TIMESTAMP, NOT NULL) — When the code was generated
- `redeemed_at` (TIMESTAMP, NULLABLE) — When the code was redeemed (NULL until redeemed)

**Constraints:**
- Code must be unique and non-empty
- Code can only be redeemed once (check `redeemed_by_user_id IS NOT NULL` to determine if used)
- `generated_by_user_id != redeemed_by_user_id` (self-linking prevention, enforced at application logic level)

**Notes:**
- Single-use: once `redeemed_by_user_id` is set, the code is consumed and cannot be used again
- To find redeemable codes: `SELECT * FROM invite_codes WHERE code = ? AND redeemed_by_user_id IS NULL`
- To prevent concurrent redemptions, use database transactions and row-level locking (e.g., `SELECT ... FOR UPDATE`)
- Code format is a design decision (e.g., 6–8 alphanumeric characters, UUID, etc.)

---

## Key Design Decisions

### 1. One Family Per Couple
Each user has a foreign key to a single family in the `users` table, and each child has a foreign key to the family that owns it. This enforces that:
- A user (parent) is bound to one family
- Both users in a couple reference the same family, and any children they share reference that same family
- The relationship is simple and unambiguous, and already supports multiple children per family natively (`children.family_id` is one-to-many) — no junction table needed for that scaling case

### 2. Idempotent Watch Progress
Watch progress is stored as a single record per user per video with a `UNIQUE(user_id, video_id)` constraint. Updates are idempotent via the "furthest-watched wins" rule:
- On each update, only persist if `new_watched_seconds > old_watched_seconds`
- Prevents progress from ever going backwards
- Handles network retries and out-of-order updates gracefully

### 3. Single-Use Invite Codes
Invite codes are consumed immediately upon redemption:
- `redeemed_by_user_id` is NULL until used
- Once set, the code cannot be reused
- Prevents replay attacks and accidental double-linking

**Concurrent safety**: Use database transactions with row-level locking (`SELECT ... FOR UPDATE`) when redeeming to ensure only one user can redeem a code simultaneously.

### 4. Family Membership
Two users are partners simply by sharing the same `family_id` — no separate relationship table or bidirectional record-keeping is needed:
- To find a user's partner: `SELECT * FROM users WHERE family_id = ? AND id != ?`
- "Are these two users linked?" is just `u1.family_id = u2.family_id`, comparable directly from two already-loaded rows

### 5. Authorization Boundary
All shared activity queries must verify:
1. The logged-in user and the target user share the same `family_id`
2. The queried data belongs to the shared family (via its owning user or child) only
3. The queried partner data belongs to the linked partner only

Example authorization check (pseudocode):
```
GET /videos/{id}/partner-activity
- User is authenticated
- Video exists
- User and partner share the same family_id
- Return partner's like state and progress
```

---

## Entity Relationship Diagram (ERD)

```
                    ┌──────────────────┐
                    │     Families      │
                    ├──────────────────┤
                    │ id (PK)          │
                    │ created_at       │
                    └──────────────────┘
                       │             │
                       │ 1           │ 1
                       │             │
                       │ N           │ N
                       ▼             ▼
        ┌────────────────┐   ┌──────────────────┐
        │     Users      │   │    Children      │
        ├────────────────┤   ├──────────────────┤
        │ id (PK)        │   │ id (PK)          │
        │ email (UNIQUE) │   │ family_id (FK)   │
        │ password_hash  │   │ name             │
        │ role           │   │ date_of_birth    │
        │ family_id (FK) │   │ created_at       │
        │ created_at     │   └──────────────────┘
        │ UNIQUE(family  │
        │  _id, role)    │
        └────────────────┘

┌──────────────────────────────────────────────┐
│                                              │
│  invite_codes                                │
│  ├─ id (PK)                                 │
│  ├─ code (UNIQUE)                           │
│  ├─ generated_by_user_id (FK) ────┐        │
│  ├─ redeemed_by_user_id (FK)      ├────────┤
│  ├─ family_id (FK) ────────────────┤        │
│  ├─ created_at                     │        │
│  └─ redeemed_at                    │        │
│                                    │        │
│  Points to Users (generator)   Points to Users (redeemer)
│  family_id points to Families                │
│                                              │
└──────────────────────────────────────────────┘

┌────────────────┐
│ Masterclasses  │
├────────────────┤
│ id (PK)        │
│ title          │
│ description    │
│ created_at     │
└────────────────┘
        │
        │ 1
        │
        │ N
        ▼
┌──────────────────────┐
│     Videos           │
├──────────────────────┤
│ id (PK)              │
│ title                │
│ duration_seconds     │
│ masterclass_id (FK)  │
│ video_url            │
│ created_at           │
└──────────────────────┘
        │
        ├────────────────────────┐
        │                        │
        │ 1                      │ 1
        │                        │
        │ N                      │ N
        │                        │
        ▼                        ▼
┌────────────────┐      ┌──────────────────┐
│  Video Likes   │      │ Watch Progress   │
├────────────────┤      ├──────────────────┤
│ id (PK)        │      │ id (PK)          │
│ user_id (FK)   │      │ user_id (FK)     │
│ video_id (FK)  │      │ video_id (FK)    │
│ created_at     │      │ watched_seconds  │
│ UNIQUE(user    │      │ last_updated_at  │
│  _id, video_id)│      │ UNIQUE(user_id,  │
└────────────────┘      │  video_id)       │
        │               └──────────────────┘
        │                       │
        └───────────┬───────────┘
                    │
                    │ N:1
                    │
                    ▼
            ┌────────────────┐
            │     Users      │
            │ (user_id FK)   │
            └────────────────┘
```

---

## Indexing Recommendations

For optimal query performance, consider the following indexes:

```sql
-- Users
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_family_id ON users(family_id);

-- Children
CREATE INDEX idx_children_family_id ON children(family_id);

-- Video Likes (for quick lookup)
CREATE INDEX idx_video_likes_user_id ON video_likes(user_id);
CREATE INDEX idx_video_likes_video_id ON video_likes(video_id);

-- Watch Progress (for quick lookup)
CREATE INDEX idx_watch_progress_user_id ON watch_progress(user_id);
CREATE INDEX idx_watch_progress_video_id ON watch_progress(video_id);

-- Invite Codes (for code lookup and status checks)
CREATE UNIQUE INDEX idx_invite_codes_code ON invite_codes(code);
CREATE INDEX idx_invite_codes_generated_by ON invite_codes(generated_by_user_id);
CREATE INDEX idx_invite_codes_redeemed_by ON invite_codes(redeemed_by_user_id);
CREATE INDEX idx_invite_codes_family_id ON invite_codes(family_id);

-- Videos (for browse and lookup)
CREATE INDEX idx_videos_masterclass_id ON videos(masterclass_id);
```

---

## Query Patterns

### Find a user's partner in the same family
```sql
SELECT * FROM users
WHERE family_id = ? AND id != ?;
```

### Check if two users are linked
No query needed — compare two already-loaded rows' `family_id` values directly (`u1.family_id = u2.family_id`).

### Get a user's watch progress for a video
```sql
SELECT watched_seconds, last_updated_at
FROM watch_progress
WHERE user_id = ? AND video_id = ?;
```

### Get partner's watch progress for a video (with authorization check)
```sql
SELECT wp.watched_seconds, wp.last_updated_at
FROM watch_progress wp
JOIN users u ON u.id = wp.user_id
WHERE wp.video_id = ?
  AND u.family_id = (SELECT family_id FROM users WHERE id = ?) -- requesting user's family
  AND u.id != ?; -- exclude the requesting user, return only the partner
```

### Get partner's like state for a video (with authorization check)
```sql
SELECT COUNT(*) > 0 AS liked_by_partner
FROM video_likes vl
JOIN users u ON u.id = vl.user_id
WHERE vl.video_id = ?
  AND u.family_id = (SELECT family_id FROM users WHERE id = ?) -- requesting user's family
  AND u.id != ?; -- exclude the requesting user, return only the partner
```

### Redeem an invite code (with transaction and locking)
```sql
BEGIN TRANSACTION;
SELECT id, generated_by_user_id, redeemed_by_user_id, family_id
FROM invite_codes
WHERE code = ?
FOR UPDATE; -- Lock the row

-- Check if already redeemed
IF redeemed_by_user_id IS NOT NULL THEN
  ROLLBACK; -- Already used
ELSE
  UPDATE invite_codes
  SET redeemed_by_user_id = ?, redeemed_at = NOW()
  WHERE code = ?;

  -- No separate relationship row needed: the redeeming user is simply
  -- created with family_id = invite_codes.family_id.

  COMMIT;
END IF;
```

---

## Seed Data

The application should seed the database with:

**Masterclass 1**
- Title: (Design decision — e.g., "Early Child Development")
- 4–5 videos with real durations

**Masterclass 2**
- Title: (Design decision — e.g., "Parenting Wellness")
- 4–5 videos with real durations

Example seed script:
```sql
INSERT INTO masterclasses (id, title, description, created_at)
VALUES 
  (1, 'Early Child Development', '...', NOW()),
  (2, 'Parenting Wellness', '...', NOW());

INSERT INTO videos (id, title, duration_seconds, masterclass_id, video_url, created_at)
VALUES 
  (1, 'Video 1', 600, 1, 'https://...', NOW()),
  (2, 'Video 2', 480, 1, 'https://...', NOW()),
  -- ... etc
```

---

## Migration Strategy

Use a database migration tool (e.g., Go's `migrate` package, or Flyway) to manage schema changes:

1. Create initial schema on first deployment
2. Version all migrations
3. Apply migrations in order on app startup (or via CI/CD)
4. Test migrations in development environment before production deployment

Example migration file (UP):
```sql
-- migrations/001_initial_schema.up.sql
CREATE TABLE children (...)
CREATE TABLE users (...)
CREATE TABLE masterclasses (...)
-- ... etc
```

---

## Notes for Implementation

1. **Transactions**: Critical operations (invite code redemption) must use database transactions with proper isolation levels to prevent race conditions.

2. **Timestamp Handling**: All timestamps should be stored in UTC. Use `NOW()` or the equivalent in your language/driver.

3. **Foreign Key Constraints**: Enable foreign key constraints to prevent orphaned records.

4. **Password Hashing**: Never store plaintext passwords. Use bcrypt, argon2, or scrypt with appropriate cost factors.

5. **Nullable Fields**: Only `redeemed_by_user_id`, `redeemed_at`, and `description` should be nullable; all other fields should be NOT NULL.

6. **Delete Cascades**: Consider whether deletions should cascade or be prevented by foreign key constraints (generally safer to prevent deletion of referenced records).

7. **Audit Trail**: Consider adding `updated_at` timestamps to track when records are modified (optional but useful for debugging).
