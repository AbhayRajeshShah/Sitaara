-- name: GetVideoActivityForFamily :many
SELECT
    u.id AS user_id,
    u.role,
    (vl.id IS NOT NULL)::bool AS liked,
    COALESCE(wp.watched_seconds, 0)::int AS watched_seconds,
    wp.last_updated_at
FROM users u
LEFT JOIN video_likes vl ON vl.user_id = u.id AND vl.video_id = $2
LEFT JOIN watch_progress wp ON wp.user_id = u.id AND wp.video_id = $2
WHERE u.family_id = $1
ORDER BY u.created_at ASC;
