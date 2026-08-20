package invites

import "github.com/jackc/pgx/v5/pgtype"

type InviteCodeResponse struct {
	Code      string             `json:"code"`
	FamilyID  pgtype.UUID        `json:"familyId"`
	CreatedAt pgtype.Timestamptz `json:"createdAt"`
}
