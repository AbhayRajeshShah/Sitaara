# Sitaara Full-Stack Engineering Assignment

## Overview / Objective

Build a minimal, complete slice of the Sitaara parenting app that demonstrates:
- Two parents linking their accounts as co-parents on a shared child
- Each parent seeing the other's activity on shared educational content

The core concept: **parenting is a team sport** — both parents share one subscription and one child profile.

The app must be a **standalone, end-to-end functioning demo** (not reliant on the Sitaara codebase), **hosted and live**, ready for testing.

---

## Functional Requirements

### 1. Accounts & Child Profile
- **Sign up / Log in**: Email + password authentication (no additional complexity required)
- **User role assignment**: Each user selects either "Mom" or "Dad" at signup
- **Shared child profile**: One child per couple with:
  - Child name
  - Child date of birth
- **Demo scope**: Support exactly **one couple (two users) and one child**

### 2. Content Library (Seeded)
- **Masterclasses**: Seed exactly **2 masterclasses** (modules / mini-courses)
- **Videos per masterclass**: Each masterclass contains **4–5 videos**
- **Video library features**:
  - Real video durations (required for meaningful watch-progress tracking)
  - Use any sample videos
- **User experience flow**: Browse masterclasses → open a masterclass → view its videos → play a video

### 3. Video Player & Per-User Actions
- **Video player**: Plays video and tracks watch progress (how far through the video the user has watched)
- **Watch progress reporting**: Report watch progress to the backend
- **Like / Unlike**: Each user can like or unlike a video
- **Per-user tracking** (stored and queryable):
  - Like state for every video
  - Watch progress for every video
  - Derived: progress through each masterclass

### 4. Partner Linking
- **Invite code generation**: One user generates an invite code
- **Invite code redemption**: The other user enters the code to link accounts as co-parents on the same child
- **Mutual linking**: Once linked, both partners can see each other's activity
- **One-way flow**: Linking is initiated by one user, redeemed by the other (both become linked to each other)

### 5. Shared Activity (Core Feature)
Once two accounts are linked, each partner sees the other's activity on the shared content:

#### On a Video:
- If partner has liked it: show `❤ Liked by Mom / Dad` (or the partner's role)
- Show partner's watch status as one of:
  - Not started
  - Watching ~50% (or similar progress indicator)
  - Completed

#### On a Masterclass:
- Show partner's overall progress: e.g., "Dad has completed 3/5 videos (~60%)"
- Indicate when partner is currently watching that masterclass (has a video in progress)
- The exact definition of "masterclass %" and "currently watching" is a **design decision** — must be sensible and explained in the write-up

#### Propagation:
- If a user likes a video on Account 1, Account 2 (once linked) should see it was liked by their partner
- If a user watches 50% of a video or masterclass on Account 1, Account 2 should see that their partner has watched that %

---

## Entities and Concepts Mentioned

- **User**: A parent account with email, password, and role (Mom or Dad)
- **Child**: A shared profile with name and date of birth (one per couple)
- **Masterclass**: A module / mini-course containing multiple videos
- **Video**: A playable video with real duration and content URL
- **Invite Code**: A redeemable code that links two users as partners on a shared child
- **Watch Progress**: Per-user state tracking how far through a video or masterclass a user has watched
- **Like State**: Per-user boolean indicating whether a user has liked a video
- **Partner Relationship**: A mutual link between two users indicating they share a child profile and can see each other's activity
- **Shared Activity**: The aggregated view of a partner's likes and progress visible after linking

---

## Required Functionality

### Authentication & Account Management
- User sign-up with email + password
- User login with email + password
- User role selection (Mom / Dad)
- Child profile creation (name, date of birth) — one per couple
- Session management to maintain login state

### Content Management
- Display list of seeded masterclasses
- Display list of videos within a masterclass
- Play videos with real durations
- Track and report watch progress to the backend

### User Actions & Progress Tracking
- Like a video
- Unlike a video
- Update watch progress for a video (reporting current position to backend)
- Derive masterclass progress from video progress
- Retrieve stored like state and watch progress for display

### Partner Linking
- Generate invite code (user must be authenticated)
- Display invite code to the generating user
- Enter/redeem invite code (user must be authenticated, must be a different user)
- Validate that code can only be redeemed once
- Validate that code cannot be redeemed by more than one partner
- Prevent a user from linking to themselves
- Prevent re-linking of already-linked users

### Shared Activity Visibility
- Retrieve partner's like state for videos (only if linked)
- Retrieve partner's watch progress for videos (only if linked)
- Retrieve partner's masterclass progress (only if linked)
- Retrieve partner's "currently watching" state (only if linked)
- Display partner activity on video detail and masterclass detail views
- Refresh partner activity when user returns to the app (consistency on refresh; live updates optional)

---

## Data-Related Requirements

### Data Storage
- **Persistent database**: Real, hosted PostgreSQL instance (not localhost)
- **Seeded content**: 2 masterclasses and 4–5 videos per masterclass must be seeded at initialization

### Data Models Required
The following entities must be stored and queryable:

1. **Users**: Email, password hash, role (Mom/Dad), created_at
2. **Children**: Name, date of birth, created_at
3. **Child Ownership**: Relationship linking users to their shared child
4. **Masterclasses**: Title, description, created_at
5. **Videos**: Title, duration (in seconds), masterclass_id, video_url, created_at
6. **Video Likes**: user_id, video_id, created_at (unique constraint to prevent duplicates)
7. **Watch Progress**: user_id, video_id, watched_seconds, last_updated_at (idempotent updates)
8. **Invite Codes**: Code, generated_by_user_id, redeemed_by_user_id (null if not yet redeemed), child_id, created_at, redeemed_at
9. **Partner Relationships**: user_id_1, user_id_2, child_id, linked_at (mutual, symmetric)

### Data Integrity Requirements
- Watch progress must be idempotent: furthest-watched position always wins (never go backwards)
- Likes must be idempotent: liking twice does not create duplicates
- Invite codes must be unique and single-use
- Partner relationships must be symmetric (if A links to B on child C, then B is linked to A on child C)
- Users must only see data for their linked partner on the shared child

---

## API / Backend Requirements

### Core Endpoints (Indicative — Design is Flexible)

**Authentication**
- `POST /auth/signup` — Create account (email, password, role, child_name, child_dob)
- `POST /auth/login` — Login (email, password) → return session token

**Content**
- `GET /masterclasses` — List all masterclasses (authenticated)
- `GET /masterclasses/{id}` — Get masterclass details + videos
- `GET /videos/{id}` — Get video details

**User Actions**
- `POST /videos/{id}/like` — Like a video
- `DELETE /videos/{id}/like` — Unlike a video
- `POST /videos/{id}/progress` — Update watch progress (report current position in seconds)
- `GET /videos/{id}/progress` — Get user's own watch progress

**Partner Linking**
- `POST /invite-codes` — Generate invite code (returns code)
- `POST /invite-codes/{code}/redeem` — Redeem invite code (must be authenticated as different user)
- `GET /partner` — Get linked partner details (if linked)
- `GET /partner/status` — Get partner linking status

**Shared Activity**
- `GET /videos/{id}/partner-activity` — Get partner's like state and watch progress for video (if linked)
- `GET /masterclasses/{id}/partner-progress` — Get partner's progress on masterclass (if linked)

**Business Logic Notes**
- All endpoints except signup/login require authentication
- All shared activity endpoints must verify the user is linked with their partner before returning data
- Watch progress updates should be idempotent (furthest-watched wins)
- Like state must be idempotent (toggling prevents duplicates)

---

## Authentication / Authorization Requirements

### Authentication
- Email + password sign-up and login
- Session-based authentication (or token-based; implementation is flexible)
- Secure password handling (hashing, no plaintext storage)

### Authorization
- **Core principle**: A user should **only ever see their linked partner's activity for the shared child**
- Never show any other user's data
- Never show partner data before the accounts are linked
- Linked partners have mutual, symmetric visibility
- After unlinking (if supported), visibility must immediately cease
- All endpoints serving user data or partner data must verify ownership/linking

### Edge Cases
- User cannot link to themselves (code generation + redemption validation)
- User cannot see any user's data (including their own partner) before the accounts are linked
- If a user is already linked to a partner, attempting to link again should fail gracefully (not silently re-link)
- A new user logging in should not have access to their partner's data until they generate/redeem an invite code

---

## Validation / Business Rules

### Invite Code Rules
- **Non-reusable**: A code can only be redeemed once
- **Single partner**: A code cannot be redeemed by more than one partner
- **No self-linking**: A user cannot redeem their own generated code
- **Concurrent redemption**: If two people attempt to redeem the same code simultaneously, only one should succeed; the other must receive a clear error
- **Already linked**: A user who is already linked to a partner should not be able to re-link (attempting to link to the same partner again should fail with a clear message)

### Watch Progress Rules
- **Never backwards**: Watch progress for a video should never decrease (furthest-watched position always wins)
- **Real durations**: Video durations must be real and meaningful for progress tracking
- **Progress bounds**: Watch progress in seconds should not exceed video duration (or handle gracefully if it does)

### Like Rules
- **Idempotent**: Liking a video twice should not create duplicate like records; the second like should be a no-op or an unlike
- **Per-user**: Each user's like state is independent

### Linking Rules
- **Mutual**: Once linked, both users can see each other's activity for the shared child
- **Shared child**: Linking is always for the child created at signup (one child per couple)
- **One couple**: The demo only supports one couple (two users) and one child

---

## Constraints & Technical Requirements

### Stack (Required)
- **Backend**: Go (required)
- **Frontend**: Flutter (required)
- **Database**: PostgreSQL (required, must be hosted, not localhost)

### Hosting (Required)
- **Entire app must be hosted and live** (not running on localhost)
- **Frontend hosting**: Options include Firebase, Vercel, Netlify, Flutter Web, etc.
- **Backend hosting**: Options include Render, Railway, Fly, Cloud Run, Heroku, etc.
- **Database hosting**: Options include Neon, Supabase, AWS RDS, etc.
- **Free tier hosting is acceptable**

### Code Quality
- Clean, correct backend with a sensible data model
- Solid integrity and authorization checks
- Thoughtful handling of edge cases (linking + shared-progress logic)
- Well-structured frontend with reusable, cleanly separated video-player component
- Clear component separation for surfacing partner activity

### Timeline
- Aim for completion in **3–4 days**
- Focus on correctness and completeness, not polish everywhere
- A well-reasoned, correct, complete slice is more important than polished edge features

### Tools & AI Usage
- **No restrictions**: Use any tools, libraries, AI (Claude, Copilot, etc.)
- The write-up must clearly document **which parts were AI-assisted vs. written by hand**, core logic decisions that were yours, and how you verified AI output

---

## Deliverables

1. **Hosted, working demo URL**
   - Frontend + backend + database, end-to-end functional
   - Accessible via a live link that the Sitaara team can click and use immediately
   - Free hosting is acceptable

2. **Two-account test flow**
   - Either: two pre-seeded test logins ready to use
   - Or: clear, documented steps for signing up and linking two accounts from scratch

3. **Source code**
   - Repository link (GitHub, GitLab, etc.) or zip file
   - Must include both Go backend and Flutter frontend

4. **README / Write-up**
   - How you built it and how you worked on it (process, project structure, order of approach)
   - How much you used AI and how much you didn't (which parts were AI-assisted, which were written by hand, core logic decisions, verification)
   - The reasoning behind key technical decisions:
     - Data model (schema / ERD recommended)
     - How you handled the edge cases (linking integrity, idempotent actions, authorization, consistency)
     - Trade-offs made
   - Explanation of the "masterclass %" and "currently watching" definitions

5. **Optional: Screen recording**
   - Not required (live demo will happen anyway)
   - If provided, keep it brief

---

## Acceptance Criteria

### Core Functionality (Must Have)
- [ ] User can sign up with email + password, select role (Mom/Dad), create child profile
- [ ] User can log in with email + password
- [ ] Two seeded masterclasses exist, each with 4–5 real-duration videos
- [ ] User can browse masterclasses and videos
- [ ] User can play a video and see watch progress
- [ ] Watch progress is reported to backend and persisted
- [ ] User can like / unlike a video
- [ ] Like state is persisted and retrieved
- [ ] User can generate an invite code
- [ ] User can redeem an invite code to link with their partner
- [ ] After linking, both users can see each other's activity:
  - Like state on videos (show "❤ Liked by Mom/Dad")
  - Watch progress on videos (not started / watching ~50% / completed)
  - Overall progress on masterclasses (e.g., "Dad has completed 3/5 videos (~60%)")
  - Current watching status on masterclasses
- [ ] Partner activity is only visible after linking
- [ ] Partner activity updates on refresh (consistency on refresh achieved)

### Edge Cases & Integrity (Must Have)
- [ ] User cannot link to themselves (validation prevents self-linking)
- [ ] Invite code cannot be redeemed twice (code is single-use)
- [ ] Invite code cannot be redeemed by more than one partner (only redeemer becomes linked)
- [ ] User who is already linked cannot silently re-link (error message or prevention)
- [ ] Concurrent redemption of the same code is handled (only one succeeds)
- [ ] Watch progress never goes backwards (furthest-watched wins)
- [ ] Liking twice is idempotent (no duplicate like records)
- [ ] User cannot see any other user's data (except linked partner on shared child)
- [ ] Authorization checks prevent unauthorized access to partner data

### Data & Persistence (Must Have)
- [ ] PostgreSQL database is used and hosted (not localhost)
- [ ] Data persists across sessions
- [ ] Content is seeded on initialization (2 masterclasses, 4–5 videos each)
- [ ] User data, child data, video progress, likes, and partner relationships are stored

### Deliverables (Must Have)
- [ ] Live, hosted demo is accessible and fully functional
- [ ] Source code is provided and readable
- [ ] README / write-up is complete and explains:
  - Process, structure, and order of work
  - AI usage vs. hand-written logic
  - Key technical decisions and data model
  - Edge case handling and reasoning
  - Definitions of "masterclass %" and "currently watching"

---

## Ambiguities or Requirements Needing Clarification

1. **Masterclass % Definition**: The exact calculation of "masterclass %" is a design decision. Possible approaches:
   - Average of all video completion percentages
   - Only count completed videos
   - Weighted average
   - Other sensible metric
   - **Note**: Must be explained in the write-up with reasoning

2. **Currently Watching Definition**: How to determine if a partner is "currently watching" a masterclass:
   - At least one video in the masterclass has been started but not completed?
   - At least one video is in progress (partially watched)?
   - Other definition
   - **Note**: Must be explained in the write-up with reasoning

3. **Live Updates vs. On Refresh**: The requirement states "on refresh is fine; live updates are a nice bonus." This clarifies that:
   - Minimum viable: Partner activity updates when the user navigates or refreshes
   - Nice to have: Real-time push updates (WebSocket, polling, etc.)

4. **Unlinking**: The assignment does not mention unlinking or what happens if users unlink. Clarification needed on:
   - Should unlinking be supported?
   - If yes, what happens to historical data?
   - (Current assumption: Not required for MVP, but should be considered if time allows)

5. **Session Longevity**: How long should user sessions last, and should there be a logout feature?
   - Current assumption: Basic logout supported, sessions are valid for the demo duration

6. **Multiple Children**: The requirement states "one shared child" for the demo. Clarification:
   - Should the backend support multiple children per couple (for future scaling)?
   - Current assumption: MVP is one child per couple; architecture should be extensible

7. **Video URL Source**: The assignment says "use any sample videos you like, as long as they have real durations." Clarification on what sources are acceptable:
   - YouTube links?
   - Self-hosted video files?
   - Third-party CDN (e.g., Vimeo)?
   - Current assumption: Any public, accessible video URLs with real durations are acceptable

8. **Password Requirements**: No specification on password complexity or validation:
   - Current assumption: Basic email + password is acceptable (no complexity requirements specified)

9. **Error Handling & User Feedback**: The assignment does not specify exact error messages. Clarification:
   - Should specific errors be returned (e.g., "Code already redeemed", "User already linked")?
   - Current assumption: Clear, user-friendly error messages should be provided

10. **Invite Code Format**: No specification on invite code format, length, or generation:
    - Current assumption: Any reasonable, human-readable format (e.g., alphanumeric, 6–8 characters) is acceptable

---

See [data-model.md](data-model.md) for the detailed PostgreSQL schema design.

---

## Summary

This assignment is a **complete, minimal slice** of the Sitaara parenting app focused on demonstrating partner linking and shared progress. The bar is set high on **correctness and integrity** (especially around edge cases), and moderate on **visual polish**. The write-up is as important as the code and should clearly communicate process, technical decisions, and edge case reasoning.
