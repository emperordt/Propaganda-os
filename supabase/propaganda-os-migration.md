# Propaganda OS Migration

Copy everything in the SQL block below and paste into Supabase SQL Editor:
**https://wqclspynbdghfsosqygg.supabase.co/project/_/sql**

```sql
-- ============================================
-- PROPAGANDA OS MIGRATION
-- Adds multi-tenant client support + auto-named creative pipeline
-- Run in Supabase SQL Editor at https://wqclspynbdghfsosqygg.supabase.co
-- Re-runnable: uses IF NOT EXISTS / DROP IF EXISTS throughout
-- ============================================

-- ============================================
-- SECTION 1: CLIENTS (multi-tenant root)
-- ============================================
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,  -- 3-5 letter code (MLMD, PROP, CALX)
  status TEXT DEFAULT 'onboarding',  -- prospect/onboarding/active/paused/offboarded
  website_url TEXT,
  slack_channel_id TEXT,
  google_drive_folder TEXT,
  primary_contact_email TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clients_code ON clients(code);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);

DROP TRIGGER IF EXISTS set_clients_updated_at ON clients;
CREATE TRIGGER set_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SECTION 2: BATCHES (weekly production batches per client)
-- Auto-named: {client_code}-W{week_number} -> e.g. MLMD-W6
-- ============================================
CREATE TABLE IF NOT EXISTS batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  week_number INT NOT NULL,
  year INT NOT NULL,
  name TEXT,
  status TEXT DEFAULT 'planning',
  due_date DATE,
  strategy_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(client_id, year, week_number)
);

CREATE INDEX IF NOT EXISTS idx_batches_client ON batches(client_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);

CREATE OR REPLACE FUNCTION generate_batch_name()
RETURNS TRIGGER AS $$
DECLARE
  client_code TEXT;
BEGIN
  SELECT code INTO client_code FROM clients WHERE id = NEW.client_id;
  NEW.name := client_code || '-W' || NEW.week_number::text;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_batch_name ON batches;
CREATE TRIGGER set_batch_name
  BEFORE INSERT ON batches
  FOR EACH ROW
  EXECUTE FUNCTION generate_batch_name();

-- ============================================
-- SECTION 3: CONCEPTS (angle/format groupings within batches)
-- ============================================
CREATE TABLE IF NOT EXISTS concepts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID REFERENCES batches(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id),
  angle TEXT NOT NULL,
  format TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  copy_doc_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_concepts_batch ON concepts(batch_id);
CREATE INDEX IF NOT EXISTS idx_concepts_client ON concepts(client_id);

-- ============================================
-- SECTION 4: CREATIVES (individual ads with auto-naming)
-- Auto-named: {batch_name}-{angle}-{format}-{awareness_code}-B{body#}-H{hook#}
-- e.g. CALX-W15-PainAgitate-ImageAd-PA-B1-H1
-- ============================================
CREATE TABLE IF NOT EXISTS creatives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  concept_id UUID REFERENCES concepts(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id),
  generation_id UUID,
  body_number INT NOT NULL DEFAULT 1,
  hook_number INT NOT NULL,
  name TEXT,
  hook_text TEXT,
  body_text TEXT,
  cta_text TEXT,
  awareness_level TEXT,
  creative_type TEXT DEFAULT 'Image',
  format TEXT,
  image_url TEXT,
  preview_url TEXT,
  final_url TEXT,
  production_status TEXT DEFAULT 'draft',
  performance TEXT,
  internal_notes TEXT,
  archived BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_creatives_concept ON creatives(concept_id);
CREATE INDEX IF NOT EXISTS idx_creatives_client ON creatives(client_id);
CREATE INDEX IF NOT EXISTS idx_creatives_status ON creatives(production_status);
CREATE INDEX IF NOT EXISTS idx_creatives_archived ON creatives(archived);

CREATE OR REPLACE FUNCTION generate_creative_name()
RETURNS TRIGGER AS $$
DECLARE
  batch_name TEXT;
  concept_angle TEXT;
  concept_format TEXT;
  awareness_code TEXT;
BEGIN
  SELECT b.name, c.angle, c.format
  INTO batch_name, concept_angle, concept_format
  FROM concepts c
  JOIN batches b ON b.id = c.batch_id
  WHERE c.id = NEW.concept_id;

  awareness_code := CASE NEW.awareness_level
    WHEN 'Unaware' THEN 'UA'
    WHEN 'Problem Aware' THEN 'PA'
    WHEN 'Solution Aware' THEN 'SA'
    WHEN 'Product Aware' THEN 'PrA'
    WHEN 'Most Aware' THEN 'MA'
    ELSE 'XX'
  END;

  NEW.name := batch_name || '-' || concept_angle || '-' || concept_format
              || '-' || awareness_code
              || '-B' || NEW.body_number || '-H' || NEW.hook_number;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_creative_name ON creatives;
CREATE TRIGGER set_creative_name
  BEFORE INSERT ON creatives
  FOR EACH ROW
  EXECUTE FUNCTION generate_creative_name();

DROP TRIGGER IF EXISTS set_creatives_updated_at ON creatives;
CREATE TRIGGER set_creatives_updated_at
  BEFORE UPDATE ON creatives
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SECTION 5: ONBOARDING_STEPS
-- ============================================
CREATE TABLE IF NOT EXISTS onboarding_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  step_number INT NOT NULL,
  step_name TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  result_data JSONB
);

CREATE INDEX IF NOT EXISTS idx_onboarding_client ON onboarding_steps(client_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_status ON onboarding_steps(status);

-- ============================================
-- SECTION 6: ALTER EXISTING TABLES
-- ============================================
ALTER TABLE brand_profiles ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES clients(id);
ALTER TABLE image_ad_generations ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES clients(id);
ALTER TABLE vercel_projects ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES clients(id);

CREATE INDEX IF NOT EXISTS idx_brand_profiles_client ON brand_profiles(client_id);
CREATE INDEX IF NOT EXISTS idx_image_ad_gens_client ON image_ad_generations(client_id);
CREATE INDEX IF NOT EXISTS idx_vercel_projects_client ON vercel_projects(client_id);

-- ============================================
-- SECTION 7: ROW LEVEL SECURITY
-- ============================================
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE creatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_steps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on clients" ON clients;
CREATE POLICY "Allow all on clients" ON clients FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on batches" ON batches;
CREATE POLICY "Allow all on batches" ON batches FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on concepts" ON concepts;
CREATE POLICY "Allow all on concepts" ON concepts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on creatives" ON creatives;
CREATE POLICY "Allow all on creatives" ON creatives FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on onboarding_steps" ON onboarding_steps;
CREATE POLICY "Allow all on onboarding_steps" ON onboarding_steps FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- DONE
-- ============================================
```
