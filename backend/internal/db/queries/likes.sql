-- name: LikeVideo :exec
INSERT INTO video_likes (user_id, video_id)
VALUES ($1, $2)
ON CONFLICT (user_id, video_id) DO NOTHING;

-- name: UnlikeVideo :exec
DELETE FROM video_likes
WHERE user_id = $1 AND video_id = $2;

-- name: GetLike :one
SELECT * FROM video_likes
WHERE user_id = $1 AND video_id = $2;
