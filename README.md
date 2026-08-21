# Sitaara — Parenting Masterclass

A minimal, end-to-end slice of the Sitaara parenting app: two parents link accounts as co-parents on one shared child, browse seeded video masterclasses, and see each other's watch progress and likes propagate in real time on refresh.

## Live Demo

|                            | URL                               |
| -------------------------- | --------------------------------- |
| **Frontend (Flutter Web)** | https://sitaara-ba350.web.app/    |
| **Backend API**            | https://sitaara.onrender.com      |
| **Database**               | Hosted PostgreSQL (not localhost) |

Two-account test flow: sign up twice (see [Try It](#try-it) below) — no pre-seeded logins are provided.

## Stack

- **Backend**: Go — [chi](https://github.com/go-chi/chi) router, [pgx](https://github.com/jackc/pgx) + [sqlc](https://sqlc.dev/) for typed queries, JWT auth
- **Frontend**: Flutter (mobile + web)
- **Database**: PostgreSQL, migrations run automatically on server start

## Repository Layout

```
app/       Flutter client
backend/   Go API — internal/ (domain packages), migrations/, docs/openapi.yaml
```

## Try It

1. Sign up as User A (role: Mom or Dad, plus child name + DOB).
2. From the Partner tab, generate an invite code.
3. Sign up as User B on a second device/session, entering that invite code (or sign in as B and redeem the code from the Partner tab).
4. Both accounts now share the same child. Like a video and update watch progress as one user, then switch to the other — their activity shows up on refresh.

## Features Implemented

- Email + password auth (JWT, 30-day session), role selection, shared child profile
- 2 seeded masterclasses, 5 real-duration videos each
- Video player with watch-progress reporting, like/unlike, resume-from-last-position
- Invite-code partner linking, symmetric once linked
- Shared activity once linked: partner's like state, per-video watch %, per-masterclass progress, and "currently watching" / "partner up" indicators
- Full edge-case handling: self-link prevention, single-use codes, concurrent-redemption safety, idempotent progress/likes, strict family-scoped authorization

## Key Design Decisions

Full reasoning lives in [`DECISIONS.md`](DECISIONS.md). Highlights:

- **Masterclass %** = `completed videos / total videos` (not an average of partial watch %) — each video counts equally
- **Currently watching** = any video with `0 < watched_seconds < duration`; no time-recency window (kept simple for a 2-masterclass demo)
- **Watch progress** is client-reported and idempotent (furthest position always wins) rather than checkpoint-gated — a deliberate simplicity trade-off, not an oversight
- **Partner = same `family_id`** — no separate relationship table; two users are linked simply by sharing a family row
- **Invite codes**: 6-char, unambiguous alphabet, no expiry, single active code per family, redemption is safe under concurrent requests (row lock + ordered advisory locks)

## Running Locally

**Backend**

```
cd backend
cp .env.example .env   # set DATABASE_URL, JWT_SECRET
go run ./cmd/server     # runs migrations + seed automatically
```

**Frontend**

```
cd app
flutter run --dart-define=API_HOST=http://localhost:8080
```

API reference: [`backend/docs/openapi.yaml`](backend/docs/openapi.yaml)

## AI Usage

This project was built with substantial AI assistance (Claude) across both the Go backend and Flutter frontend — schema design, service/handler logic, edge-case handling, and UI screens. Core architectural calls (data model shape, masterclass %/currently-watching definitions, invite-code and family-switching semantics) were reviewed and decided deliberately rather than accepted blindly; see [`DECISIONS.md`](DECISIONS.md) for the reasoning behind each. AI output was verified by reading the generated code, cross-checking it against the schema/migrations, and exercising the flows through the running app.
