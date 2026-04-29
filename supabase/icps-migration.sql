-- ============================================
-- ICPS TABLE — Customer avatars per client
-- Each ICP holds the deep psychographic profile + Schwartz awareness analysis
-- Run AFTER propaganda-os-migration.sql
-- ============================================

CREATE TABLE IF NOT EXISTS icps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,

  -- Identity
  name TEXT NOT NULL,                    -- short label, e.g. "Women 40-60 stuck on keto"
  description TEXT,                      -- 1-sentence ICP description
  status TEXT DEFAULT 'active',          -- active/paused/archived

  -- ============================================
  -- 9 PSYCHOGRAPHIC BLOCKS (each is a JSONB object with 5 named fields)
  -- ============================================
  goals_dreams JSONB,                    -- {public_goals, secret_dreams, identity_desires, legacy_fears, current_process}
  fears_insecurities JSONB,              -- {three_am_thoughts, imposter_syndrome, failure_scenarios, competitive_paranoia, time_anxiety}
  embarrassing_situations JSONB,         -- {professional_shame, personal_inadequacy, social_exposure, past_failures, status_threats}
  product_transformation JSONB,          -- {immediate_relief, status_elevation, confidence_boost, time_liberation, competitive_advantage}
  obvious_choice JSONB,                  -- {psychological_fit, trust_triggers, authority_positioning, social_proof_alignment, risk_reversal}
  failed_alternatives JSONB,             -- {previous_solutions, false_promises, diy_disasters, competitor_disappointments, free_cheap_failures}
  hesitation_reasons JSONB,              -- {skepticism_sources, investment_fears, change_resistance, perfectionism_paralysis, authority_doubts}
  enemy_story JSONB,                     -- {external_villains, system_failures, bad_advice_sources, internal_saboteurs, competitive_threats}
  internal_dialogue JSONB,               -- {self_talk_patterns, justification_stories, hope_vs_cynicism, decision_paralysis, success_fantasies}

  -- ============================================
  -- HARD DATA & PROOF (Step 3)
  -- ============================================
  market_pain_data TEXT,                 -- bullet list: "• stat — source"
  solution_validation_data TEXT,         -- bullet list: "• stat — source"

  -- ============================================
  -- COMPETITIVE INTELLIGENCE (Step 5)
  -- ============================================
  direct_competitors TEXT,               -- list of top 5 with offers/pricing/positioning
  alternative_solutions TEXT,            -- DIY, free, do-nothing alternatives
  customer_complaints TEXT,              -- top complaints about existing options
  market_trends TEXT,                    -- shifts, new angles, emerging tech

  -- ============================================
  -- PSYCHOLOGICAL PROFILE (Step 6)
  -- ============================================
  decision_making_style TEXT,            -- logic / emotion / social proof, fast / slow, individual / committee
  core_identity TEXT,                    -- identity to achieve + protect + how purchase fits self-image
  emotional_lever TEXT,                  -- biggest emotional driver (fear/aspiration/status)
  job_to_be_done TEXT,                   -- functional + emotional + social jobs

  -- ============================================
  -- LANGUAGE LIBRARY (Step 7)
  -- ============================================
  their_phrases TEXT,                    -- how they describe the problem
  power_words TEXT,                      -- words that feel powerful/credible
  pushy_words_avoid TEXT,                -- language that turns them off
  emotional_language TEXT,               -- words they overuse when frustrated/excited

  -- ============================================
  -- SCHWARTZ AWARENESS LEVEL ANALYSIS
  -- ============================================
  awareness_analysis JSONB,              -- {most_aware: {messaging, proof, objections}, product_aware: {...}, solution_aware: {...}, problem_aware: {...}, unaware: {...}}
  current_sophistication_stage INT,      -- 1-5 (Schwartz's sophistication stages)
  current_sophistication_notes TEXT,     -- what works now, what's commoditized

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_icps_client ON icps(client_id);
CREATE INDEX IF NOT EXISTS idx_icps_status ON icps(status);

DROP TRIGGER IF EXISTS set_icps_updated_at ON icps;
CREATE TRIGGER set_icps_updated_at
  BEFORE UPDATE ON icps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- LINK CREATIVES TO ICPS (so we can track which avatar is converting)
-- ============================================
ALTER TABLE creatives ADD COLUMN IF NOT EXISTS icp_id UUID REFERENCES icps(id);
CREATE INDEX IF NOT EXISTS idx_creatives_icp ON creatives(icp_id);

-- ============================================
-- RLS
-- ============================================
ALTER TABLE icps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on icps" ON icps;
CREATE POLICY "Allow all on icps" ON icps FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- DONE
-- ============================================
