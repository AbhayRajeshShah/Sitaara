ALTER TABLE users ADD CONSTRAINT users_child_role_unique UNIQUE (child_id, role);
