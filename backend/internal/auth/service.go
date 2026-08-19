package auth

import (
	"context"
	"errors"
	"strings"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	queries *sqlc.Queries
	issuer  *Issuer
}

func NewService(queries *sqlc.Queries, issuer *Issuer) *Service {
	return &Service{queries: queries, issuer: issuer}
}

func (s *Service) SignIn(ctx context.Context, req SignInRequest) (SignInResponse, *apiError) {
	if strings.TrimSpace(req.Email) == "" {
		return SignInResponse{}, badRequest("invalid_request", "email is required")
	}
	if req.Password == "" {
		return SignInResponse{}, badRequest("invalid_request", "password is required")
	}

	// Same generic error for "user not found" and "wrong password" so the
	// response never reveals whether an email is registered.
	invalidCredentials := unauthorized("invalid_credentials", "invalid email or password")

	user, err := s.queries.GetUserByEmail(ctx, req.Email)
	if errors.Is(err, pgx.ErrNoRows) {
		return SignInResponse{}, invalidCredentials
	} else if err != nil {
		return SignInResponse{}, internalErr(err)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return SignInResponse{}, invalidCredentials
	}

	token, expiresAt, err := s.issuer.IssueToken(user.ID.String(), string(user.Role))
	if err != nil {
		return SignInResponse{}, internalErr(err)
	}

	return SignInResponse{
		ID:             user.ID,
		Email:          user.Email,
		Role:           user.Role,
		Token:          token,
		TokenExpiresAt: expiresAt,
	}, nil
}
