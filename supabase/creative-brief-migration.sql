-- ============================================
-- CREATIVE BRIEF MIGRATION
-- Adds brief layer to concepts (ICE/approval/hypothesis), batch-level test plan,
-- denormalized lead_type/asset_type on creatives, extended auto-name trigger.
-- Run AFTER propaganda-os-migration.sql + icps-migration.sql.
-- Re-runnable: uses IF NOT EXISTS / OR REPLACE / DROP IF EXISTS throughout.
-- ============================================

-- ============================================
-- SECTION 1: CONCEPTS — becomes the brief-bearing entity
-- ============================================
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS big_idea           TEXT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS lead_type          TEXT;   -- Story | Problem-Solution | Big Secret | Promise | Proclamation | Offer
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS awareness_level    TEXT;   -- Unaware | Problem Aware | Solution Aware | Product Aware | Most Aware
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS asset_type         TEXT DEFAULT 'IMG';  -- IMG | VID | CAR
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS offer_id           UUID REFERENCES offer_contexts(id);
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS icp_id             UUID REFERENCES icps(id);
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS swipe_id           UUID REFERENCES image_ad_swipes(id);
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS brief_json         JSONB DEFAULT '{}'::jsonb;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS hypothesis         TEXT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS expected_outcome   TEXT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS concept_category   TEXT;   -- Control | DataDriven | Innovation
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS impact             INT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS confidence         INT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS ease               INT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS approved_by        TEXT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS approved_at        TIMESTAMPTZ;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS rejected_at        TIMESTAMPTZ;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS rejection_reason   TEXT;
ALTER TABLE concepts ADD COLUMN IF NOT EXISTS submitted_by       TEXT;

-- ICE checks (drop & recreate so this migration is re-runnable)
ALTER TABLE concepts DROP CONSTRAINT IF EXISTS concepts_impact_chk;
ALTER TABLE concepts DROP CONSTRAINT IF EXISTS concepts_confidence_chk;
ALTER TABLE concepts DROP CONSTRAINT IF EXISTS concepts_ease_chk;
ALTER TABLE concepts ADD CONSTRAINT concepts_impact_chk     CHECK (impact     IS NULL OR impact     BETWEEN 1 AND 10);
ALTER TABLE concepts ADD CONSTRAINT concepts_confidence_chk CHECK (confidence IS NULL OR confidence BETWEEN 1 AND 10);
ALTER TABLE concepts ADD CONSTRAINT concepts_ease_chk       CHECK (ease       IS NULL OR ease       BETWEEN 1 AND 10);

-- Computed ICE score — drop first to allow re-run after expression changes
ALTER TABLE concepts DROP COLUMN IF EXISTS ice_score;
ALTER TABLE concepts ADD COLUMN ice_score NUMERIC(4,2)
  GENERATED ALWAYS AS (
    ROUND(((COALESCE(impact,0) + COALESCE(confidence,0) + COALESCE(ease,0))::numeric) / 3.0, 2)
  ) STORED;

COMMENT ON COLUMN concepts.status IS
  'draft | scored | approved | rejected | in_production | launched | archived';

CREATE INDEX IF NOT EXISTS idx_concepts_status      ON concepts(status);
CREATE INDEX IF NOT EXISTS idx_concepts_lead_type   ON concepts(lead_type);
CREATE INDEX IF NOT EXISTS idx_concepts_asset_type  ON concepts(asset_type);
CREATE INDEX IF NOT EXISTS idx_concepts_ice_score   ON concepts(ice_score);

-- ============================================
-- SECTION 2: BATCHES — test-plan fields
-- ============================================
ALTER TABLE batches ADD COLUMN IF NOT EXISTS hypothesis        TEXT;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS expected_outcomes TEXT;
ALTER TABLE batches ADD COLUMN IF NOT EXISTS learnings         TEXT;

-- ============================================
-- SECTION 3: CREATIVES — denormalized fields for fast filtering
-- ============================================
ALTER TABLE creatives ADD COLUMN IF NOT EXISTS lead_type  TEXT;
ALTER TABLE creatives ADD COLUMN IF NOT EXISTS asset_type TEXT DEFAULT 'IMG';

CREATE INDEX IF NOT EXISTS idx_creatives_lead_type  ON creatives(lead_type);
CREATE INDEX IF NOT EXISTS idx_creatives_asset_type ON creatives(asset_type);
CREATE INDEX IF NOT EXISTS idx_creatives_performance ON creatives(performance);

-- ============================================
-- SECTION 4: EXTENDED AUTO-NAME TRIGGER
-- New pattern: {batch}-{angle}-{format}-{awareness}-{lead_type}-{asset_type}-B{n}-H{n}
-- Example:     MLMD-W5-Simplicity-UGC-PA-Story-IMG-B1-H1
--
-- Back-compat: if lead_type/asset_type aren't set on the row OR on the parent
-- concept, those segments are omitted — legacy creatives keep their short names.
-- ============================================
CREATE OR REPLACE FUNCTION generate_creative_name()
RETURNS TRIGGER AS $$
DECLARE
  v_batch_name      TEXT;
  v_angle           TEXT;
  v_format          TEXT;
  v_awareness_code  TEXT;
  v_lead_type       TEXT;
  v_lead_code       TEXT;
  v_asset_type      TEXT;
  v_concept_aware   TEXT;
BEGIN
  -- Pull batch + angle + format from concept; fall back lead_type/asset_type/awareness from concept too.
  SELECT b.name, c.angle, c.format, c.lead_type, c.asset_type, c.awareness_level
  INTO   v_batch_name, v_angle, v_format, v_lead_type, v_asset_type, v_concept_aware
  FROM concepts c
  JOIN batches b ON b.id = c.batch_id
  WHERE c.id = NEW.concept_id;

  -- Row-level overrides (denormalized columns) take precedence over concept defaults
  v_lead_type  := COALESCE(NEW.lead_type,  v_lead_type);
  v_asset_type := COALESCE(NEW.asset_type, v_asset_type);

  -- Awareness: prefer the row-level value, fall back to concept.awareness_level
  v_awareness_code := CASE COALESCE(NEW.awareness_level, v_concept_aware)
    WHEN 'Unaware'        THEN 'UA'
    WHEN 'Problem Aware'  THEN 'PA'
    WHEN 'Solution Aware' THEN 'SA'
    WHEN 'Product Aware'  THEN 'PrA'
    WHEN 'Most Aware'     THEN 'MA'
    ELSE NULL
  END;

  -- Lead type → short token for filename
  v_lead_code := CASE v_lead_type
    WHEN 'Story'             THEN 'Story'
    WHEN 'Problem-Solution'  THEN 'ProbSol'
    WHEN 'Big Secret'        THEN 'BigSec'
    WHEN 'Promise'           THEN 'Promise'
    WHEN 'Proclamation'      THEN 'Proclam'
    WHEN 'Offer'             THEN 'Offer'
    ELSE NULL
  END;

  -- Build the name. Required: batch + angle + format. Optional segments are appended only when present.
  NEW.name := v_batch_name || '-' || v_angle || '-' || v_format;

  IF v_awareness_code IS NOT NULL THEN
    NEW.name := NEW.name || '-' || v_awareness_code;
  END IF;
  IF v_lead_code IS NOT NULL THEN
    NEW.name := NEW.name || '-' || v_lead_code;
  END IF;
  IF v_asset_type IS NOT NULL THEN
    NEW.name := NEW.name || '-' || v_asset_type;
  END IF;

  NEW.name := NEW.name || '-B' || NEW.body_number || '-H' || NEW.hook_number;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger already exists from propaganda-os-migration; OR REPLACE on the function is enough.

-- ============================================
-- SECTION 5: HELPER VIEW — concepts with computed batch + client
-- Speeds up the brief generator + creative board joins.
-- ============================================
CREATE OR REPLACE VIEW concepts_full AS
SELECT
  c.*,
  b.name        AS batch_name,
  b.week_number AS batch_week_number,
  b.year        AS batch_year,
  cl.name       AS client_name,
  cl.code       AS client_code
FROM concepts c
LEFT JOIN batches b ON b.id = c.batch_id
LEFT JOIN clients cl ON cl.id = c.client_id;

-- ============================================
-- DONE. Verify with:
--   SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_name='concepts' ORDER BY ordinal_position;
--
--   INSERT INTO concepts (batch_id, client_id, angle, format, lead_type, awareness_level, asset_type)
--   VALUES ('<batch_uuid>', '<client_uuid>', 'TestAngle', 'UGC', 'Story', 'Problem Aware', 'IMG');
--
--   INSERT INTO creatives (concept_id, client_id, hook_number) VALUES ('<concept_uuid>', '<client_uuid>', 1);
--   -- Expect creatives.name like '{CODE}-W{N}-TestAngle-UGC-PA-Story-IMG-B1-H1'
-- ============================================
