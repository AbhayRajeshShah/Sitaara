package db

import (
	"fmt"
	"io/fs"
	"net/url"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
)

func RunMigrations(databaseURL string, files fs.FS) error {
	source, err := iofs.New(files, ".")
	if err != nil {
		return fmt.Errorf("migration source: %w", err)
	}

	pgxURL, err := pgx5DatabaseURL(databaseURL)
	if err != nil {
		return err
	}

	m, err := migrate.NewWithSourceInstance("iofs", source, pgxURL)
	if err != nil {
		return fmt.Errorf("create migrator: %w", err)
	}
	defer m.Close()

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("apply migrations: %w", err)
	}
	return nil
}

func pgx5DatabaseURL(databaseURL string) (string, error) {
	u, err := url.Parse(databaseURL)
	if err != nil {
		return "", fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	u.Scheme = "pgx5"
	return u.String(), nil
}
