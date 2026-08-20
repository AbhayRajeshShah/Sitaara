package masterclasses

import (
	"context"
	"errors"

	"github.com/AbhayRajeshShah/Sitaara/backend/internal/db/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// completionGraceSeconds is how much trailing slack a video gets before it
// counts as "completed" toward a masterclass's completed-video count — a
// viewer who stops just short of the literal end (credits, rounding in
// reported position) still gets credit. Single source of truth; threaded
// into GetMasterclassProgressForFamily as a bound parameter.
const completionGraceSeconds int32 = 10

type Service struct {
	queries *sqlc.Queries
}

func NewService(queries *sqlc.Queries) *Service {
	return &Service{queries: queries}
}

func (s *Service) List(ctx context.Context, requestingUserID pgtype.UUID) ([]MasterclassSummary, *apiError) {
	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return nil, internalErr(err)
	}

	all, err := s.queries.ListMasterclasses(ctx)
	if err != nil {
		return nil, internalErr(err)
	}

	progressRows, err := s.queries.GetMasterclassProgressForFamily(ctx, sqlc.GetMasterclassProgressForFamilyParams{
		FamilyID:               user.FamilyID,
		CompletionGraceSeconds: completionGraceSeconds,
	})
	if err != nil {
		return nil, internalErr(err)
	}
	byMasterclass := make(map[pgtype.UUID][]sqlc.GetMasterclassProgressForFamilyRow, len(all))
	for _, row := range progressRows {
		byMasterclass[row.MasterclassID] = append(byMasterclass[row.MasterclassID], row)
	}

	out := make([]MasterclassSummary, len(all))
	for i, mc := range all {
		rows := byMasterclass[mc.ID]
		members := make([]MasterclassProgress, len(rows))
		var totalVideos int32
		for j, row := range rows {
			totalVideos = row.TotalVideos
			percent := 0
			if row.TotalVideos > 0 {
				percent = int(row.CompletedVideos) * 100 / int(row.TotalVideos)
			}
			members[j] = MasterclassProgress{
				UserID:          row.UserID,
				Role:            row.Role,
				IsYou:           row.UserID == requestingUserID,
				CompletedVideos: row.CompletedVideos,
				TotalVideos:     row.TotalVideos,
				PercentComplete: percent,
			}
		}
		out[i] = MasterclassSummary{
			ID:          mc.ID,
			Title:       mc.Title,
			Description: mc.Description,
			TotalVideos: totalVideos,
			Progress:    members,
		}
	}
	return out, nil
}

func (s *Service) GetDetail(ctx context.Context, requestingUserID, masterclassID pgtype.UUID) (MasterclassDetailResponse, *apiError) {
	mc, err := s.queries.GetMasterclass(ctx, masterclassID)
	if errors.Is(err, pgx.ErrNoRows) {
		return MasterclassDetailResponse{}, notFound("masterclass_not_found", "masterclass not found")
	} else if err != nil {
		return MasterclassDetailResponse{}, internalErr(err)
	}

	user, err := s.queries.GetUserByID(ctx, requestingUserID)
	if err != nil {
		return MasterclassDetailResponse{}, internalErr(err)
	}

	vids, err := s.queries.ListVideosByMasterclass(ctx, masterclassID)
	if err != nil {
		return MasterclassDetailResponse{}, internalErr(err)
	}

	videos := make([]VideoWithActivity, len(vids))
	for i, v := range vids {
		rows, err := s.queries.GetVideoActivityForFamily(ctx, sqlc.GetVideoActivityForFamilyParams{
			FamilyID: user.FamilyID,
			VideoID:  v.ID,
		})
		if err != nil {
			return MasterclassDetailResponse{}, internalErr(err)
		}
		members := make([]VideoMemberActivity, len(rows))
		for j, row := range rows {
			members[j] = VideoMemberActivity{
				UserID:         row.UserID,
				Role:           row.Role,
				IsYou:          row.UserID == requestingUserID,
				Liked:          row.Liked,
				WatchedSeconds: row.WatchedSeconds,
				LastWatchedAt:  row.LastUpdatedAt,
			}
		}
		videos[i] = VideoWithActivity{
			ID:              v.ID,
			Title:           v.Title,
			DurationSeconds: v.DurationSeconds,
			VideoURL:        v.VideoUrl,
			Members:         members,
		}
	}

	return MasterclassDetailResponse{
		ID:          mc.ID,
		Title:       mc.Title,
		Description: mc.Description,
		Videos:      videos,
	}, nil
}
