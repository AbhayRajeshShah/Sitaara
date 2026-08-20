package invites

import (
	"errors"
	"log"
	"net/http"

	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5/pgconn"
)

type apiError struct {
	status  int
	code    string
	message string
}

func notFound(code, msg string) *apiError { return &apiError{http.StatusNotFound, code, msg} }
func conflict(code, msg string) *apiError { return &apiError{http.StatusConflict, code, msg} }

func internalErr(err error) *apiError {
	log.Printf("invites: internal error: %v", err)
	return &apiError{http.StatusInternalServerError, "internal_error", "something went wrong"}
}

func isUniqueViolation(err error, constraint string) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == pgerrcode.UniqueViolation && pgErr.ConstraintName == constraint
	}
	return false
}
