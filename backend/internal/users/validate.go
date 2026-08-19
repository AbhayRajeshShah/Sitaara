package users

import (
	"fmt"
	"net/mail"
	"strings"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
)

const (
	minPasswordLength = 8
	maxPasswordLength = 72 // bcrypt silently truncates beyond 72 bytes; reject instead
)

func parseRole(s string) (sqlc.ParentRole, *apiError) {
	switch sqlc.ParentRole(s) {
	case sqlc.ParentRoleMom, sqlc.ParentRoleDad, sqlc.ParentRoleGuardian:
		return sqlc.ParentRole(s), nil
	default:
		return "", badRequest("invalid_request", "role must be one of: mom, dad, guardian")
	}
}

func validateEmail(email string) *apiError {
	if strings.TrimSpace(email) == "" {
		return badRequest("invalid_request", "email is required")
	}
	if _, err := mail.ParseAddress(email); err != nil {
		return badRequest("invalid_request", "email is not a valid address")
	}
	return nil
}

func validatePassword(password string) *apiError {
	switch {
	case len(password) < minPasswordLength:
		return badRequest("invalid_request", fmt.Sprintf("password must be at least %d characters", minPasswordLength))
	case len(password) > maxPasswordLength:
		return badRequest("invalid_request", fmt.Sprintf("password must be at most %d characters", maxPasswordLength))
	}
	return nil
}
