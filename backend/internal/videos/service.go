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

func (s *Service) ToggleLike(ctx context.Context, userID, videoID pgtype.UUID) (LikeResponse, *apiError) {
	if _, err := s.queries.GetVideo(ctx, videoID); errors.Is(err, pgx.ErrNoRows) {
		return LikeResponse{}, notFound("video_not_found", "video not found")
	} else if err != nil {
		return LikeResponse{}, internalErr(err)
	}

	_, err := s.queries.GetLike(ctx, sqlc.GetLikeParams{UserID: userID, VideoID: videoID})
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		if err := s.queries.LikeVideo(ctx, sqlc.LikeVideoParams{UserID: userID, VideoID: videoID}); err != nil {
			return LikeResponse{}, internalErr(err)
		}
		return LikeResponse{VideoID: videoID, Liked: true}, nil
	case err != nil:
		return LikeResponse{}, internalErr(err)
	default:
		if err := s.queries.UnlikeVideo(ctx, sqlc.UnlikeVideoParams{UserID: userID, VideoID: videoID}); err != nil {
			return LikeResponse{}, internalErr(err)
		}
		return LikeResponse{VideoID: videoID, Liked: false}, nil
	}
}

func (s *Service) UpdateProgress(ctx context.Context, userID, videoID pgtype.UUID, watchedSeconds int32) (ProgressResponse, *apiError) {
	if watchedSeconds < 0 {
		return ProgressResponse{}, badRequest("invalid_request", "watchedSeconds must be non-negative")
	}

	video, err := s.queries.GetVideo(ctx, videoID)
	if errors.Is(err, pgx.ErrNoRows) {
		return ProgressResponse{}, notFound("video_not_found", "video not found")
	} else if err != nil {
		return ProgressResponse{}, internalErr(err)
	}

	if watchedSeconds > video.DurationSeconds {
		watchedSeconds = video.DurationSeconds
	}

	progress, err := s.queries.UpsertWatchProgress(ctx, sqlc.UpsertWatchProgressParams{
		UserID:         userID,
		VideoID:        videoID,
		WatchedSeconds: watchedSeconds,
	})
	if err != nil {
		return ProgressResponse{}, internalErr(err)
	}

	return ProgressResponse{
		VideoID:        videoID,
		WatchedSeconds: progress.WatchedSeconds,
		LastUpdatedAt:  progress.LastUpdatedAt,
	}, nil
}

func (s *Service) GetProgress(ctx context.Context, userID, videoID pgtype.UUID) (ProgressResponse, *apiError) {
	if _, err := s.queries.GetVideo(ctx, videoID); errors.Is(err, pgx.ErrNoRows) {
		return ProgressResponse{}, notFound("video_not_found", "video not found")
	} else if err != nil {
		return ProgressResponse{}, internalErr(err)
	}

	progress, err := s.queries.GetWatchProgress(ctx, sqlc.GetWatchProgressParams{UserID: userID, VideoID: videoID})
	if errors.Is(err, pgx.ErrNoRows) {
		return ProgressResponse{VideoID: videoID, WatchedSeconds: 0}, nil
	} else if err != nil {
		return ProgressResponse{}, internalErr(err)
	}

	return ProgressResponse{
		VideoID:        videoID,
		WatchedSeconds: progress.WatchedSeconds,
		LastUpdatedAt:  progress.LastUpdatedAt,
	}, nil
}
