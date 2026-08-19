CREATE TYPE parent_role AS ENUM ('mom', 'dad', 'guardian');

CREATE TABLE children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL CHECK (btrim(name) <> ''),
    date_of_birth DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role parent_role NOT NULL,
    child_id UUID NOT NULL REFERENCES children (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_email_unique UNIQUE (email)
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
    child_id UUID NOT NULL REFERENCES children (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    redeemed_at TIMESTAMPTZ,
    CONSTRAINT invite_codes_code_unique UNIQUE (code),
    CONSTRAINT invite_codes_no_self_redeem CHECK (
        redeemed_by_user_id IS NULL OR redeemed_by_user_id <> generated_by_user_id
    )
);

CREATE TABLE partner_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_1 UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    user_id_2 UUID NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    child_id UUID NOT NULL REFERENCES children (id) ON DELETE RESTRICT,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT partner_user_order CHECK (user_id_1 < user_id_2),
    CONSTRAINT partner_relationships_unique UNIQUE (user_id_1, user_id_2, child_id)
);

CREATE INDEX idx_users_child_id ON users (child_id);

CREATE INDEX idx_videos_masterclass_id ON videos (masterclass_id);

CREATE INDEX idx_video_likes_user_id ON video_likes (user_id);
CREATE INDEX idx_video_likes_video_id ON video_likes (video_id);

CREATE INDEX idx_watch_progress_user_id ON watch_progress (user_id);
CREATE INDEX idx_watch_progress_video_id ON watch_progress (video_id);

CREATE INDEX idx_invite_codes_generated_by ON invite_codes (generated_by_user_id);
CREATE INDEX idx_invite_codes_redeemed_by ON invite_codes (redeemed_by_user_id);

CREATE INDEX idx_partner_relationships_user_id_1 ON partner_relationships (user_id_1);
CREATE INDEX idx_partner_relationships_user_id_2 ON partner_relationships (user_id_2);
CREATE INDEX idx_partner_relationships_child_id ON partner_relationships (child_id);
