package invites

import (
	"context"
	"errors"
	"fmt"

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

func (s *Service) Status(ctx context.Context, requestingUserID pgtype.UUID) (StatusResponse, *apiError) {
	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return StatusResponse{}, internalErr(err)
	}

	members, err := s.queries.ListUsersByFamilyID(ctx, user.FamilyID)
	if err != nil {
		return StatusResponse{}, internalErr(err)
	}

	return StatusResponse{IsConnected: len(members) >= 2}, nil
}

// Redeem lets an already-linked user switch to the family behind a
// different invite code. The user's current family — including its child —
// is cascade-deleted first, since the schema has no ON DELETE CASCADE
// anywhere and every FK is RESTRICT. This is only allowed while the user is
// the sole member of their current family: if a partner is already linked
// there, switching away would destroy the partner's data without their
// consent, so it's rejected before anything is deleted.
func (s *Service) Redeem(ctx context.Context, requestingUserID pgtype.UUID, code string) (RedeemResponse, *apiError) {
	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	oldFamilyID := user.FamilyID

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	defer tx.Rollback(ctx)
	q := s.queries.WithTx(tx)

	invite, err := q.GetInviteByCodeForUpdate(ctx, code)
	if errors.Is(err, pgx.ErrNoRows) {
		return RedeemResponse{}, notFound("invite_not_found", "invite code not found")
	} else if err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if invite.RedeemedByUserID.Valid {
		return RedeemResponse{}, conflict("invite_already_used", "invite code has already been redeemed")
	}
	if invite.GeneratedByUserID == requestingUserID {
		return RedeemResponse{}, conflict("self_redeem_not_allowed", "you cannot redeem your own invite code")
	}
	newFamilyID := invite.FamilyID
	if newFamilyID == oldFamilyID {
		return RedeemResponse{}, conflict("already_in_family", "you already belong to this family")
	}

	for _, familyID := range sortedFamilyIDs(oldFamilyID, newFamilyID) {
		if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtext($1::text)::bigint)`, familyID); err != nil {
			return RedeemResponse{}, internalErr(err)
		}
	}

	oldMembers, err := q.ListUsersByFamilyID(ctx, oldFamilyID)
	if err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if len(oldMembers) > 1 {
		return RedeemResponse{}, conflict(
			"family_has_partner",
			"you're linked to a partner — switching families isn't supported while linked",
		)
	}

	newMembers, err := q.ListUsersByFamilyID(ctx, newFamilyID)
	if err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if len(newMembers) >= 2 {
		return RedeemResponse{}, conflict("family_has_two_parents", "this family already has two linked parents")
	}
	for _, m := range newMembers {
		if m.Role == user.Role {
			return RedeemResponse{}, conflict("family_already_has_role", fmt.Sprintf("this family already has a %s", user.Role))
		}
	}

	if err := q.DeleteInviteCodesByFamilyID(ctx, oldFamilyID); err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if err := q.DeleteChildrenByFamilyID(ctx, oldFamilyID); err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if _, err := q.UpdateUserFamily(ctx, sqlc.UpdateUserFamilyParams{ID: requestingUserID, FamilyID: newFamilyID}); err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if err := q.DeleteFamily(ctx, oldFamilyID); err != nil {
		return RedeemResponse{}, internalErr(err)
	}
	if _, err := q.RedeemInvite(ctx, sqlc.RedeemInviteParams{ID: invite.ID, RedeemedByUserID: requestingUserID}); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return RedeemResponse{}, conflict("invite_already_used", "invite code has already been redeemed")
		}
		return RedeemResponse{}, internalErr(err)
	}

	if err := tx.Commit(ctx); err != nil {
		return RedeemResponse{}, internalErr(err)
	}

	resp := RedeemResponse{FamilyID: newFamilyID}
	if child, err := s.queries.GetChildByFamilyID(ctx, newFamilyID); err == nil {
		resp.Child = &SwitchChildResponse{ID: child.ID, Name: child.Name, DateOfBirth: child.DateOfBirth}
	}
	return resp, nil
}

// sortedFamilyIDs returns both ids in a consistent order (by string form)
// so concurrent Redeem calls touching the same two families always acquire
// their advisory locks in the same sequence, avoiding a deadlock.
func sortedFamilyIDs(a, b pgtype.UUID) []pgtype.UUID {
	as, bs := a.String(), b.String()
	if as <= bs {
		return []pgtype.UUID{a, b}
	}
	return []pgtype.UUID{b, a}
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
