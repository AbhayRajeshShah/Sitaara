package invites

import (
	"net/http"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/auth"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/httpx"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) Generate(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	resp, aerr := h.svc.Generate(r.Context(), userID)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, resp)
}

func (h *Handler) Status(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	resp, aerr := h.svc.Status(r.Context(), userID)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) Redeem(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	code := chi.URLParam(r, "code")
	resp, aerr := h.svc.Redeem(r.Context(), userID, code)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) GetActive(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing authentication")
		return
	}
	resp, aerr := h.svc.GetActive(r.Context(), userID)
	if aerr != nil {
		httpx.WriteError(w, aerr.status, aerr.code, aerr.message)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}
