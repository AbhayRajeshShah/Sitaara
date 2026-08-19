-- name: ListMasterclasses :many
SELECT * FROM masterclasses
ORDER BY created_at ASC;

-- name: GetMasterclass :one
SELECT * FROM masterclasses
WHERE id = $1;

-- name: ListVideosByMasterclass :many
SELECT * FROM videos
WHERE masterclass_id = $1
ORDER BY created_at ASC;

-- name: GetVideo :one
SELECT * FROM videos
WHERE id = $1;
