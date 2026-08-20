package users

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/auth"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	pool    *pgxpool.Pool
	queries *sqlc.Queries
	issuer  *auth.Issuer
}

func NewService(pool *pgxpool.Pool, queries *sqlc.Queries, issuer *auth.Issuer) *Service {
	return &Service{pool: pool, queries: queries, issuer: issuer}
}

type createResult struct {
	User           sqlc.User
	Child          *sqlc.Child // nil for the invite-code case, populated when a new child is created
	Token          string
	TokenExpiresAt time.Time
}

func (s *Service) Create(ctx context.Context, req CreateUserRequest) (createResult, *apiError) {
	// --- Phase A: field-level validation, no DB tx ---
	role, aerr := parseRole(req.Role)
	if aerr != nil {
		return createResult{}, aerr
	}
	if aerr := validateEmail(req.Email); aerr != nil {
		return createResult{}, aerr
	}
	if aerr := validatePassword(req.Password); aerr != nil {
		return createResult{}, aerr
	}

	hasInvite := req.InviteCode != nil && strings.TrimSpace(*req.InviteCode) != ""

	var childName string
	var childDOB pgtype.Date
	if !hasInvite {
		if req.ChildName == nil || strings.TrimSpace(*req.ChildName) == "" {
			return createResult{}, badRequest("invalid_request", "childName is required when inviteCode is not provided")
		}
		if req.ChildDob == nil {
			return createResult{}, badRequest("invalid_request", "childDob is required when inviteCode is not provided")
		}
		d, err := db.ParseDate(*req.ChildDob)
		if err != nil {
			return createResult{}, badRequest("invalid_request", "childDob must be a valid YYYY-MM-DD date")
		}
		if d.Time.After(time.Now()) {
			return createResult{}, badRequest("invalid_request", "childDob cannot be in the future")
		}
		childName, childDOB = strings.TrimSpace(*req.ChildName), d
	}

	// Fast-path email pre-check; the DB unique constraint is the real race backstop.
	if _, err := s.queries.GetUserByEmail(ctx, req.Email); err == nil {
		return createResult{}, conflict("email_already_registered", "email is already registered")
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return createResult{}, internalErr(err)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return createResult{}, internalErr(err)
	}

	// --- Phase B: single DB transaction ---
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return createResult{}, internalErr(err)
	}
	defer tx.Rollback(ctx) // no-op after Commit

	q := s.queries.WithTx(tx)

	var familyID pgtype.UUID
	var invite sqlc.InviteCode
	var newChild *sqlc.Child

	if hasInvite {
		invite, err = q.GetInviteByCodeForUpdate(ctx, *req.InviteCode)
		if errors.Is(err, pgx.ErrNoRows) {
			return createResult{}, notFound("invite_not_found", "invite code not found")
		} else if err != nil {
			return createResult{}, internalErr(err)
		}
		if invite.RedeemedByUserID.Valid {
			return createResult{}, conflict("invite_already_used", "invite code has already been redeemed")
		}
		familyID = invite.FamilyID
	} else {
		f, err := q.CreateFamily(ctx)
		if err != nil {
			return createResult{}, internalErr(err)
		}
		familyID = f.ID

		c, err := q.CreateChild(ctx, sqlc.CreateChildParams{FamilyID: familyID, Name: childName, DateOfBirth: childDOB})
		if err != nil {
			return createResult{}, internalErr(err)
		}
		newChild = &c
	}

	// Serialize concurrent user-creation attempts for this family_id — closes
	// the race that unique(family_id, role) alone can't (it prevents duplicate
	// roles but not a total count above 2, since 3 roles exist).
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtext($1::text)::bigint)`, familyID); err != nil {
		return createResult{}, internalErr(err)
	}

	existing, err := q.ListUsersByFamilyID(ctx, familyID)
	if err != nil {
		return createResult{}, internalErr(err)
	}
	if len(existing) >= 2 {
		return createResult{}, conflict("family_has_two_parents", "this family already has two linked parents")
	}
	for _, u := range existing {
		if u.Role == role {
			return createResult{}, conflict("family_already_has_role", fmt.Sprintf("this family already has a %s", role))
		}
	}

	newUser, err := q.CreateUser(ctx, sqlc.CreateUserParams{
		Email:        req.Email,
		PasswordHash: string(hash),
		Role:         role,
		FamilyID:     familyID,
	})
	if err != nil {
		if isUniqueViolation(err, "users_email_unique") {
			return createResult{}, conflict("email_already_registered", "email is already registered")
		}
		if isUniqueViolation(err, "users_family_role_unique") {
			return createResult{}, conflict("family_already_has_role", fmt.Sprintf("this family already has a %s", role))
		}
		return createResult{}, internalErr(err)
	}

	if hasInvite {
		if _, err := q.RedeemInvite(ctx, sqlc.RedeemInviteParams{ID: invite.ID, RedeemedByUserID: newUser.ID}); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return createResult{}, conflict("invite_already_used", "invite code has already been redeemed")
			}
			return createResult{}, internalErr(err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return createResult{}, internalErr(err)
	}

	token, expiresAt, err := s.issuer.IssueToken(newUser.ID.String(), string(newUser.Role))
	if err != nil {
		return createResult{}, internalErr(err)
	}

	return createResult{User: newUser, Child: newChild, Token: token, TokenExpiresAt: expiresAt}, nil
}
