-- name: GetMasterclassProgressForFamily :many
SELECT
    mc.id AS masterclass_id,
    u.id AS user_id,
    u.role,
    COUNT(v.id)::int AS total_videos,
    COUNT(*) FILTER (WHERE wp.watched_seconds + sqlc.arg(completion_grace_seconds)::int >= v.duration_seconds)::int AS completed_videos
FROM masterclasses mc
CROSS JOIN users u
LEFT JOIN videos v ON v.masterclass_id = mc.id
LEFT JOIN watch_progress wp ON wp.user_id = u.id AND wp.video_id = v.id
WHERE u.family_id = sqlc.arg(family_id)
GROUP BY mc.id, u.id, u.role
ORDER BY mc.id;
