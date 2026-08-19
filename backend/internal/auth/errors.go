package auth

import (
	"log"
	"net/http"
)

type apiError struct {
	status  int
	code    string
	message string
}

func badRequest(code, msg string) *apiError   { return &apiError{http.StatusBadRequest, code, msg} }
func unauthorized(code, msg string) *apiError { return &apiError{http.StatusUnauthorized, code, msg} }

func internalErr(err error) *apiError {
	log.Printf("auth: internal error: %v", err)
	return &apiError{http.StatusInternalServerError, "internal_error", "something went wrong"}
}
