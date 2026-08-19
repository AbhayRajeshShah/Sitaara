package db

import (
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

const dateLayout = "2006-01-02"

// ParseDate parses a strict YYYY-MM-DD calendar date into a pgtype.Date.
// Rejects values that time.Parse would otherwise silently roll over
// (e.g. "2024-02-30").
func ParseDate(s string) (pgtype.Date, error) {
	t, err := time.ParseInLocation(dateLayout, s, time.UTC)
	if err != nil {
		return pgtype.Date{}, fmt.Errorf("invalid date %q: expected YYYY-MM-DD", s)
	}
	if t.Format(dateLayout) != s {
		return pgtype.Date{}, fmt.Errorf("invalid date %q: day out of range for month", s)
	}
	return pgtype.Date{Time: t, Valid: true}, nil
}

// ParseUUID parses a standard dashed UUID string into a pgtype.UUID.
func ParseUUID(s string) (pgtype.UUID, error) {
	var u pgtype.UUID
	if err := u.Scan(s); err != nil {
		return pgtype.UUID{}, fmt.Errorf("invalid uuid %q: %w", s, err)
	}
	return u, nil
}
