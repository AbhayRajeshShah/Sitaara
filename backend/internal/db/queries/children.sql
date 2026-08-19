-- name: CreateChild :one
INSERT INTO children (name, date_of_birth)
VALUES ($1, $2)
RETURNING *;

-- name: GetChild :one
SELECT * FROM children
WHERE id = $1;
