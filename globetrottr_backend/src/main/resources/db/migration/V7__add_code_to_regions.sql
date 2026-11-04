ALTER TABLE regions ADD COLUMN IF NOT EXISTS code VARCHAR(50);
CREATE INDEX IF NOT EXISTS idx_regions_code ON regions (code);
