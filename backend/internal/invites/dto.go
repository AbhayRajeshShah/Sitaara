package invites

import "github.com/jackc/pgx/v5/pgtype"

type InviteCodeResponse struct {
	Code      string             `json:"code"`
	FamilyID  pgtype.UUID        `json:"familyId"`
	CreatedAt pgtype.Timestamptz `json:"createdAt"`
}

type StatusResponse struct {
	IsConnected bool `json:"isConnected"`
}

type SwitchChildResponse struct {
	ID          pgtype.UUID `json:"id"`
	Name        string      `json:"name"`
	DateOfBirth pgtype.Date `json:"dob"`
}

type RedeemResponse struct {
	FamilyID pgtype.UUID          `json:"familyId"`
	Child    *SwitchChildResponse `json:"child,omitempty"`
}
