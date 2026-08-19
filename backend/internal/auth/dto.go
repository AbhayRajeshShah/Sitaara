package auth

import (
	"time"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

type SignInRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type SignInResponse struct {
	ID             pgtype.UUID     `json:"id"`
	Email          string          `json:"email"`
	Role           sqlc.ParentRole `json:"role"`
	Token          string          `json:"token"`
	TokenExpiresAt time.Time       `json:"tokenExpiresAt"`
}
