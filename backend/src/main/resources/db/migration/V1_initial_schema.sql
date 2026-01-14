-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table (optional accounts for authenticated users)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    provider VARCHAR(50),
    provider_id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_provider_id UNIQUE (provider, provider_id)
);

-- Coffee shops table with PostGIS geometry for location
CREATE TABLE coffee_shops (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    location GEOMETRY(Point, 4326) NOT NULL, -- WGS84 coordinate system
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial index for location queries (enables fast geographic searches)
CREATE INDEX idx_coffee_shops_location ON coffee_shops USING GIST (location);

-- Submissions table (user-submitted data about coffee shops)
-- Uses JSONB for flexible schema (milk_types, syrup_types, etc.)
CREATE TABLE submissions (
    id BIGSERIAL PRIMARY KEY,
    coffee_shop_id BIGINT NOT NULL REFERENCES coffee_shops(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL, -- Nullable for anonymous submissions
    data JSONB NOT NULL DEFAULT '{}', -- Flexible data storage (price, milk_types, syrup_types, quality_rating, etc.)
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for JSONB queries (enables fast searches within JSON data)
CREATE INDEX idx_submissions_data ON submissions USING GIN (data);
CREATE INDEX idx_submissions_coffee_shop_id ON submissions (coffee_shop_id);
CREATE INDEX idx_submissions_user_id ON submissions (user_id);
CREATE INDEX idx_submissions_status ON submissions (status);

-- Votes table (upvote/downvote system)
CREATE TABLE votes (
    id BIGSERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL, -- Nullable for anonymous votes
    vote_type VARCHAR(10) NOT NULL CHECK (vote_type IN ('up', 'down')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Prevent duplicate votes from same user on same submission
    CONSTRAINT unique_user_submission_vote UNIQUE (submission_id, user_id)
);

CREATE INDEX idx_votes_submission_id ON votes (submission_id);
CREATE INDEX idx_votes_user_id ON votes (user_id);

-- Flags table (for reporting inappropriate content)
CREATE TABLE flags (
    id BIGSERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL, -- Nullable for anonymous flags
    reason TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, reviewed, dismissed, action_taken
    reviewed_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_flags_submission_id ON flags (submission_id);
CREATE INDEX idx_flags_user_id ON flags (user_id);
CREATE INDEX idx_flags_status ON flags (status);

-- Favorites table (for users to save favorite coffee shops)
CREATE TABLE favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coffee_shop_id BIGINT NOT NULL REFERENCES coffee_shops(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Prevent duplicate favorites
    CONSTRAINT unique_user_coffee_shop_favorite UNIQUE (user_id, coffee_shop_id)
);

CREATE INDEX idx_favorites_user_id ON favorites (user_id);
CREATE INDEX idx_favorites_coffee_shop_id ON favorites (coffee_shop_id);

