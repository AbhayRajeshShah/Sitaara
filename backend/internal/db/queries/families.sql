-- name: CreateFamily :one
INSERT INTO families DEFAULT VALUES
RETURNING *;
