-- BlindBook Band Reporting System - Database Schema
-- Supabase PostgreSQL
-- Run these commands in the Supabase SQL Editor

-- ============================================================
-- TABLE 1: User Contact Information
-- ============================================================
-- Purpose: Store user's contact info (entered once, reused for all band reports)
-- Constraints: One record per user (unique on user_id)

CREATE TABLE IF NOT EXISTS user_contact_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Contact information fields
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  street_address VARCHAR(255),
  street_address_2 VARCHAR(255),
  city VARCHAR(100),
  state_province VARCHAR(100),
  zip_postal_code VARCHAR(20),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Create index for fast user lookups
CREATE INDEX IF NOT EXISTS idx_user_contact_info_user_id 
  ON user_contact_info(user_id);

-- Add updated_at trigger (optional but good practice)
CREATE OR REPLACE FUNCTION update_user_contact_info_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_contact_info_updated_at_trigger
  BEFORE UPDATE ON user_contact_info
  FOR EACH ROW
  EXECUTE FUNCTION update_user_contact_info_updated_at();

-- ============================================================
-- TABLE 2: Band Records & Certificates
-- ============================================================
-- Purpose: Store each band report (multiple per user)
-- Constraints: Multiple records allowed per user

CREATE TABLE IF NOT EXISTS band_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Band information (from hunt log)
  band_number VARCHAR(20) NOT NULL,
  harvest_date DATE,
  harvest_location VARCHAR(255),
  harvest_note TEXT,
  
  -- Certificate information (extracted from USGS certificate)
  species VARCHAR(100),
  age_at_banding VARCHAR(50),
  sex VARCHAR(50),
  banding_date DATE,
  banding_location VARCHAR(255),
  banding_state VARCHAR(100),
  research_project VARCHAR(255),
  
  -- File references
  certificate_pdf_url VARCHAR(500),
  raw_certificate_text TEXT,
  
  -- Status tracking
  reporting_status VARCHAR(50) DEFAULT 'pending',  -- pending, submitted, awaiting_certificate, complete
  submission_date TIMESTAMP,
  certificate_received_date TIMESTAMP,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_band_certificates_user_id 
  ON band_certificates(user_id);

CREATE INDEX IF NOT EXISTS idx_band_certificates_band_number 
  ON band_certificates(band_number);

CREATE INDEX IF NOT EXISTS idx_band_certificates_status 
  ON band_certificates(reporting_status);

CREATE INDEX IF NOT EXISTS idx_band_certificates_created_at 
  ON band_certificates(created_at DESC);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_band_certificates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_band_certificates_updated_at_trigger
  BEFORE UPDATE ON band_certificates
  FOR EACH ROW
  EXECUTE FUNCTION update_band_certificates_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
-- Purpose: Ensure users can only access their own data
-- Security: Critical for multi-user system

-- Enable RLS on both tables
ALTER TABLE user_contact_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE band_certificates ENABLE ROW LEVEL SECURITY;

-- RLS Policy: User Contact Info - Users can only see/edit their own
CREATE POLICY user_contact_info_user_isolation 
  ON user_contact_info 
  FOR ALL 
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Band Certificates - Users can only see/edit their own
CREATE POLICY band_certificates_user_isolation 
  ON band_certificates 
  FOR ALL 
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- VIEWS (Optional but useful)
-- ============================================================

-- View: Band Summary by Status
CREATE OR REPLACE VIEW band_summary AS
  SELECT 
    user_id,
    COUNT(*) as total_bands,
    SUM(CASE WHEN reporting_status = 'complete' THEN 1 ELSE 0 END) as completed_reports,
    SUM(CASE WHEN reporting_status = 'pending' THEN 1 ELSE 0 END) as pending_reports,
    MAX(created_at) as last_band_date
  FROM band_certificates
  GROUP BY user_id;

-- View: Recent Bands (last 30 days)
CREATE OR REPLACE VIEW recent_bands AS
  SELECT *
  FROM band_certificates
  WHERE created_at > now() - interval '30 days'
  ORDER BY created_at DESC;

-- ============================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================

-- Insert test contact info (replace user_id with real user)
/*
INSERT INTO user_contact_info (
  user_id, 
  first_name, 
  last_name, 
  email, 
  phone, 
  street_address, 
  city, 
  state_province, 
  zip_postal_code
) VALUES (
  'test-user-id-here',
  'John',
  'Doe',
  'john@example.com',
  '(555) 123-4567',
  '123 Main Street',
  'Springfield',
  'Missouri',
  '65201'
);
*/

-- Insert test band (replace user_id with real user)
/*
INSERT INTO band_certificates (
  user_id,
  band_number,
  harvest_date,
  harvest_location,
  species,
  age_at_banding,
  sex,
  banding_date,
  banding_location,
  banding_state,
  research_project,
  reporting_status
) VALUES (
  'test-user-id-here',
  '1234567',
  '2025-03-15',
  'Lake Maurepas, Louisiana',
  'Mallard',
  'Adult',
  'Female',
  '2023-03-15',
  'Lake Maurepas',
  'LA',
  'Waterfowl Migration Study',
  'complete'
);
*/

-- ============================================================
-- COMMON QUERIES (Reference)
-- ============================================================

-- Get user's contact info
-- SELECT * FROM user_contact_info WHERE user_id = auth.uid();

-- Get all user's bands
-- SELECT * FROM band_certificates 
-- WHERE user_id = auth.uid() 
-- ORDER BY harvest_date DESC;

-- Get completed reports
-- SELECT * FROM band_certificates 
-- WHERE user_id = auth.uid() AND reporting_status = 'complete'
-- ORDER BY harvest_date DESC;

-- Get pending reports
-- SELECT * FROM band_certificates 
-- WHERE user_id = auth.uid() AND reporting_status = 'pending'
-- ORDER BY created_at DESC;

-- Count bands by species
-- SELECT species, COUNT(*) as count
-- FROM band_certificates 
-- WHERE user_id = auth.uid()
-- GROUP BY species
-- ORDER BY count DESC;

-- ============================================================
-- SCHEMA DOCUMENTATION
-- ============================================================

/*

TABLE: user_contact_info
PURPOSE: Store user's contact information (one record per user)
KEY FIELDS:
  - id: Unique identifier (UUID)
  - user_id: Reference to auth.users (one-to-one)
  - Contact fields: Used to pre-fill reportband.gov form
  - Timestamps: created_at, updated_at

TABLE: band_certificates
PURPOSE: Store band reports and certificate data (multiple per user)
KEY FIELDS:
  - id: Unique identifier (UUID)
  - user_id: Reference to auth.users (many-to-one)
  - band_number: The 8-9 digit band number from the bird
  - Harvest fields: When/where the bird was shot
  - Certificate fields: Data extracted from USGS certificate
  - Status: Tracks reporting status (pending → submitted → complete)
  - Timestamps: created_at, updated_at, submission_date, certificate_received_date

SECURITY:
  - RLS enabled on both tables
  - Users can only access their own data
  - Auth-based isolation

INDEXES:
  - user_id: Fast lookups by user
  - band_number: Find specific bands
  - status: Filter by reporting status
  - created_at: Sort by date

*/

-- ============================================================
-- MIGRATION NOTE
-- ============================================================
-- If adding new fields later:
-- 1. Modify the CREATE TABLE statement above
-- 2. Run: ALTER TABLE table_name ADD COLUMN new_field TYPE;
-- 3. Add indexes if needed for filtering/sorting
-- 4. Update RLS policies if needed
-- 5. Test with sample data
