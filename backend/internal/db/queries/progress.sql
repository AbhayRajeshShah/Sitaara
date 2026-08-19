-- name: UpsertWatchProgress :one
INSERT INTO watch_progress (user_id, video_id, watched_seconds, last_updated_at)
VALUES ($1, $2, $3, now())
ON CONFLICT (user_id, video_id)
DO UPDATE SET
    watched_seconds = GREATEST(watch_progress.watched_seconds, EXCLUDED.watched_seconds),
    last_updated_at = CASE
        WHEN EXCLUDED.watched_seconds > watch_progress.watched_seconds THEN now()
        ELSE watch_progress.last_updated_at
    END
RETURNING *;

-- name: GetWatchProgress :one
SELECT * FROM watch_progress
WHERE user_id = $1 AND video_id = $2;
