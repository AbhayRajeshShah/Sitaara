package users

import (
	"time"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

type CreateUserRequest struct {
	Email      string  `json:"email"`
	Password   string  `json:"password"`
	Role       string  `json:"role"`
	InviteCode *string `json:"inviteCode,omitempty"`
	ChildName  *string `json:"childName,omitempty"`
	ChildDob   *string `json:"childDob,omitempty"`
}

type ChildResponse struct {
	ID          pgtype.UUID `json:"id"`
	Name        string      `json:"name"`
	DateOfBirth pgtype.Date `json:"dob"`
}

type CreateUserResponse struct {
	ID             pgtype.UUID     `json:"id"`
	Email          string          `json:"email"`
	Role           sqlc.ParentRole `json:"role"`
	ChildID        pgtype.UUID     `json:"childId"`
	Child          *ChildResponse  `json:"child,omitempty"`
	Token          string          `json:"token"`
	TokenExpiresAt time.Time       `json:"tokenExpiresAt"`
}
