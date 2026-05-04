-- Add AI classification fields to reports table
ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS ai_category TEXT,
  ADD COLUMN IF NOT EXISTS ai_confidence DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS priority_score DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS credibility_score DOUBLE PRECISION DEFAULT 1;

-- Index for sorting by AI priority
CREATE INDEX IF NOT EXISTS idx_reports_priority
  ON reports(priority_score DESC);

-- Spatial index for hotspot queries (requires PostGIS)
CREATE INDEX IF NOT EXISTS idx_reports_location
  ON reports USING GIST (point(longitude, latitude));
