package masterclasses

import (
	"net/http"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/auth"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/httpx"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	resp, aerr := h.svc.List(r.Context(), userID)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) GetDetail(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	masterclassID, err := db.ParseUUID(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_request", "invalid masterclass id")
		return
	}
	resp, aerr := h.svc.GetDetail(r.Context(), userID, masterclassID)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}
