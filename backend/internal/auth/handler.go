package auth

import (
	"encoding/json"
	"net/http"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/httpx"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) SignIn(w http.ResponseWriter, r *http.Request) {
	var req SignInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_request", "malformed JSON body")
		return
	}

	resp, aerr := h.svc.SignIn(r.Context(), req)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, resp)
}
