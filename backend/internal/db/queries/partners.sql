-- name: InsertPartner :one
INSERT INTO partner_relationships (user_id_1, user_id_2, child_id)
VALUES (LEAST($1::uuid, $2::uuid), GREATEST($1::uuid, $2::uuid), $3)
RETURNING *;

-- name: GetPartnerForUser :one
SELECT * FROM partner_relationships
WHERE user_id_1 = $1 OR user_id_2 = $1;
