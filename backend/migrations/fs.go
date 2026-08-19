package migrations

import "embed"

// FS contains versioned SQL migrations applied on startup.
//
//go:embed *.sql
var FS embed.FS
