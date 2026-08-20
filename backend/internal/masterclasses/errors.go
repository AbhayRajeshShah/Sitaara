package masterclasses

import (
	"log"
	"net/http"
)

type apiError struct {
	status  int
	code    string
	message string
}

func notFound(code, msg string) *apiError { return &apiError{http.StatusNotFound, code, msg} }

func internalErr(err error) *apiError {
	log.Printf("masterclasses: internal error: %v", err)
	return &apiError{http.StatusInternalServerError, "internal_error", "something went wrong"}
}
