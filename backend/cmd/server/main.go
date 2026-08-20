package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/auth"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/config"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/httpx"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/invites"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/masterclasses"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/users"
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/videos"
	"github.com/AbhayRajeshShah/Sitaara/backend/migrations"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	ctx := context.Background()
	pool, err := db.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	if err := db.RunMigrations(cfg.DatabaseURL, migrations.FS); err != nil {
		log.Fatal(err)
	}

	queries := sqlc.New(pool)
	issuer := auth.NewIssuer(cfg.JWTSecret)
	usersHandler := users.NewHandler(users.NewService(pool, queries, issuer))
	authHandler := auth.NewHandler(auth.NewService(queries, issuer))
	videosHandler := videos.NewHandler(videos.NewService(queries))
	invitesHandler := invites.NewHandler(invites.NewService(pool, queries))
	masterclassesHandler := masterclasses.NewHandler(masterclasses.NewService(queries))

	r := chi.NewRouter()
	r.Get("/hello", helloHandler)
	r.Get("/health", healthHandler(pool))
	r.Post("/users", usersHandler.Create)
	r.Post("/auth/signin", authHandler.SignIn)

	r.Group(func(r chi.Router) {
		r.Use(issuer.RequireAuth)
		r.Get("/videos/{id}/partner-activity", videosHandler.GetFamilyActivity)
		r.Get("/me", usersHandler.Me)
		r.Post("/invite-codes", invitesHandler.Generate)
		r.Get("/invite-codes/active", invitesHandler.GetActive)
		r.Get("/masterclasses", masterclassesHandler.List)
		r.Get("/masterclasses/{id}", masterclassesHandler.GetDetail)
	})

	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,
	}

	go func() {
		log.Printf("listening on %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatal(err)
	}
}

func helloHandler(w http.ResponseWriter, _ *http.Request) {
	httpx.WriteJSON(w, http.StatusOK, map[string]string{"message": "hello"})
}

func healthHandler(pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := pool.Ping(r.Context()); err != nil {
			httpx.WriteJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "unhealthy"})
			return
		}
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	}
}
