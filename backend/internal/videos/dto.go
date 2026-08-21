package videos

import (
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

type FamilyMemberActivity struct {
	UserID         pgtype.UUID        `json:"userId"`
	Role           sqlc.ParentRole    `json:"role"`
	IsYou          bool               `json:"isYou"`
	Liked          bool               `json:"liked"`
	WatchedSeconds int32              `json:"watchedSeconds"`
	LastWatchedAt  pgtype.Timestamptz `json:"lastWatchedAt"`
}

type FamilyActivityResponse struct {
	VideoID pgtype.UUID             `json:"videoId"`
	Members []FamilyMemberActivity  `json:"members"`
}

type LikeResponse struct {
	VideoID pgtype.UUID `json:"videoId"`
	Liked   bool        `json:"liked"`
}

type UpdateProgressRequest struct {
	WatchedSeconds int32 `json:"watchedSeconds"`
}

type ProgressResponse struct {
	VideoID        pgtype.UUID        `json:"videoId"`
	WatchedSeconds int32              `json:"watchedSeconds"`
	LastUpdatedAt  pgtype.Timestamptz `json:"lastUpdatedAt"`
}
