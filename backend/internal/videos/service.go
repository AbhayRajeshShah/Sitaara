package videos

import (
	"context"
	"errors"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Service struct {
	queries *sqlc.Queries
}

func NewService(queries *sqlc.Queries) *Service {
	return &Service{queries: queries}
}

func (s *Service) GetFamilyActivity(ctx context.Context, requestingUserID, videoID pgtype.UUID) (FamilyActivityResponse, *apiError) {
	if _, err := s.queries.GetVideo(ctx, videoID); errors.Is(err, pgx.ErrNoRows) {
		return FamilyActivityResponse{}, notFound("video_not_found", "video not found")
	} else if err != nil {
		return FamilyActivityResponse{}, internalErr(err)
	}

	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return FamilyActivityResponse{}, internalErr(err)
	}

	rows, err := s.queries.GetVideoActivityForFamily(ctx, sqlc.GetVideoActivityForFamilyParams{
		FamilyID: user.FamilyID,
		VideoID:  videoID,
	})
	if err != nil {
		return FamilyActivityResponse{}, internalErr(err)
	}

	members := make([]FamilyMemberActivity, len(rows))
	for i, row := range rows {
		members[i] = FamilyMemberActivity{
			UserID:         row.UserID,
			Role:           row.Role,
			IsYou:          row.UserID == requestingUserID,
			Liked:          row.Liked,
			WatchedSeconds: row.WatchedSeconds,
			LastWatchedAt:  row.LastUpdatedAt,
		}
	}

	return FamilyActivityResponse{VideoID: videoID, Members: members}, nil
}
