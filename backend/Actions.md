# System Actions & Workflows

This document outlines all system actions, their requirements, validation steps, and the business logic that occurs when they are triggered.

---

## 1. User Creation

**Trigger:** POST /users (or equivalent endpoint)

**Payload Parameters:**

- `email` (string, required)
- `password` (string, required)
- `role` (string, required)
- `inviteCode` (string, optional)
- `childName` (string, conditional) - required if inviteCode not provided
- `childDob` (string, conditional) - required if inviteCode not provided (ISO 8601 format: YYYY-MM-DD)

**Workflow:**

### Case 1: With Invite Code

1. **Validate Invite Code**
    - Check if invite code exists in the database
    - Verify it is still active (not expired, not revoked)
    - If invalid or expired → Return 400/401 error
    - If valid → Proceed to step 2

2. **Retrieve Associated Child**
    - Query invite code to get associated child_id
    - Retrieve child record by child_id
    - If child not found → Return 400 error (invalid invite code data)
    - If child is deleted/inactive → Return 400 error

3. **Validate User Data**
    - Check if email already exists in system
    - If exists → Return 409 Conflict (email already registered)
    - Validate password meets requirements (length, complexity, etc.)
    - If invalid → Return 400 error

4. **Create User**
    - Hash password
    - Create user record with:
        - email
        - hashed password
        - role
        - child_id (from retrieved child)
    - Link user to invite code (update invite code record with user_id)
    - Mark invite code as used
    - Update invite code status to "claimed"

5. **Issue Auth Token**
    - Mint a JWT (HS256) with `sub` = user_id and `role` as claims, valid for 30 days

6. **Return Success**
    - Return 201 Created with:
        - user_id
        - email
        - role
        - child_id
        - child information (name, dob)
        - token (JWT for immediate authenticated access, no separate sign-in required)

### Case 2: Without Invite Code

1. **Validate Required Payload**
    - Check if childName is provided
    - If missing → Return 400 error (childName required)
    - Check if childDob is provided
    - If missing → Return 400 error (childDob required)
    - Validate childDob format (ISO 8601 YYYY-MM-DD)
    - If invalid format → Return 400 error

2. **Validate User Data**
    - Check if email already exists in system
    - If exists → Return 409 Conflict
    - Validate password meets requirements
    - If invalid → Return 400 error
    - Validate role is supported
    - If invalid → Return 400 error

3. **Create Child**
    - Create child record with:
        - name (from childName)
        - dob (from childDob)
        - created_at (current timestamp)
        - status (active)
    - Retrieve generated child_id
    - If creation fails → Return 500 error

4. **Create User**
    - Hash password
    - Create user record with:
        - email
        - hashed password
        - role
        - child_id (from newly created child)
    - Return with user and child information

5. **Issue Auth Token**
    - Mint a JWT (HS256) with `sub` = user_id and `role` as claims, valid for 30 days

6. **Return Success**
    - Return 201 Created with:
        - user_id
        - email
        - role
        - child_id
        - child information (name, dob)
        - token (JWT for immediate authenticated access, no separate sign-in required)

**Error Scenarios:**

- Invalid/expired invite code → 400 Bad Request
- Invite code has no associated child → 400 Bad Request
- Associated child not found or inactive → 400 Bad Request
- Email already registered → 409 Conflict
- Invalid password → 400 Bad Request
- Invalid role → 400 Bad Request
- childName not provided (without invite code) → 400 Bad Request
- childDob not provided (without invite code) → 400 Bad Request
- Invalid childDob format → 400 Bad Request
- Child creation failed → 500 Internal Server Error

**Business Logic Notes:**

- Child must exist before user creation (either pre-created via invite or created in this request)
- One user per child (enforce unique child_id in users table)
- Invite codes are reusable until claimed (after claiming, child is associated with a user)
- Invite codes automatically transition from "active" to "claimed" status upon successful user creation

---

## 2. User Sign In

**Trigger:** POST /auth/signin (or equivalent endpoint)

**Payload Parameters:**

- `email` (string, required)
- `password` (string, required)

**Workflow:**

1. **Validate Input**
    - Check if email and password are provided
    - If missing → Return 400 Bad Request

2. **Retrieve User**
    - Query user by email
    - If user not found → Return 401 Unauthorized
    - If user is deleted/inactive → Return 401 Unauthorized

3. **Verify Password**
    - Retrieve stored hashed password from user record
    - Compare provided password with stored hash using bcrypt or similar
    - If password doesn't match → Return 401 Unauthorized (same generic error/code as "user not found" — never reveal whether the email is registered)

4. **Create Token**
    - Generate JWT (HS256) with `sub` = user_id and `role` as claims, valid for 30 days — same issuer/TTL used by User Creation, so tokens from either endpoint are interchangeable

5. **Return Success**
    - Return 200 OK with:
        - User ID
        - User email
        - User role
        - Auth token/JWT
        - Token expiration time

**Error Scenarios:**

- Email not provided → 400 Bad Request
- Password not provided → 400 Bad Request
- User not found → 401 Unauthorized (`invalid_credentials`)
- Invalid password → 401 Unauthorized (`invalid_credentials`, identical to "user not found")
- Database error → 500 Internal Server Error

**Not implemented (schema/scope gaps, same treatment as invite-expiry in §1):**

- Account-status/ban check — no status column exists on `users` and no ban/suspend feature exists anywhere yet
- last_login/last_activity tracking — no such columns exist on `users`
- Rate limiting / login-attempt lockout — no infra for this yet
- Refresh token — out of scope; client re-authenticates via sign-in once the 30-day token expires

**Security Considerations:**

- Do not reveal whether email exists in error messages (use generic "invalid credentials")
- Implement rate limiting on sign-in attempts to prevent brute force
- Use secure password hashing (bcrypt, argon2, etc.)
- Consider implementing login attempt tracking and temporary lockout after N failures
- Log all sign-in attempts (especially failures)
- Use HTTPS/TLS for all authentication endpoints

---

## 3. Invite Code Creation

**Trigger:** POST /invite-codes (or equivalent endpoint)

**Payload Parameters:**

- `userId` (string, required - from authenticated request)

**Workflow:**

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Retrieve user ID from auth context

2. **Check for Active Invite Code**
    - Query database for active (non-expired, non-revoked) invite codes created by this user
    - If active code exists → Proceed to step 3
    - If no active code exists → Proceed to step 4

3. **Delete Previous Invite Code**
    - Mark previous invite code as revoked/inactive
    - OR delete the record entirely (depending on audit requirements)
    - Proceed to step 4

4. **Generate New Invite Code**
    - Generate unique, random invite code (e.g., 12-character alphanumeric string)
    - Set expiration time (configurable, e.g., 30 days from now)
    - Create invite code record with:
        - Code string
        - Creator user_id
        - Created timestamp
        - Expiration timestamp
        - Status (active)

5. **Return Success**
    - Return 201 Created with generated invite code and expiration time

**Error Scenarios:**

- User not authenticated → 401 Unauthorized
- User not found → 404 Not Found
- Database error during creation → 500 Internal Server Error

**Business Logic Notes:**

- Only one active invite code per user at a time
- Previous codes are automatically invalidated
- Codes expire after configured duration (default: 30 days)

---

## 4. Masterclass - Aggregate Partner Information

**Trigger:** GET /users/{userId}/masterclass (or equivalent endpoint)

**Path Parameters:**

- `userId` (string, required - from authenticated request or path)

**Query Parameters:**

- `masterclassId` (string, optional - if provided, aggregate for specific masterclass)

**Workflow:**

### Case 1: Aggregate All Masterclasses for a User

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Verify user has permission to view this data (own data or admin)

2. **Retrieve User's Video Interactions**
    - Query all videos the user has interacted with
    - Get likes and watch progress for each video

3. **Group by Masterclass**
    - For each video, retrieve associated masterclass ID
    - Group video metrics by masterclass

4. **Aggregate Metrics Per Masterclass**
    - For each masterclass:
        - Count total videos watched (progress > 0)
        - Count total videos liked
        - Calculate average watch progress (%)
        - Count total videos in masterclass
        - Calculate completion percentage

5. **Retrieve Partner Information**
    - For each masterclass, get associated partner/instructor info
    - Include partner name, image, bio, etc.

6. **Build Response**
    - Structure data as array of masterclass summaries with:
        - Masterclass ID and name
        - Partner information
        - User's engagement metrics (likes, watches, progress)
        - Overall completion status

7. **Return Success**
    - Return 200 OK with aggregated data

### Case 2: Aggregate Specific Masterclass

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Verify permission to view data

2. **Retrieve Masterclass**
    - Query masterclass by ID
    - If not found → Return 404 error

3. **Retrieve Partner Information**
    - Get partner/instructor details for this masterclass

4. **Retrieve User's Video Interactions for This Masterclass**
    - Query all videos in this masterclass
    - Get user's like status for each video
    - Get user's watch progress for each video

5. **Aggregate Metrics**
    - Count liked videos
    - Count videos with progress > 0
    - Calculate average watch progress
    - Calculate completion percentage

6. **Build Response**
    - Include masterclass details, partner info, and user metrics

7. **Return Success**
    - Return 200 OK with aggregated data

**Error Scenarios:**

- User not authenticated → 401 Unauthorized
- Masterclass not found → 404 Not Found
- User lacks permission → 403 Forbidden

**Data Structures Involved:**

- `users` table
- `masterclasses` table
- `partners` table
- `videos` table
- `user_video_likes` table
- `user_video_progress` table

---

## 5. Video - Like/Unlike & Watch Progress

**Trigger:**

- POST /videos/{videoId}/like (like)
- DELETE /videos/{videoId}/like (unlike)
- PUT /videos/{videoId}/progress (update progress)

### 5.1 Like Video

**Path Parameters:**

- `videoId` (string, required)

**Workflow:**

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Retrieve user ID from auth context

2. **Validate Video**
    - Query video by ID
    - If not found → Return 404 error
    - Verify video is not deleted

3. **Check Existing Like**
    - Query user_video_likes for this (userId, videoId) combination
    - If like already exists → Return 409 Conflict (already liked)

4. **Create Like Record**
    - Insert record into user_video_likes table with:
        - user_id
        - video_id
        - created_at (current timestamp)
        - status (active)

5. **Update Video Metrics** (optional)
    - Increment video's like_count

6. **Return Success**
    - Return 201 Created with like record details

**Error Scenarios:**

- User not authenticated → 401 Unauthorized
- Video not found → 404 Not Found
- Already liked → 409 Conflict

---

### 5.2 Unlike Video

**Path Parameters:**

- `videoId` (string, required)

**Workflow:**

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Retrieve user ID from auth context

2. **Validate Video**
    - Query video by ID
    - If not found → Return 404 error

3. **Check Existing Like**
    - Query user_video_likes for this (userId, videoId) combination
    - If no like exists → Return 404 error (not liked)

4. **Delete Like Record**
    - Delete the like record from user_video_likes table
    - OR Mark as inactive/deleted (depends on audit requirements)

5. **Update Video Metrics** (optional)
    - Decrement video's like_count

6. **Return Success**
    - Return 200 OK or 204 No Content

**Error Scenarios:**

- User not authenticated → 401 Unauthorized
- Video not found → 404 Not Found
- Like doesn't exist → 404 Not Found

---

### 5.3 Update Watch Progress

**Path Parameters:**

- `videoId` (string, required)

**Payload Parameters:**

- `progress` (number, required) - percentage watched (0-100)
- `currentTime` (number, optional) - current playback position in seconds
- `totalDuration` (number, optional) - total video duration in seconds

**Workflow:**

1. **Authenticate Request**
    - Verify requesting user is authenticated
    - Retrieve user ID from auth context

2. **Validate Video**
    - Query video by ID
    - If not found → Return 404 error
    - Retrieve video's total_duration

3. **Validate Progress Data**
    - Validate progress is numeric and 0 ≤ progress ≤ 100
    - If invalid → Return 400 error
    - Validate currentTime is numeric and non-negative (if provided)
    - If invalid → Return 400 error

4. **Check Existing Progress Record**
    - Query user_video_progress for this (userId, videoId) combination
    - If exists → Proceed to step 5
    - If not exists → Proceed to step 6

5. **Update Progress Record**
    - Update user_video_progress with:
        - progress (new value, only if higher than current)
        - current_time (if provided)
        - updated_at (current timestamp)
        - status (update to completed if progress == 100)
    - Return 200 OK

6. **Create New Progress Record**
    - Insert record into user_video_progress with:
        - user_id
        - video_id
        - progress
        - current_time (if provided)
        - total_duration (if provided)
        - created_at (current timestamp)
        - updated_at (current timestamp)
        - status (in_progress or completed based on progress value)
    - Return 201 Created

7. **Trigger Additional Logic** (if applicable)
    - If progress == 100:
        - Mark as completed
        - Award any badges/achievements if applicable
        - Check if entire masterclass is completed
    - If progress > previous progress:
        - Update user's last_activity timestamp

**Error Scenarios:**

- User not authenticated → 401 Unauthorized
- Video not found → 404 Not Found
- Invalid progress value → 400 Bad Request
- Invalid time data → 400 Bad Request

**Business Logic Notes:**

- Progress should never decrease (only increase)
- Only update if new progress > current progress
- Watch progress tracking enables resume functionality
- Completion status changes trigger potential notifications/badges

---

## Data Dependencies

### Tables Required:

- `users` - User accounts
- `invite_codes` - Invite code records
- `masterclasses` - Masterclass/course records
- `partners` - Partner/instructor information
- `videos` - Video content
- `user_video_likes` - Like status per user-video
- `user_video_progress` - Watch progress per user-video

### Relationships:

- masterclasses → partners (many-to-one)
- videos → masterclasses (many-to-one)
- user_video_likes → users + videos (many-to-many junction)
- user_video_progress → users + videos (many-to-many junction)
- invite_codes → users (one-to-one, user_id nullable until used)

---

## Transaction Considerations

**Atomic Operations Required:**

- User Creation: Create user + process invite code (if provided)
- Invite Code Creation: Delete old code + create new code
- Like/Unlike: Update like record + update video metrics
- Watch Progress: Create/update progress + update completion status

**Idempotent Operations:**

- Watch Progress updates should be idempotent (only increase)
- Like operations should validate existing state before creating
- Unlike operations should validate like exists before deleting

---

## Audit & Logging

Consider logging for:

- User creation (especially with invite codes)
- Invite code generation
- Like/unlike actions
- Watch progress milestones (e.g., 50%, 100% completion)
- Masterclass completion events
