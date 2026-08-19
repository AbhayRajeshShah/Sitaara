package users

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

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_request", "malformed JSON body")
		return
	}

	result, aerr := h.svc.Create(r.Context(), req)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}

	resp := CreateUserResponse{
		ID:             result.User.ID,
		Email:          result.User.Email,
		Role:           result.User.Role,
		ChildID:        result.User.ChildID,
		Token:          result.Token,
		TokenExpiresAt: result.TokenExpiresAt,
	}
	if result.Child != nil {
		resp.Child = &ChildResponse{
			ID:          result.Child.ID,
			Name:        result.Child.Name,
			DateOfBirth: result.Child.DateOfBirth,
		}
	}

	httpx.WriteJSON(w, http.StatusCreated, resp)
}
