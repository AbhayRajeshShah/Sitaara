# Decisions

Key decisions made over the course of the SITAARA Full-Stack Assignment, updated to reflect what was actually implemented (superseding a few earlier assumptions that changed once the code was written).

## Accounts

- The `child` is simply shared data, not an individual user profile
- Roles are a Postgres enum: `mom`, `dad`, `guardian`
- `UNIQUE(family_id, role)` — a family can have at most one of each role, which in practice caps a family at two linked parents
- Passwords are hashed with bcrypt; never stored or logged in plaintext
- No email verification, no password complexity rules — out of scope for a demo of this size

## Authentication & Sessions

- JWT (HS256), `sub` = user id, `role` as a custom claim, 30-day expiry — issued identically by both sign-up and sign-in, so tokens from either endpoint are interchangeable
- No refresh-token flow: once a token expires, the client just signs in again
- No account lockout / rate limiting on login attempts — acceptable gap for demo scope
- Sign-in and "wrong password" return the identical `invalid_credentials` error, so the API never reveals whether an email is registered
- Logging out clears the locally cached watch-progress values too (`WatchProgressStore.clearAll`), so a previous user's in-flight progress can never leak into the next session on the same device

## Video Progress Tracking

- **Superseded**: earlier notes floated a Khan-Academy-style checkpoint system to stop users from skipping to the end and "cheating" progress. That was never built. What shipped instead: the client reports its raw playback position in seconds, the server clamps it to the video's duration and keeps whichever value is furthest (`GREATEST(existing, new)` on upsert) — never allowed to go backwards.
- This is a deliberate trade-off, not an oversight: a client can still self-report an arbitrary position (e.g. seek to the end and report full duration). Given the assignment's scope (a demo, not a production LMS with anti-cheat requirements), trusting the client's reported position kept the video player simple and the progress model idempotent and easy to reason about. Documented here so it's an explicit choice in the write-up, not a silent gap.
- Progress is stored as one row per `(user_id, video_id)` (`UNIQUE` constraint), so reporting is naturally idempotent regardless of how many times the same position is flushed.

## Partner Linking

- Invite codes are 6 characters, drawn from an alphabet that excludes visually ambiguous characters (`0`/`O`, `1`/`I`/`L`) so they're easy to read and re-type
- Codes never expire; they're single-use and are auto-invalidated the moment the owning family generates a new one (only one active code per family at a time)
- A family that already has two linked parents cannot generate a new invite code (`family_has_two_parents`) — nothing further to invite
- Redemption is guarded against races with a `SELECT ... FOR UPDATE` row lock on the invite plus Postgres advisory locks on both families involved, acquired in a fixed (sorted) order so two concurrent redemptions touching the same two families can never deadlock
- No self-redemption, no re-redeeming an already-used code, no joining a family that already has your role or is already full — all enforced inside the same transaction
- **Switching families**: if a solo (unlinked) user redeems a code for a different family, their current family — including its child — is deleted first, then they're moved into the new family. This is only allowed while they're the *sole* member of their current family: a user who already has a partner linked cannot switch away, since that would destroy the partner's data without consent.
- Because switching destroys the joining user's current child data, the Flutter client shows a confirmation dialog before calling redeem ("current child information will be lost") — the user must explicitly confirm before the request is sent.
- There are two ways to end up linked: redeeming a code as a brand-new signup (`inviteCode` passed at `/users` creation) or redeeming later as an already-existing user (`POST /invite-codes/{code}/redeem`). Both funnel through the same family-membership rules.

## Progress Completion

- Two levels, same as originally scoped:
  - **Masterclass %** = `completed_videos / total_videos` — a strict video-count ratio, not an average of partial watch percentages. Each video is worth the same regardless of length.
  - **Video %** is a separate, continuous metric based on `watched_seconds / duration_seconds`.
- **Completed** (for the masterclass-level count) means `watched_seconds + 10s >= duration_seconds` — a 10-second trailing grace window so a viewer who stops just short of the literal end (credits, rounding in the reported position) still gets credit for finishing. This grace constant is a single named value (`completionGraceSeconds`) threaded through the one query that needs it.
- **Currently watching** = **superseded from the original 90-day-recency idea**, which was never implemented. What actually ships: a video counts as "in progress" simply if `0 < watched_seconds < duration_seconds` — no recency window at all. At the masterclass level, the Flutter client buckets a masterclass as "Currently watching" if the signed-in user has strictly-between-0-and-100% progress on it; there's no time-based staleness check, on the reasoning that with only 2 seeded masterclasses, an old "in progress" entry isn't confusing enough to justify the extra complexity of a rolling window. Worth revisiting if the content library grows.
- The same partial-progress rule (`0 < watched < duration`) is reused to show "Partner is watching" on a video's course-content row, and to power the dashboard's "Partner up" section — masterclasses the signed-in user hasn't started but their partner has (i.e. the user's own progress is 0/none while `partnerProgress.percentComplete > 0`), pulled out of "Available" so the two don't overlap.

## Data Model

- No separate "child ownership" or "partner relationship" join table. `family_id` is the one shared anchor: both `users` and `children` reference it directly, so "are these two users partners?" is just `u1.family_id == u2.family_id`, and "what does this family share?" is a single `WHERE family_id = ?`. Simpler than the join-table shape the assignment brief sketched, and sufficient since a family only ever has up to two parents and one child in this scope.
- No `ON DELETE CASCADE` anywhere — every foreign key is `RESTRICT`. Family-switching (above) explicitly deletes the old family's child and invite codes itself, in a controlled order inside one transaction, rather than relying on cascades to do it implicitly.

## Frontend Navigation

- Removed the "Classes" bottom-nav tab — it was a placeholder with no screen behind it
- Removed the top-bar hamburger icon everywhere — it never opened a drawer and, on most screens, only duplicated back-navigation the bottom nav already provides
- The top-bar avatar now always navigates to the Profile screen (previously the home screen's avatar opened a one-off sign-out menu instead)
- Sign-out moved to a dedicated "Log Out" button at the bottom of the Profile screen, with its own confirmation dialog, rather than living behind the avatar tap
- Lesson Player has no "active" bottom-nav tab (it isn't one of Home/Partner/Profile), but all three remain tappable from there, and pull-to-refresh re-fetches the masterclass detail without interrupting whatever video is currently playing
