package invites

import (
	"context"
	"errors"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxCodeGenerationAttempts = 5

type Service struct {
	pool    *pgxpool.Pool
	queries *sqlc.Queries
}

func NewService(pool *pgxpool.Pool, queries *sqlc.Queries) *Service {
	return &Service{pool: pool, queries: queries}
}

func (s *Service) Generate(ctx context.Context, requestingUserID pgtype.UUID) (InviteCodeResponse, *apiError) {
	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}

	members, err := s.queries.ListUsersByFamilyID(ctx, user.FamilyID)
	if err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}
	if len(members) >= 2 {
		return InviteCodeResponse{}, conflict("family_has_two_parents", "this family already has two linked parents")
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}
	defer tx.Rollback(ctx)
	q := s.queries.WithTx(tx)

	if err := q.DeleteActiveInvitesForFamily(ctx, user.FamilyID); err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}

	var invite sqlc.InviteCode
	for attempt := 0; attempt < maxCodeGenerationAttempts; attempt++ {
		code, err := generateCode()
		if err != nil {
			return InviteCodeResponse{}, internalErr(err)
		}
		invite, err = q.CreateInvite(ctx, sqlc.CreateInviteParams{
			Code:              code,
			GeneratedByUserID: requestingUserID,
			FamilyID:          user.FamilyID,
		})
		if err == nil {
			break
		}
		if !isUniqueViolation(err, "invite_codes_code_unique") {
			return InviteCodeResponse{}, internalErr(err)
		}
		invite = sqlc.InviteCode{}
	}
	if invite.Code == "" {
		return InviteCodeResponse{}, internalErr(errors.New("could not generate a unique invite code"))
	}

	if err := tx.Commit(ctx); err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}

	return InviteCodeResponse{Code: invite.Code, FamilyID: invite.FamilyID, CreatedAt: invite.CreatedAt}, nil
}

func (s *Service) GetActive(ctx context.Context, requestingUserID pgtype.UUID) (InviteCodeResponse, *apiError) {
	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}

	invite, err := s.queries.GetActiveInviteForFamily(ctx, user.FamilyID)
	if errors.Is(err, pgx.ErrNoRows) {
		return InviteCodeResponse{}, notFound("no_active_invite", "no active invite code for this family")
	} else if err != nil {
		return InviteCodeResponse{}, internalErr(err)
	}

	return InviteCodeResponse{Code: invite.Code, FamilyID: invite.FamilyID, CreatedAt: invite.CreatedAt}, nil
}
