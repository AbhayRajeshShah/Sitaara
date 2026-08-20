package auth

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/httpx"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type contextKey struct{ name string }

var userIDKey = &contextKey{"userID"}

// RequireAuth validates the Bearer token minted by Issuer.IssueToken and
// stores the authenticated user's id in the request context.
func (i *Issuer) RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tokenStr, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || tokenStr == "" {
			httpx.WriteError(w, http.StatusUnauthorized, "unauthorized", "missing or malformed authorization header")
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
			}
			return i.secret, nil
		})
		if err != nil || !token.Valid {
			httpx.WriteError(w, http.StatusUnauthorized, "invalid_token", "invalid or expired token")
			return
		}

		userID, err := db.ParseUUID(claims.Subject)
		if err != nil {
			httpx.WriteError(w, http.StatusUnauthorized, "invalid_token", "invalid token subject")
			return
		}

		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), userIDKey, userID)))
	})
}

// UserIDFromContext returns the authenticated user id stored by RequireAuth.
func UserIDFromContext(ctx context.Context) (pgtype.UUID, bool) {
	v, ok := ctx.Value(userIDKey).(pgtype.UUID)
	return v, ok
}
