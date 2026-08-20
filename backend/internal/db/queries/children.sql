-- name: CreateChild :one
INSERT INTO children (family_id, name, date_of_birth)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetChild :one
SELECT * FROM children
WHERE id = $1;
