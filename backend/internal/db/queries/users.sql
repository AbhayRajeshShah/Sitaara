-- name: CreateUser :one
INSERT INTO users (email, password_hash, role, family_id)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1;

-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1;

-- name: ListUsersByFamilyID :many
SELECT * FROM users
WHERE family_id = $1;
