package masterclasses

import (
	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

type MasterclassProgress struct {
	UserID          pgtype.UUID     `json:"userId"`
	Role            sqlc.ParentRole `json:"role"`
	IsYou           bool            `json:"isYou"`
	CompletedVideos int32           `json:"completedVideos"`
	TotalVideos     int32           `json:"totalVideos"`
	PercentComplete int             `json:"percentComplete"`
}

type MasterclassSummary struct {
	ID          pgtype.UUID            `json:"id"`
	Title       string                 `json:"title"`
	Description *string                `json:"description"`
	TotalVideos int32                  `json:"totalVideos"`
	Progress    []MasterclassProgress  `json:"progress"`
}

type VideoMemberActivity struct {
	UserID         pgtype.UUID        `json:"userId"`
	Role           sqlc.ParentRole    `json:"role"`
	IsYou          bool               `json:"isYou"`
	Liked          bool               `json:"liked"`
	WatchedSeconds int32              `json:"watchedSeconds"`
	LastWatchedAt  pgtype.Timestamptz `json:"lastWatchedAt"`
}

type VideoWithActivity struct {
	ID              pgtype.UUID           `json:"id"`
	Title           string                `json:"title"`
	DurationSeconds int32                 `json:"durationSeconds"`
	VideoURL        string                `json:"videoUrl"`
	Members         []VideoMemberActivity `json:"members"`
}

type MasterclassDetailResponse struct {
	ID          pgtype.UUID          `json:"id"`
	Title       string               `json:"title"`
	Description *string              `json:"description"`
	Videos      []VideoWithActivity  `json:"videos"`
}
