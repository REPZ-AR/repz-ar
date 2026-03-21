-- Create the workout_progress table
CREATE TABLE workout_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profile(user_id) ON DELETE CASCADE,
    current_workout_index INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    -- Add a unique constraint on user_id so we can easily perform UPSERTs
    UNIQUE(user_id)
);

-- Enable Row Level Security (RLS)
ALTER TABLE workout_progress ENABLE ROW LEVEL SECURITY;

-- Create policies so users can only read and modify their own progress
CREATE POLICY "Users can view their own progress"
ON workout_progress FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
ON workout_progress FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
ON workout_progress FOR UPDATE
USING (auth.uid() = user_id);