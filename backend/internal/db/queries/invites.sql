-- name: CreateInvite :one
INSERT INTO invite_codes (code, generated_by_user_id, family_id)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetInviteByCode :one
SELECT * FROM invite_codes
WHERE code = $1;

-- name: GetInviteByCodeForUpdate :one
SELECT * FROM invite_codes
WHERE code = $1
FOR UPDATE;

-- name: RedeemInvite :one
UPDATE invite_codes
SET redeemed_by_user_id = $2,
    redeemed_at = now()
WHERE id = $1
  AND redeemed_by_user_id IS NULL
RETURNING *;

-- name: DeleteActiveInvitesForFamily :exec
DELETE FROM invite_codes
WHERE family_id = $1 AND redeemed_by_user_id IS NULL;

-- name: GetActiveInviteForFamily :one
SELECT * FROM invite_codes
WHERE family_id = $1 AND redeemed_by_user_id IS NULL
ORDER BY created_at DESC
LIMIT 1;
