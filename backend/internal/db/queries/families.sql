-- name: CreateFamily :one
INSERT INTO families DEFAULT VALUES
RETURNING *;

-- name: DeleteFamily :exec
DELETE FROM families
WHERE id = $1;
