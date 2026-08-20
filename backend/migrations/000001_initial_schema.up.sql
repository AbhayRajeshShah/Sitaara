CREATE TYPE parent_role AS ENUM ('mom', 'dad', 'guardian');

CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families (id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL CHECK (btrim(name) <> ''),
    date_of_birth DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role parent_role NOT NULL,
    family_id UUID NOT NULL REFERENCES families (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_family_role_unique UNIQUE (family_id, role)
);

CREATE TABLE masterclasses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL CHECK (btrim(title) <> ''),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL CHECK (btrim(title) <> ''),
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    masterclass_id UUID NOT NULL REFERENCES masterclasses (id) ON DELETE RESTRICT,
    video_url TEXT NOT NULL CHECK (btrim(video_url) <> ''),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE video_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    video_id UUID NOT NULL REFERENCES videos (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT video_likes_user_video_unique UNIQUE (user_id, video_id)
);

CREATE TABLE watch_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    video_id UUID NOT NULL REFERENCES videos (id) ON DELETE RESTRICT,
    watched_seconds INTEGER NOT NULL CHECK (watched_seconds >= 0),
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT watch_progress_user_video_unique UNIQUE (user_id, video_id)
);

CREATE TABLE invite_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(32) NOT NULL,
    generated_by_user_id UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    redeemed_by_user_id UUID REFERENCES users (id) ON DELETE RESTRICT,
    family_id UUID NOT NULL REFERENCES families (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    redeemed_at TIMESTAMPTZ,
    CONSTRAINT invite_codes_code_unique UNIQUE (code),
    CONSTRAINT invite_codes_no_self_redeem CHECK (
        redeemed_by_user_id IS NULL OR redeemed_by_user_id <> generated_by_user_id
    )
);

CREATE INDEX idx_children_family_id ON children (family_id);
CREATE INDEX idx_users_family_id ON users (family_id);

CREATE INDEX idx_videos_masterclass_id ON videos (masterclass_id);

CREATE INDEX idx_video_likes_user_id ON video_likes (user_id);
CREATE INDEX idx_video_likes_video_id ON video_likes (video_id);

CREATE INDEX idx_watch_progress_user_id ON watch_progress (user_id);
CREATE INDEX idx_watch_progress_video_id ON watch_progress (video_id);

CREATE INDEX idx_invite_codes_generated_by ON invite_codes (generated_by_user_id);
CREATE INDEX idx_invite_codes_redeemed_by ON invite_codes (redeemed_by_user_id);
CREATE INDEX idx_invite_codes_family_id ON invite_codes (family_id);
