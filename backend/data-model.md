# Backend Data Model Design

## Overview

This document describes the PostgreSQL schema for the Sitaara partner-linking app. The design prioritizes data integrity, idempotent operations, and clear authorization boundaries.

---

## Database Entities

### Users
Represents a parent account with authentication and role information.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `email` (VARCHAR, UNIQUE, NOT NULL) — Email address used for login and identification
- `password_hash` (VARCHAR, NOT NULL) — Securely hashed password (bcrypt or similar)
- `role` (ENUM/VARCHAR, NOT NULL) — Either "Mom" or "Dad"
- `child_id` (FK to Children, NOT NULL) — Reference to the shared child
- `created_at` (TIMESTAMP, NOT NULL) — Account creation timestamp

**Constraints:**
- Email must be unique across the system
- Each user is linked to exactly one child (one couple, one child)

**Notes:**
- Password should be hashed using bcrypt, argon2, or similar before storage
- Role is immutable after signup

---

### Children
Represents a shared child profile owned by a couple.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `name` (VARCHAR, NOT NULL) — Child's name
- `date_of_birth` (DATE, NOT NULL) — Child's date of birth
- `created_at` (TIMESTAMP, NOT NULL) — Profile creation timestamp

**Constraints:**
- Name should not be empty

**Notes:**
- Each child is shared between exactly two users (one couple)
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
- `child_id` (FK to Children, NOT NULL) — The child being linked (always the child of the generating user)
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

### Partner Relationships
Tracks mutual partner links between two users on a shared child.

**Fields:**
- `id` (PK, UUID/Serial) — Primary key
- `user_id_1` (FK to Users, NOT NULL) — First user in the relationship
- `user_id_2` (FK to Users, NOT NULL) — Second user in the relationship
- `child_id` (FK to Children, NOT NULL) — The shared child
- `linked_at` (TIMESTAMP, NOT NULL) — When the link was established

**Constraints:**
- `UNIQUE(user_id_1, user_id_2, child_id)` — Prevents duplicate partner relationships
- `user_id_1 < user_id_2` (enforce ordering to prevent both (A, B) and (B, A) existing) — Recommended
- `user_id_1 != user_id_2` (self-linking prevention, enforced at application logic level)

**Notes:**
- Relationships are **symmetric**: if (A, B) exists, it means both A and B are linked to each other
- To find a user's partner: `SELECT * FROM partner_relationships WHERE (user_id_1 = ? OR user_id_2 = ?) AND child_id = ?`
- To check if two users are linked: `SELECT * FROM partner_relationships WHERE (user_id_1 = ? AND user_id_2 = ?) OR (user_id_1 = ? AND user_id_2 = ?) AND child_id = ?`
- Enforce `user_id_1 < user_id_2` at the application layer to avoid duplicates (e.g., don't allow both (1, 2) and (2, 1))

---

## Key Design Decisions

### 1. One Child Per Couple
Each user has a foreign key to a single child in the `users` table. This enforces that:
- A user (parent) is bound to one child for the demo
- Both users in a couple reference the same child
- The relationship is simple and unambiguous

**Future scaling**: If supporting multiple children per couple is needed, a many-to-many junction table (users_children) would replace the direct foreign key.

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

### 4. Symmetric Partner Relationships
Partner relationships are bidirectional and stored as a single record with ordering (user_id_1 < user_id_2) to prevent duplicates:
- If A and B are linked, there is exactly one record with (user_id_1=A, user_id_2=B) or (user_id_1=B, user_id_2=A)
- Recommended: enforce `user_id_1 < user_id_2` at the application layer to maintain consistency
- Queries must check both directions: `(user_id_1 = ? AND user_id_2 = ?) OR (user_id_1 = ? AND user_id_2 = ?)`

### 5. Authorization Boundary
All shared activity queries must verify:
1. The logged-in user is linked to their partner via `partner_relationships` on the shared child
2. The queried data belongs to the shared child only
3. The queried partner data belongs to the linked partner only

Example authorization check (pseudocode):
```
GET /videos/{id}/partner-activity
- User is authenticated
- Video exists
- User and partner are linked on the shared child
- Return partner's like state and progress
```

---

## Entity Relationship Diagram (ERD)

```
┌────────────────┐
│     Users      │
├────────────────┤
│ id (PK)        │
│ email (UNIQUE) │
│ password_hash  │
│ role           │
│ child_id (FK)  │ ──────────┐
│ created_at     │           │
└────────────────┘           │
         │                   │
         │ 1                 │ N
         │                   │
         └──────────┬────────┘
                    │
                    ▼
          ┌──────────────────┐
          │    Children      │
          ├──────────────────┤
          │ id (PK)          │
          │ name             │
          │ date_of_birth    │
          │ created_at       │
          └──────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        │ 1         │ 1         │ N
        │           │           │
        ▼           ▼           ▼
┌──────────────────────────────────────────────┐
│                                              │
│  partner_relationships                       │
│  ├─ id (PK)                                 │
│  ├─ user_id_1 (FK) ──────┐                 │
│  ├─ user_id_2 (FK) ──────┼─────────────────┤
│  ├─ child_id (FK) ────────┘                 │
│  └─ linked_at                               │
│  UNIQUE(user_id_1, user_id_2, child_id)    │
│                                              │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│                                              │
│  invite_codes                                │
│  ├─ id (PK)                                 │
│  ├─ code (UNIQUE)                           │
│  ├─ generated_by_user_id (FK) ────┐        │
│  ├─ redeemed_by_user_id (FK)      ├────────┤
│  ├─ child_id (FK) ─────────────────┤        │
│  ├─ created_at                     │        │
│  └─ redeemed_at                    │        │
│                                    │        │
│  Points to Users (generator)   Points to Users (redeemer)
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
CREATE INDEX idx_users_child_id ON users(child_id);

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

-- Partner Relationships (for finding partners and checking links)
CREATE INDEX idx_partner_relationships_user_id_1 ON partner_relationships(user_id_1);
CREATE INDEX idx_partner_relationships_user_id_2 ON partner_relationships(user_id_2);
CREATE INDEX idx_partner_relationships_child_id ON partner_relationships(child_id);

-- Videos (for browse and lookup)
CREATE INDEX idx_videos_masterclass_id ON videos(masterclass_id);
```

---

## Query Patterns

### Find a user's partner for a shared child
```sql
SELECT CASE
    WHEN user_id_1 = ? THEN user_id_2
    WHEN user_id_2 = ? THEN user_id_1
END AS partner_user_id
FROM partner_relationships
WHERE (user_id_1 = ? OR user_id_2 = ?)
  AND child_id = ?;
```

### Check if two users are linked on a child
```sql
SELECT COUNT(*) > 0 AS is_linked
FROM partner_relationships
WHERE ((user_id_1 = ? AND user_id_2 = ?) OR (user_id_1 = ? AND user_id_2 = ?))
  AND child_id = ?;
```

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
WHERE wp.user_id = ? -- partner's user_id
  AND wp.video_id = ?
  AND EXISTS (
    SELECT 1 FROM partner_relationships pr
    WHERE (pr.user_id_1 = ? AND pr.user_id_2 = ?) 
       OR (pr.user_id_1 = ? AND pr.user_id_2 = ?)
    AND pr.child_id = ?
  );
```

### Get partner's like state for a video (with authorization check)
```sql
SELECT COUNT(*) > 0 AS liked_by_partner
FROM video_likes vl
WHERE vl.user_id = ? -- partner's user_id
  AND vl.video_id = ?
  AND EXISTS (
    SELECT 1 FROM partner_relationships pr
    WHERE (pr.user_id_1 = ? AND pr.user_id_2 = ?) 
       OR (pr.user_id_1 = ? AND pr.user_id_2 = ?)
    AND pr.child_id = ?
  );
```

### Redeem an invite code (with transaction and locking)
```sql
BEGIN TRANSACTION;
SELECT id, generated_by_user_id, redeemed_by_user_id, child_id
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
  
  INSERT INTO partner_relationships (user_id_1, user_id_2, child_id, linked_at)
  VALUES (MIN(generated_by_user_id, ?), MAX(generated_by_user_id, ?), child_id, NOW());
  
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

1. **Transactions**: Critical operations (invite code redemption, partner linking) must use database transactions with proper isolation levels to prevent race conditions.

2. **Timestamp Handling**: All timestamps should be stored in UTC. Use `NOW()` or the equivalent in your language/driver.

3. **Foreign Key Constraints**: Enable foreign key constraints to prevent orphaned records.

4. **Password Hashing**: Never store plaintext passwords. Use bcrypt, argon2, or scrypt with appropriate cost factors.

5. **Nullable Fields**: Only `redeemed_by_user_id`, `redeemed_at`, and `description` should be nullable; all other fields should be NOT NULL.

6. **Delete Cascades**: Consider whether deletions should cascade or be prevented by foreign key constraints (generally safer to prevent deletion of referenced records).

7. **Audit Trail**: Consider adding `updated_at` timestamps to track when records are modified (optional but useful for debugging).
